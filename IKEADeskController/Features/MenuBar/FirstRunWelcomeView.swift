import SwiftUI

struct FirstRunWelcomeView: View {
    @Bindable var appState: AppState
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header
            MenuBarLocationHint()

            VStack(alignment: .leading, spacing: 8) {
                Label("Lives in the menu bar only", systemImage: "menubar.rectangle")
                Label("No Dock icon", systemImage: "dock.rectangle")
                Label("No menu next to the Apple () menu", systemImage: "apple.logo")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button("Open Calibration") {
                    openWindow(id: "calibration")
                    dismissWindow(id: "welcome")
                }
                .buttonStyle(AdaptiveProminentButtonStyle())
                .keyboardShortcut(.defaultAction)

                Button("Got It") {
                    dismissWindow(id: "welcome")
                }
                .buttonStyle(AdaptiveSecondaryButtonStyle())
            }
        }
        .padding(28)
        .frame(width: 460)
        .wizardWindowBackground()
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
            if appState.showCalibration {
                openWindow(id: "calibration")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            BrandHeader()
            Text("Your desk control panel is always one click away in the menu bar.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
