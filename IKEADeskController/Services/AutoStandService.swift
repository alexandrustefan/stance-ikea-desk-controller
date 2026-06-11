import AppKit
import Foundation

@MainActor
final class AutoStandService {
    private enum PosturePhase: Equatable {
        case sitting
        case standing
    }

    private var timer: Timer?
    private weak var appState: AppState?
    private(set) var standingSessions: [(started: Date, ended: Date)] = []

    private var hourlyPhase: PosturePhase?
    private var intervalCycleStartedAt: Date?
    private var intervalPhase: PosturePhase?

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

    var todayStandingDuration: TimeInterval {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        return standingSessions
            .filter { $0.ended >= startOfDay }
            .reduce(0) { $0 + $1.ended.timeIntervalSince($1.started) }
    }

    private func tick() {
        guard let appState, let profile = appState.profileManager.activeProfile else { return }
        let config = profile.autoStand
        guard config.enabled else {
            hourlyPhase = nil
            intervalCycleStartedAt = nil
            intervalPhase = nil
            appState.autoStandCountdownText = nil
            return
        }

        if isInactive(thresholdMinutes: config.inactivityThreshold) {
            appState.autoStandCountdownText = "Auto-stand paused (inactive)"
            return
        }

        switch config.scheduleMode {
        case .hourly:
            handleHourly(config: config, appState: appState)
        case .interval:
            handleInterval(config: config, appState: appState)
        case .custom:
            appState.autoStandCountdownText = "Custom schedule active"
        }
    }

    /// Stand for N minutes at the start of each hour, then sit for the remainder.
    private func handleHourly(config: AutoStandConfig, appState: AppState) {
        let calendar = Calendar.current
        let now = Date()
        let minuteOfHour = calendar.component(.minute, from: now)
        let standMinutes = max(1, Int(config.standMinutesPerHour.rounded()))
        let shouldStand = minuteOfHour < standMinutes
        let desiredPhase: PosturePhase = shouldStand ? .standing : .sitting

        if hourlyPhase != desiredPhase {
            transition(to: desiredPhase, appState: appState, standMinutes: Double(standMinutes))
            hourlyPhase = desiredPhase
        }

        if shouldStand {
            let minutesUntilSit = max(1, standMinutes - minuteOfHour)
            appState.autoStandCountdownText = "Sitting in \(minutesUntilSit) min"
        } else {
            let minutesUntilStand = max(1, 60 - minuteOfHour)
            appState.autoStandCountdownText = "Standing in \(minutesUntilStand) min"
        }
    }

    /// Sit for intervalStandMinutes, then stand for intervalSitMinutes, repeat.
    private func handleInterval(config: AutoStandConfig, appState: AppState) {
        let now = Date()
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

        if intervalPhase != desiredPhase {
            transition(to: desiredPhase, appState: appState, standMinutes: config.intervalSitMinutes)
            intervalPhase = desiredPhase
        }

        if shouldStand {
            let standElapsed = elapsed - sitSeconds
            let minutesLeft = max(1, Int((standSeconds - standElapsed) / 60))
            appState.autoStandCountdownText = "Sitting in \(minutesLeft) min"
        } else {
            let minutesLeft = max(1, Int((sitSeconds - elapsed) / 60))
            appState.autoStandCountdownText = "Standing in \(minutesLeft) min"
        }
    }

    private func transition(to phase: PosturePhase, appState: AppState, standMinutes: Double) {
        switch phase {
        case .standing:
            appState.moveToStand()
            standingSessions.append((started: .now, ended: .now.addingTimeInterval(standMinutes * 60)))
        case .sitting:
            appState.moveToSit()
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
