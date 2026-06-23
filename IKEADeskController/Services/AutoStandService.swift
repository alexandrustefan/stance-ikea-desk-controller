import AppKit
import Foundation

struct StandingSession: Sendable, Equatable {
    var started: Date
    var ended: Date?
}

@MainActor
final class AutoStandService {
    private enum PosturePhase: Equatable {
        case sitting
        case standing
    }

    private var timer: Timer?
    private weak var appState: AppState?
    private(set) var standingSessions: [StandingSession] = []

    private var hourlyPhase: PosturePhase?
    private var intervalCycleStartedAt: Date?
    private var intervalPhase: PosturePhase?
    private var customPhase: PosturePhase?
    private var customEntryID: UUID?
    private var snoozedUntil: Date?
    private var lastBreakReminderAt: Date?
    private var lastPreStandNotificationAt: Date?

    func start(appState: AppState) {
        self.appState = appState
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func snooze(minutes: Double = 5) {
        snoozedUntil = Date().addingTimeInterval(minutes * 60)
    }

    func skipCurrentTransition() {
        snoozedUntil = Date().addingTimeInterval(30 * 60)
    }

    var todayStandingDuration: TimeInterval {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        return standingSessions.reduce(0) { total, session in
            guard session.started >= startOfDay || (session.ended ?? .now) >= startOfDay else { return total }
            let end = session.ended ?? .now
            let start = max(session.started, startOfDay)
            return total + end.timeIntervalSince(start)
        }
    }

    var todaySessionCount: Int {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        return standingSessions.filter { $0.started >= startOfDay || ($0.ended ?? .now) >= startOfDay }.count
    }

    var weeklyAverageStandingDuration: TimeInterval {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: .now)) ?? .now
        var dailyTotals: [TimeInterval] = []
        for dayOffset in 0 ..< 7 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) else { continue }
            let dayStart = calendar.startOfDay(for: day)
            guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { continue }
            let total = standingSessions.reduce(0.0) { sum, session in
                let end = session.ended ?? .now
                guard end > dayStart, session.started < dayEnd else { return sum }
                let start = max(session.started, dayStart)
                let finish = min(end, dayEnd)
                return sum + finish.timeIntervalSince(start)
            }
            if total > 0 { dailyTotals.append(total) }
        }
        guard !dailyTotals.isEmpty else { return 0 }
        return dailyTotals.reduce(0, +) / Double(dailyTotals.count)
    }

    func formattedDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        if minutes < 60 { return "\(minutes)m" }
        return "\(minutes / 60)h \(minutes % 60)m"
    }

    private func tick() {
        guard let appState, let profile = appState.profileManager.activeProfile else { return }
        let config = profile.autoStand
        let now = Date()

        guard config.enabled else {
            resetScheduleState(clearCountdown: true, appState: appState)
            return
        }

        if let snoozedUntil, now < snoozedUntil {
            appState.autoStandCountdownText = "Auto-stand snoozed"
            return
        }
        snoozedUntil = nil

        guard AutoStandScheduler.shouldRunAutoStand(now, config: config) else {
            appState.autoStandCountdownText = "Outside active schedule"
            return
        }

        if FocusModeChecker.shouldSuppress(config: config) {
            appState.autoStandCountdownText = "Paused (Focus mode)"
            return
        }

        if isInactive(thresholdMinutes: config.inactivityThreshold) {
            appState.autoStandCountdownText = "Auto-stand paused (inactive)"
            return
        }

        if config.breakRemindersEnabled {
            handleBreakReminder(config: config, appState: appState, now: now)
        }

        switch config.scheduleMode {
        case .hourly:
            handleHourly(config: config, appState: appState, now: now)
        case .interval:
            handleInterval(config: config, appState: appState, now: now)
        case .custom:
            handleCustom(config: config, appState: appState, profile: profile, now: now)
        }
    }

    private func handleHourly(config: AutoStandConfig, appState: AppState, now: Date) {
        let calendar = Calendar.current
        let minuteOfHour = calendar.component(.minute, from: now)
        let standMinutes = max(1, Int(config.standMinutesPerHour.rounded()))
        let shouldStand = minuteOfHour < standMinutes
        let desiredPhase: PosturePhase = shouldStand ? .standing : .sitting

        maybeNotifyBeforeStand(
            config: config,
            appState: appState,
            minutesUntil: shouldStand ? max(0, standMinutes - minuteOfHour) : max(0, 60 - minuteOfHour),
            willStand: !shouldStand
        )

        if hourlyPhase != desiredPhase {
            transition(to: desiredPhase, appState: appState, config: config)
            hourlyPhase = desiredPhase
        }

        if shouldStand {
            appState.autoStandCountdownText = "Sitting in \(max(1, standMinutes - minuteOfHour)) min"
        } else {
            appState.autoStandCountdownText = "Standing in \(max(1, 60 - minuteOfHour)) min"
        }
    }

    private func handleInterval(config: AutoStandConfig, appState: AppState, now: Date) {
        if intervalCycleStartedAt == nil {
            intervalCycleStartedAt = now
            intervalPhase = .sitting
        }

        guard let cycleStart = intervalCycleStartedAt else { return }

        let sitSeconds = config.intervalStandMinutes * 60
        let standSeconds = config.intervalSitMinutes * 60
        let cycleSeconds = sitSeconds + standSeconds
        let elapsed = now.timeIntervalSince(cycleStart).truncatingRemainder(dividingBy: cycleSeconds)

        let shouldStand = elapsed >= sitSeconds
        let desiredPhase: PosturePhase = shouldStand ? .standing : .sitting

        if shouldStand {
            let standElapsed = elapsed - sitSeconds
            let minutesLeft = max(1, Int((standSeconds - standElapsed) / 60))
            maybeNotifyBeforeStand(
                config: config,
                appState: appState,
                minutesUntil: minutesLeft,
                willStand: false
            )
            appState.autoStandCountdownText = "Sitting in \(minutesLeft) min"
        } else {
            let minutesLeft = max(1, Int((sitSeconds - elapsed) / 60))
            maybeNotifyBeforeStand(
                config: config,
                appState: appState,
                minutesUntil: minutesLeft,
                willStand: true
            )
            appState.autoStandCountdownText = "Standing in \(minutesLeft) min"
        }

        if intervalPhase != desiredPhase {
            transition(to: desiredPhase, appState: appState, config: config)
            intervalPhase = desiredPhase
        }
    }

    private func handleCustom(
        config: AutoStandConfig,
        appState: AppState,
        profile: DeskProfile,
        now: Date
    ) {
        guard let entry = AutoStandScheduler.matchingScheduleEntry(now, config: config) else {
            customPhase = nil
            customEntryID = nil
            appState.autoStandCountdownText = "No active schedule block"
            return
        }

        if customEntryID != entry.id {
            customEntryID = entry.id
            executeScheduleAction(entry.action, appState: appState, profile: profile, config: config)
            customPhase = posturePhase(for: entry.action)
        }

        appState.autoStandCountdownText = "Custom block active"
    }

    private func executeScheduleAction(
        _ action: ScheduleAction,
        appState: AppState,
        profile: DeskProfile,
        config: AutoStandConfig
    ) {
        switch action {
        case .stand:
            transition(to: .standing, appState: appState, config: config)
        case .sit:
            transition(to: .sitting, appState: appState, config: config)
        case .moveToHeight(let height):
            Task { await appState.moveToHeight(height) }
            notifyIfEnabled(config: config, title: "Desk moving", body: "Moving to \(Int(height)) cm")
        case .preset(let id):
            if let preset = profile.customPositions.first(where: { $0.id == id }) {
                appState.moveToCustomPosition(preset)
                notifyIfEnabled(config: config, title: "Desk moving", body: "Moving to \(preset.name)")
            }
        }
    }

    private func posturePhase(for action: ScheduleAction) -> PosturePhase? {
        switch action {
        case .stand: .standing
        case .sit: .sitting
        case .moveToHeight, .preset: nil
        }
    }

    private func transition(to phase: PosturePhase, appState: AppState, config: AutoStandConfig) {
        switch phase {
        case .standing:
            appState.moveToStand()
            standingSessions.append(StandingSession(started: .now, ended: nil))
            notifyIfEnabled(config: config, title: "Time to stand", body: "Your desk is moving to standing height.")
        case .sitting:
            closeOpenStandingSession()
            appState.moveToSit()
            notifyIfEnabled(config: config, title: "Time to sit", body: "Your desk is moving to sitting height.")
        }
    }

    private func closeOpenStandingSession() {
        guard let index = standingSessions.lastIndex(where: { $0.ended == nil }) else { return }
        standingSessions[index].ended = .now
        if let appState, let profile = appState.profileManager.activeProfile, profile.autoStand.notificationEnabled {
            let duration = standingSessions[index].ended!.timeIntervalSince(standingSessions[index].started)
            appState.notificationService.notify(
                title: "Standing session complete",
                body: "You stood for \(formattedDuration(duration))."
            )
        }
    }

    private func handleBreakReminder(config: AutoStandConfig, appState: AppState, now: Date) {
        let interval = config.breakReminderIntervalMinutes * 60
        guard interval > 0 else { return }
        if let lastBreakReminderAt, now.timeIntervalSince(lastBreakReminderAt) < interval { return }
        lastBreakReminderAt = now
        appState.notificationService.notify(
            title: "Break reminder",
            body: "Step away from the screen for a few minutes."
        )
    }

    private func maybeNotifyBeforeStand(
        config: AutoStandConfig,
        appState: AppState,
        minutesUntil: Int,
        willStand: Bool
    ) {
        guard willStand, config.notificationEnabled else { return }
        let lead = Int(config.notifyBeforeMinutes.rounded())
        guard lead > 0, minutesUntil <= lead, minutesUntil > 0 else { return }
        if let lastPreStandNotificationAt,
           Date().timeIntervalSince(lastPreStandNotificationAt) < 60 * 5 { return }
        lastPreStandNotificationAt = .now
        appState.notificationService.notify(
            title: "Standing soon",
            body: "Standing in \(minutesUntil) minute\(minutesUntil == 1 ? "" : "s").",
            category: .autoStand
        )
    }

    private func notifyIfEnabled(config: AutoStandConfig, title: String, body: String) {
        guard config.notificationEnabled, let appState else { return }
        appState.notificationService.notify(title: title, body: body, category: .autoStand)
    }

    private func resetScheduleState(clearCountdown: Bool, appState: AppState) {
        hourlyPhase = nil
        intervalCycleStartedAt = nil
        intervalPhase = nil
        customPhase = nil
        customEntryID = nil
        if clearCountdown {
            appState.autoStandCountdownText = nil
        }
    }

    private func isInactive(thresholdMinutes: Double) -> Bool {
        let seconds = CGEventSource.secondsSinceLastEventType(
            .hidSystemState,
            eventType: CGEventType(rawValue: UInt32.max)!
        )
        return seconds > thresholdMinutes * 60
    }
}
