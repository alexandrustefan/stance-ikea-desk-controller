import SwiftUI

private struct GlassCardModifier: ViewModifier {
    let enabled: Bool
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        if enabled {
            content.adaptiveGlassBackground(in: .rect(cornerRadius: cornerRadius))
        } else {
            content
        }
    }
}

struct PositionDisplay: View {
    let heightText: String
    let percentText: String?
    var useGlass: Bool = true

    var body: some View {
        VStack(spacing: 4) {
            Text(heightText)
                .font(.system(size: 40, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
            if let percentText {
                Text(percentText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.primary.opacity(useGlass ? 0.03 : 0.04))
        }
        .modifier(GlassCardModifier(enabled: useGlass, cornerRadius: 16))
    }
}
