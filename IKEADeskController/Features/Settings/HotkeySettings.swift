import SwiftUI

struct HotkeySettings: View {
    @Bindable var appState: AppState
    @State private var recorder = HotkeyRecorder()
    @State private var conflictMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            permissionBanner

            if let conflictMessage {
                Text(conflictMessage)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            if appState.profileManager.activeProfile != nil {
                VStack(spacing: 0) {
                    hotkeyRow("Move to Sit", action: .moveSit)
                    rowDivider
                    hotkeyRow("Move to Stand", action: .moveStand)
                    rowDivider
                    hotkeyRow("Move Up", action: .moveUp, hint: "Hold to move continuously")
                    rowDivider
                    hotkeyRow("Move Down", action: .moveDown, hint: "Hold to move continuously")
                    rowDivider
                    hotkeyRow("Cycle Profiles", action: .cycleProfiles)
                    rowDivider
                    hotkeyRow("Emergency Stop", action: .emergencyStop)
                }
                .glassCard(contentPadding: 0, cornerRadius: 16)
            }

            Text("Click Record, then press a key combination. Press Esc to cancel. Up/Down hotkeys repeat while held.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var permissionBanner: some View {
        if appState.isInputMonitoringGranted {
            Label("Input Monitoring is enabled.", systemImage: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(BrandTheme.accent)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Label("Input Monitoring required", systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.orange)
                Text("Global hotkeys need Input Monitoring permission in System Settings → Privacy & Security.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 10) {
                    Button("Grant Permission") {
                        appState.requestInputMonitoringPermission()
                    }
                    .buttonStyle(AdaptiveProminentButtonStyle())
                    Button("Open System Settings") {
                        appState.openInputMonitoringSettings()
                    }
                    .buttonStyle(AdaptiveSecondaryButtonStyle())
                }
            }
            .glassCard(contentPadding: 16, cornerRadius: 16)
        }
    }

    private var rowDivider: some View {
        Divider().padding(.leading, 16)
    }

    private func hotkeyRow(_ title: String, action: HotKeyService.HotkeyAction, hint: String? = nil) -> some View {
        let combo = combo(for: action)
        let actionID = String(describing: action)

        return VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body.weight(.semibold))
                    if let hint {
                        Text(hint)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                Spacer()
                HotkeyRecorderButton(
                    title: title,
                    combo: combo,
                    isRecording: recorder.isRecording && recorder.recordingActionID == actionID,
                    onStartRecording: {
                        recorder.startRecording(actionID: actionID) { captured in
                            guard let hotkeys = appState.profileManager.activeProfile?.hotkeys else { return }
                            if HotkeyConflictChecker.hasConflict(for: captured, in: hotkeys, excluding: action) {
                                conflictMessage = "That shortcut is already used by another action."
                                return
                            }
                            conflictMessage = nil
                            appState.updateHotkey(action, combo: captured)
                        }
                    },
                    onClear: {
                        recorder.stopRecording()
                        appState.updateHotkey(action, combo: nil)
                    }
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func combo(for action: HotKeyService.HotkeyAction) -> KeyCombo? {
        guard let hotkeys = appState.profileManager.activeProfile?.hotkeys else { return nil }
        switch action {
        case .moveSit: return hotkeys.moveSit
        case .moveStand: return hotkeys.moveStand
        case .moveUp: return hotkeys.moveUp
        case .moveDown: return hotkeys.moveDown
        case .cycleProfiles: return hotkeys.cycleProfiles
        case .emergencyStop: return hotkeys.emergencyStop
        }
    }
}
