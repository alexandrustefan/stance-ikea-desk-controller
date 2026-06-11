import AppKit
import SwiftUI

@MainActor
@Observable
final class HotkeyRecorder {
    private(set) var isRecording = false
    private(set) var recordingActionID: String?
    private var monitor: Any?

    func startRecording(actionID: String, onCapture: @escaping (KeyCombo) -> Void) {
        stopRecording()
        isRecording = true
        recordingActionID = actionID

        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self, isRecording else { return event }

            if event.keyCode == 53 { // Escape
                stopRecording()
                return nil
            }

            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            guard !flags.isEmpty else { return nil }

            let combo = KeyCombo(
                keyCode: UInt16(event.keyCode),
                modifiers: UInt(flags.rawValue)
            )
            onCapture(combo)
            stopRecording()
            return nil
        }
    }

    func stopRecording() {
        isRecording = false
        recordingActionID = nil
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}

struct HotkeyRecorderButton: View {
    let title: String
    let combo: KeyCombo?
    let isRecording: Bool
    let onStartRecording: () -> Void
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onStartRecording) {
                Group {
                    if isRecording {
                        Text("Press keys…")
                            .foregroundStyle(BrandTheme.accent)
                    } else if let combo {
                        Text(HotKeyService.displayString(for: combo))
                    } else {
                        Text("Record")
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.body.monospaced())
                .frame(minWidth: 120, alignment: .trailing)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isRecording ? BrandTheme.accentSoft : Color.primary.opacity(0.05))
                }
                .overlay {
                    if isRecording {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(BrandTheme.accent.opacity(0.5), lineWidth: 1)
                    }
                }
            }
            .buttonStyle(.plain)

            if combo != nil, !isRecording {
                Button("Clear", action: onClear)
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
