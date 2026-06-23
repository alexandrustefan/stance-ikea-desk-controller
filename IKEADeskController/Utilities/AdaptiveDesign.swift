import SwiftUI

// MARK: - Glass & materials

extension View {
    @ViewBuilder
    func glassCard(contentPadding: CGFloat = 16, cornerRadius: CGFloat = 16) -> some View {
        padding(contentPadding)
            .adaptiveGlassBackground(in: .rect(cornerRadius: cornerRadius))
    }

    @ViewBuilder
    func wizardWindowBackground() -> some View {
        if #available(macOS 26, *) {
            background {
                LinearGradient(
                    colors: [
                        Color.accentColor.opacity(0.12),
                        Color(nsColor: .windowBackgroundColor).opacity(0.4),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
        } else {
            background(.regularMaterial)
        }
    }
}

struct AdaptiveProminentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        AdaptiveProminentButtonStyleBody(configuration: configuration)
    }
}

private struct AdaptiveProminentButtonStyleBody: View {
    let configuration: ButtonStyleConfiguration

    var body: some View {
        configuration.label
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .foregroundStyle(.white)
            .background {
                Capsule()
                    .fill(BrandTheme.accent.opacity(configuration.isPressed ? 0.82 : 1))
            }
    }
}

struct AdaptiveSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.quaternary.opacity(configuration.isPressed ? 0.6 : 1), in: .capsule)
    }
}

// MARK: - Shared controls

struct GoToHeightControl: View {
    @Binding var targetCM: Float
    let useMetric: Bool
    let isMoving: Bool
    let isConnected: Bool
    let onMove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Target height")
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 10) {
                TextField("Height", value: $targetCM, format: .number.precision(.fractionLength(1)))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 88)

                Text(useMetric ? "cm" : "cm")
                    .foregroundStyle(.secondary)

                Button {
                    onMove()
                } label: {
                    Label("Move here", systemImage: "arrow.down.to.line")
                }
                .buttonStyle(AdaptiveProminentButtonStyle())
                .disabled(!isConnected || isMoving)
            }

            if isMoving {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Moving desk…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else if !isConnected {
                Text("Connect your desk to move automatically.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Enter a height you already know — the desk will move there for you.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .glassCard()
    }
}

struct MenuBarLocationHint: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Find the app here")
                .font(.subheadline.weight(.semibold))

            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.quaternary.opacity(0.35))
                    .frame(height: 44)

                HStack(spacing: 10) {
                    Image(systemName: "wifi")
                    Image(systemName: "battery.100")
                    Image(systemName: "table.furniture.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.tint)
                        .padding(6)
                        .background {
                            if #available(macOS 26, *) {
                                Circle().fill(.clear).glassEffect(.regular.tint(.accentColor.opacity(0.35)).interactive())
                            } else {
                                Circle().fill(.tint.opacity(0.15))
                            }
                        }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }

            Text("Top-right of your screen, near the clock. On a MacBook with a notch, check the **»** menu if you don't see it.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .glassCard()
    }
}
