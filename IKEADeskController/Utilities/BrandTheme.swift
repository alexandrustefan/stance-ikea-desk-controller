import SwiftUI

enum BrandTheme {
    /// Sage green — wellness / standing-desk accent (not IKEA trademark colors).
    static let accent = Color(red: 0.22, green: 0.42, blue: 0.36)
    static let accentSoft = Color(red: 0.22, green: 0.42, blue: 0.36).opacity(0.14)
    static let accentMuted = Color(red: 0.22, green: 0.42, blue: 0.36).opacity(0.08)

    static let stop = Color(red: 0.72, green: 0.26, blue: 0.24)
    static let stopSoft = Color(red: 0.72, green: 0.26, blue: 0.24).opacity(0.14)

    static let wordmark = AppConstants.appName
    static let tagline = AppConstants.appTagline
}

struct BrandMark: View {
    var size: CGFloat = 44
    var cornerRadius: CGFloat = 12

    var body: some View {
        Image(systemName: "table.furniture.fill")
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(BrandTheme.accent)
            .frame(width: size, height: size)
            .background {
                brandMarkBackground(cornerRadius: cornerRadius)
            }
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private func brandMarkBackground(cornerRadius: CGFloat) -> some View {
        #if __MAC_OS_X_VERSION_MAX_ALLOWED >= 260000
            if #available(macOS 26, *) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.clear)
                    .glassEffect(
                        .regular.tint(BrandTheme.accent.opacity(0.22)).interactive(),
                        in: .rect(cornerRadius: cornerRadius)
                    )
            } else {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(BrandTheme.accentSoft)
            }
        #else
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(BrandTheme.accentSoft)
        #endif
    }
}

struct BrandHeader: View {
    var compact: Bool = false
    var subtitle: String?

    var body: some View {
        HStack(alignment: .center, spacing: compact ? 10 : 12) {
            BrandMark(size: compact ? 36 : 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(BrandTheme.wordmark)
                    .font(compact ? .subheadline.weight(.semibold) : .headline.weight(.semibold))
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(BrandTheme.tagline)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .textCase(.uppercase)
                        .tracking(0.6)
                }
            }

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Button styles

struct BrandPresetButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(BrandTheme.accent)
            .background { presetBackground(isPressed: configuration.isPressed) }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }

    @ViewBuilder
    private func presetBackground(isPressed: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        #if __MAC_OS_X_VERSION_MAX_ALLOWED >= 260000
            if #available(macOS 26, *) {
                shape
                    .fill(.clear)
                    .glassEffect(
                        .regular.tint(BrandTheme.accent.opacity(isPressed ? 0.28 : 0.18)).interactive(),
                        in: .rect(cornerRadius: 14)
                    )
            } else {
                shape.fill(isPressed ? BrandTheme.accentSoft : BrandTheme.accentMuted)
                shape.strokeBorder(BrandTheme.accent.opacity(0.18), lineWidth: 1)
            }
        #else
            shape.fill(isPressed ? BrandTheme.accentSoft : BrandTheme.accentMuted)
            shape.strokeBorder(BrandTheme.accent.opacity(0.18), lineWidth: 1)
        #endif
    }
}

struct BrandMovementButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.primary)
            .background { movementBackground(isPressed: configuration.isPressed) }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }

    @ViewBuilder
    private func movementBackground(isPressed: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        #if __MAC_OS_X_VERSION_MAX_ALLOWED >= 260000
            if #available(macOS 26, *) {
                shape
                    .fill(.clear)
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
                    .opacity(isPressed ? 0.85 : 1)
            } else {
                shape.fill(Color.primary.opacity(isPressed ? 0.08 : 0.05))
                shape.strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            }
        #else
            shape.fill(Color.primary.opacity(isPressed ? 0.08 : 0.05))
            shape.strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        #endif
    }
}

struct BrandStopButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(BrandTheme.stop)
            .background { stopBackground(isPressed: configuration.isPressed) }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }

    @ViewBuilder
    private func stopBackground(isPressed: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        #if __MAC_OS_X_VERSION_MAX_ALLOWED >= 260000
            if #available(macOS 26, *) {
                shape
                    .fill(.clear)
                    .glassEffect(
                        .regular.tint(BrandTheme.stop.opacity(isPressed ? 0.3 : 0.2)).interactive(),
                        in: .rect(cornerRadius: 12)
                    )
            } else {
                shape.fill(isPressed ? BrandTheme.stopSoft : BrandTheme.stopSoft.opacity(0.7))
                shape.strokeBorder(BrandTheme.stop.opacity(0.2), lineWidth: 1)
            }
        #else
            shape.fill(isPressed ? BrandTheme.stopSoft : BrandTheme.stopSoft.opacity(0.7))
            shape.strokeBorder(BrandTheme.stop.opacity(0.2), lineWidth: 1)
        #endif
    }
}

struct BrandPlainButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(configuration.isPressed ? .secondary : .primary)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
