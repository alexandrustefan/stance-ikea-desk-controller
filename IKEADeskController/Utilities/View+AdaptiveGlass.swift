import SwiftUI

extension View {
  /// Applies Liquid Glass on macOS 26+ when built with the macOS 26 SDK; falls back to ultra-thin material otherwise.
  /// Apply after layout modifiers (padding, frame) per Liquid Glass guidance.
  @ViewBuilder
  func adaptiveGlassBackground(in shape: some Shape = .rect(cornerRadius: 12)) -> some View {
    #if __MAC_OS_X_VERSION_MAX_ALLOWED >= 260000
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
    #else
      background(.ultraThinMaterial, in: shape)
    #endif
  }

  /// Glass button styles on macOS 26+; standard bordered styles on earlier releases.
  @ViewBuilder
  func adaptiveControlButtonStyle(prominent: Bool = false) -> some View {
    #if __MAC_OS_X_VERSION_MAX_ALLOWED >= 260000
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
    #else
      if prominent {
        buttonStyle(.borderedProminent)
      } else {
        buttonStyle(.bordered)
      }
    #endif
  }
}
