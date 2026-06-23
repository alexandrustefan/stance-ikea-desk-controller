import SwiftUI

struct AutoStandSettings: View {
    @Bindable var appState: AppState

    private var configBinding: Binding<AutoStandConfig> {
        Binding(
            get: { appState.profileManager.activeProfile?.autoStand ?? .default },
            set: { newValue in
                guard var profile = appState.profileManager.activeProfile else { return }
                profile.autoStand = newValue
                appState.profileManager.updateProfile(profile)
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if appState.profileManager.activeProfile != nil {
                statusAndModeCard
                parametersCard
                activeHoursCard
                smartRulesCard
                sessionSummaryCard
            } else {
                Text("Select or create a profile to configure Auto-Stand.")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
                    .glassCard()
            }
        }
    }

    private var statusAndModeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Toggle("Enable Auto-Stand", isOn: configBinding.enabled)
                .toggleStyle(.switch)
                .font(.headline.weight(.semibold))

            Text("Automatically move your desk between sit and stand on a schedule.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Schedule Mode")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Picker("", selection: configBinding.scheduleMode) {
                    ForEach(ScheduleMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue.capitalized).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
        }
        .glassCard(contentPadding: 16, cornerRadius: 16)
    }

    @ViewBuilder
    private var parametersCard: some View {
        let mode = configBinding.wrappedValue.scheduleMode

        VStack(alignment: .leading, spacing: 12) {
            Text("Schedule Parameters")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 14) {
                if mode == .hourly {
                    stepperRow(
                        title: "Stand Minutes Per Hour",
                        subtitle: "Stand at the start of each active hour.",
                        valueText: "\(Int(configBinding.standMinutesPerHour.wrappedValue)) min",
                        binding: configBinding.standMinutesPerHour,
                        range: 5 ... 55,
                        step: 5
                    )
                } else if mode == .interval {
                    stepperRow(
                        title: "Sit Duration",
                        subtitle: "Time sitting before standing.",
                        valueText: "\(Int(configBinding.intervalStandMinutes.wrappedValue)) min",
                        binding: configBinding.intervalStandMinutes,
                        range: 15 ... 120,
                        step: 5
                    )
                    Divider()
                    stepperRow(
                        title: "Stand Duration",
                        subtitle: "Time standing before sitting.",
                        valueText: "\(Int(configBinding.intervalSitMinutes.wrappedValue)) min",
                        binding: configBinding.intervalSitMinutes,
                        range: 5 ... 60,
                        step: 5
                    )
                } else {
                    customScheduleEditor
                }
            }
            .glassCard(contentPadding: 16, cornerRadius: 16)
        }
    }

    private var customScheduleEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Time blocks use 24-hour clock on active weekdays.")
                .font(.caption2)
                .foregroundStyle(.secondary)

            ForEach(configBinding.wrappedValue.customSchedule) { entry in
                HStack {
                    Text(blockLabel(entry))
                        .font(.caption)
                    Spacer()
                    Button("Remove", role: .destructive) {
                        var config = configBinding.wrappedValue
                        config.customSchedule.removeAll { $0.id == entry.id }
                        configBinding.wrappedValue = config
                    }
                    .font(.caption)
                }
            }

            Button("Add Stand Block (15 min)") {
                var config = configBinding.wrappedValue
                let now = Calendar.current.dateComponents([.hour, .minute], from: .now)
                let start = DateComponents(hour: now.hour, minute: now.minute)
                let endMinute = (now.minute ?? 0) + 15
                let end = DateComponents(hour: (now.hour ?? 0) + endMinute / 60, minute: endMinute % 60)
                config.customSchedule.append(
                    ScheduleEntry(id: UUID(), startTime: start, endTime: end, action: .stand)
                )
                configBinding.wrappedValue = config
            }
            .font(.caption.weight(.semibold))
        }
    }

    private var activeHoursCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Schedule")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                HStack {
                    Text("Active hours")
                    Spacer()
                    timePicker(configBinding.activeHourStart, label: "Start")
                    Text("–")
                    timePicker(configBinding.activeHourEnd, label: "End")
                }
                .font(.caption)

                weekdayPicker

                HStack {
                    Text("Quiet hours")
                    Spacer()
                    timePicker(configBinding.quietHoursStart, label: "Start")
                    Text("–")
                    timePicker(configBinding.quietHoursEnd, label: "End")
                }
                .font(.caption)
            }
            .glassCard(contentPadding: 16, cornerRadius: 16)
        }
    }

    private var weekdayPicker: some View {
        let symbols = Calendar.current.shortWeekdaySymbols
        return HStack(spacing: 6) {
            ForEach(1 ... 7, id: \.self) { weekday in
                let selected = configBinding.activeWeekdays.wrappedValue.contains(weekday)
                Button(symbols[weekday - 1]) {
                    var days = configBinding.activeWeekdays.wrappedValue
                    if selected {
                        days.removeAll { $0 == weekday }
                    } else {
                        days.append(weekday)
                    }
                    configBinding.activeWeekdays.wrappedValue = days.sorted()
                }
                .buttonStyle(.plain)
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(selected ? BrandTheme.accentMuted : Color.primary.opacity(0.05), in: Capsule())
            }
        }
    }

    private var smartRulesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Smart Rules & Notifications")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                stepperRow(
                    title: "Inactivity Pause",
                    subtitle: "Pause when idle.",
                    valueText: "\(Int(configBinding.inactivityThreshold.wrappedValue)) min",
                    binding: configBinding.inactivityThreshold,
                    range: 1 ... 60,
                    step: 1
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Divider().padding(.leading, 16)

                stepperRow(
                    title: "Notify Before Stand",
                    subtitle: "Lead time for alerts.",
                    valueText: "\(Int(configBinding.notifyBeforeMinutes.wrappedValue)) min",
                    binding: configBinding.notifyBeforeMinutes,
                    range: 0 ... 15,
                    step: 1
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Divider().padding(.leading, 16)

                Toggle(isOn: configBinding.notificationEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Push Notifications")
                            .font(.body.weight(.semibold))
                        Text("Alerts with Skip, Snooze, and Stand Now actions.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.switch)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Divider().padding(.leading, 16)

                Toggle(isOn: configBinding.breakRemindersEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Break Reminders")
                            .font(.body.weight(.semibold))
                        Text("Screen break reminders independent of standing schedule.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.switch)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                if configBinding.breakRemindersEnabled.wrappedValue {
                    stepperRow(
                        title: "Break Interval",
                        subtitle: "Time between break reminders.",
                        valueText: "\(Int(configBinding.breakReminderIntervalMinutes.wrappedValue)) min",
                        binding: configBinding.breakReminderIntervalMinutes,
                        range: 15 ... 180,
                        step: 15
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }

                Divider().padding(.leading, 16)

                Toggle(isOn: focusSuppressionBinding) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Suppress During Do Not Disturb")
                            .font(.body.weight(.semibold))
                        Text("Pause auto-stand while Focus / DND is active.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.switch)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .glassCard(contentPadding: 0, cornerRadius: 16)
        }
    }

    private var sessionSummaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Session Summary")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                Text("Today: \(appState.standingSessionSummary) across \(appState.autoStandService.todaySessionCount) sessions")
                Text("This week avg: \(appState.autoStandService.formattedDuration(appState.autoStandService.weeklyAverageStandingDuration))/day")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .glassCard(contentPadding: 16, cornerRadius: 16)
        }
    }

    private var focusSuppressionBinding: Binding<Bool> {
        Binding(
            get: { configBinding.wrappedValue.suppressDuringFocusModes.contains("DoNotDisturb") },
            set: { enabled in
                var modes = configBinding.wrappedValue.suppressDuringFocusModes
                if enabled {
                    if !modes.contains("DoNotDisturb") { modes.append("DoNotDisturb") }
                } else {
                    modes.removeAll { $0 == "DoNotDisturb" }
                }
                var config = configBinding.wrappedValue
                config.suppressDuringFocusModes = modes
                configBinding.wrappedValue = config
            }
        )
    }

    private func stepperRow(
        title: String,
        subtitle: String,
        valueText: String,
        binding: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.semibold))
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 8) {
                Text(valueText)
                    .font(.body.weight(.bold))
                    .foregroundStyle(BrandTheme.accent)
                Stepper("", value: binding, in: range, step: step)
                    .labelsHidden()
            }
        }
    }

    private func timePicker(_ binding: Binding<DateComponents>, label: String) -> some View {
        let date = dateFromComponents(binding.wrappedValue) ?? .now
        return DatePicker(
            label,
            selection: Binding(
                get: { date },
                set: { newDate in
                    binding.wrappedValue = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                }
            ),
            displayedComponents: .hourAndMinute
        )
        .labelsHidden()
        .frame(width: 90)
    }

    private func dateFromComponents(_ components: DateComponents) -> Date? {
        Calendar.current.date(from: components)
    }

    private func blockLabel(_ entry: ScheduleEntry) -> String {
        let start = formatTime(entry.startTime)
        let end = formatTime(entry.endTime)
        let action: String = switch entry.action {
        case .stand: "Stand"
        case .sit: "Sit"
        case .moveToHeight(let h): "\(Int(h)) cm"
        case .preset: "Preset"
        }
        return "\(start)–\(end): \(action)"
    }

    private func formatTime(_ components: DateComponents) -> String {
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        return String(format: "%02d:%02d", hour, minute)
    }
}

private extension Binding where Value == AutoStandConfig {
    var enabled: Binding<Bool> {
        subBinding(read: \.enabled, apply: { $0.enabled = $1 })
    }
    var scheduleMode: Binding<ScheduleMode> {
        subBinding(read: \.scheduleMode, apply: { $0.scheduleMode = $1 })
    }
    var standMinutesPerHour: Binding<Double> {
        subBinding(read: \.standMinutesPerHour, apply: { $0.standMinutesPerHour = $1 })
    }
    var intervalStandMinutes: Binding<Double> {
        subBinding(read: \.intervalStandMinutes, apply: { $0.intervalStandMinutes = $1 })
    }
    var intervalSitMinutes: Binding<Double> {
        subBinding(read: \.intervalSitMinutes, apply: { $0.intervalSitMinutes = $1 })
    }
    var inactivityThreshold: Binding<Double> {
        subBinding(read: \.inactivityThreshold, apply: { $0.inactivityThreshold = $1 })
    }
    var notificationEnabled: Binding<Bool> {
        subBinding(read: \.notificationEnabled, apply: { $0.notificationEnabled = $1 })
    }
    var notifyBeforeMinutes: Binding<Double> {
        subBinding(read: \.notifyBeforeMinutes, apply: { $0.notifyBeforeMinutes = $1 })
    }
    var breakRemindersEnabled: Binding<Bool> {
        subBinding(read: \.breakRemindersEnabled, apply: { $0.breakRemindersEnabled = $1 })
    }
    var breakReminderIntervalMinutes: Binding<Double> {
        subBinding(read: \.breakReminderIntervalMinutes, apply: { $0.breakReminderIntervalMinutes = $1 })
    }
    var activeHourStart: Binding<DateComponents> {
        subBinding(read: \.activeHourStart, apply: { $0.activeHourStart = $1 })
    }
    var activeHourEnd: Binding<DateComponents> {
        subBinding(read: \.activeHourEnd, apply: { $0.activeHourEnd = $1 })
    }
    var quietHoursStart: Binding<DateComponents> {
        subBinding(read: \.quietHoursStart, apply: { $0.quietHoursStart = $1 })
    }
    var quietHoursEnd: Binding<DateComponents> {
        subBinding(read: \.quietHoursEnd, apply: { $0.quietHoursEnd = $1 })
    }
    var activeWeekdays: Binding<[Int]> {
        subBinding(read: \.activeWeekdays, apply: { $0.activeWeekdays = $1 })
    }
    var customSchedule: Binding<[ScheduleEntry]> {
        subBinding(read: \.customSchedule, apply: { $0.customSchedule = $1 })
    }
    var suppressDuringFocusModes: Binding<[String]> {
        subBinding(read: \.suppressDuringFocusModes, apply: { $0.suppressDuringFocusModes = $1 })
    }

    private func subBinding<T>(
        read: @escaping (AutoStandConfig) -> T,
        apply: @escaping (inout AutoStandConfig, T) -> Void
    ) -> Binding<T> {
        Binding<T>(
            get: { read(wrappedValue) },
            set: { newValue in
                var config = wrappedValue
                apply(&config, newValue)
                wrappedValue = config
            }
        )
    }
}
