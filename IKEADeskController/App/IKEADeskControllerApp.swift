import SwiftUI

@main
struct IKEADeskControllerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var appState = AppState()

    var body: some Scene {
        Window(AppConstants.appName, id: "welcome") {
            WelcomeWindowHost(appState: appState)
        }
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.presented)

        Window("Calibration", id: "calibration") {
            CalibrationWizard(appState: appState)
                .environment(appState)
                .onAppear { NSApp.activate(ignoringOtherApps: true) }
        }
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.suppressed)

        Window("Choose Desk", id: "desk-picker") {
            DeskPickerView(appState: appState)
                .environment(appState)
                .frame(width: 360, height: 320)
        }
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.suppressed)
    }
}

private struct WelcomeWindowHost: View {
    @Bindable var appState: AppState
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        Group {
            if !appState.hasCompletedOnboarding {
                FirstRunWelcomeView(appState: appState)
            } else {
                Color.clear.frame(width: 1, height: 1)
            }
        }
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
            if appState.hasCompletedOnboarding {
                dismissWindow(id: "welcome")
            }
        }
    }
}
