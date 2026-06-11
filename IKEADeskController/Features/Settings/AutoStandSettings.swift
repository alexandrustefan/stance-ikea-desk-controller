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
        Form {
            Toggle("Auto-Stand", isOn: configBinding.enabled)
            Picker("Schedule Mode", selection: configBinding.scheduleMode) {
                ForEach(ScheduleMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue.capitalized).tag(mode)
                }
            }
            if configBinding.wrappedValue.scheduleMode == .hourly {
                Stepper(
                    "Stand minutes per hour: \(Int(configBinding.standMinutesPerHour.wrappedValue))",
                    value: configBinding.standMinutesPerHour,
                    in: 5 ... 55,
                    step: 5
                )
            }
            if configBinding.wrappedValue.scheduleMode == .interval {
                Stepper(
                    "Stand every \(Int(configBinding.intervalStandMinutes.wrappedValue)) min",
                    value: configBinding.intervalStandMinutes,
                    in: 15 ... 120,
                    step: 5
                )
                Stepper(
                    "Sit after \(Int(configBinding.intervalSitMinutes.wrappedValue)) min",
                    value: configBinding.intervalSitMinutes,
                    in: 5 ... 60,
                    step: 5
                )
            }
            Stepper(
                "Pause if inactive for \(Int(configBinding.inactivityThreshold.wrappedValue)) min",
                value: configBinding.inactivityThreshold,
                in: 1 ... 60
            )
            Toggle("Notifications", isOn: configBinding.notificationEnabled)
        }
        .formStyle(.grouped)
        .padding()
    }
}
