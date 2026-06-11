import SwiftUI

struct DeskControls: View {
    let isConnected: Bool
    let onBeginUp: () -> Void
    let onBeginDown: () -> Void
    let onEndHold: () -> Void
    let onStop: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                MovementButton(
                    title: "Up",
                    systemImage: "arrow.up",
                    isEnabled: isConnected,
                    onPress: onBeginUp,
                    onRelease: onEndHold
                )
                MovementButton(
                    title: "Down",
                    systemImage: "arrow.down",
                    isEnabled: isConnected,
                    onPress: onBeginDown,
                    onRelease: onEndHold
                )
            }

            Button(action: onStop) {
                Label("Stop", systemImage: "stop.fill")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PopoverStopButtonStyle())
            .disabled(!isConnected)
        }
    }
}

/// Hold-to-move using a plain label + gesture (no SwiftUI Button gesture conflicts).
private struct MovementButton: View {
    let title: String
    let systemImage: String
    let isEnabled: Bool
    let onPress: () -> Void
    let onRelease: () -> Void

    @State private var isHolding = false

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.medium))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isHolding ? Color.primary.opacity(0.1) : Color.primary.opacity(0.05))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
            }
            .opacity(isEnabled ? 1 : 0.45)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard isEnabled, !isHolding else { return }
                        isHolding = true
                        onPress()
                    }
                    .onEnded { _ in
                        guard isEnabled else { return }
                        isHolding = false
                        onRelease()
                    }
            )
            .accessibilityLabel(title)
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Press and hold to move")
    }
}

private struct PopoverStopButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(BrandTheme.stop)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(BrandTheme.stopSoft.opacity(configuration.isPressed ? 1 : 0.8))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(BrandTheme.stop.opacity(0.2), lineWidth: 1)
            }
    }
}
