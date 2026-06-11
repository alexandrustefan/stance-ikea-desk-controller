import SwiftUI

extension View {
  /// Applies Liquid Glass on macOS 26+; falls back to ultra-thin material on earlier releases.
  /// Apply after layout modifiers (padding, frame) per Liquid Glass guidance.
  @ViewBuilder
  func adaptiveGlassBackground(in shape: some Shape = .rect(cornerRadius: 12)) -> some View {
    if #available(macOS 26, *) {
      // Background-only glass — applying glassEffect directly to interactive content
      // swallows clicks on macOS 26+.
      background {
        Color.clear
          .glassEffect(.regular, in: shape)
      }
    } else {
      background(.ultraThinMaterial, in: shape)
    }
  }

  /// Glass button styles on macOS 26+; standard bordered styles on earlier releases.
  @ViewBuilder
  func adaptiveControlButtonStyle(prominent: Bool = false) -> some View {
    if #available(macOS 26, *) {
      if prominent {
        buttonStyle(.glassProminent)
      } else {
        buttonStyle(.glass)
      }
    } else if prominent {
      buttonStyle(.borderedProminent)
    } else {
      buttonStyle(.bordered)
    }
  }
}
