import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var menuBarController: MenuBarController?
    private var calibrationWindow: NSWindow?
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        if let appState = AppState.current {
            menuBarController = MenuBarController(appState: appState)
        }

        NotificationCenter.default.addObserver(
            forName: .openCalibrationWindow,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.presentCalibrationWindow()
            }
        }

        NotificationCenter.default.addObserver(
            forName: .openSettingsWindow,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.presentSettingsWindow()
            }
        }
    }

    private func presentCalibrationWindow() {
        guard let appState = AppState.current else { return }
        activateForWindowPresentation()

        if calibrationWindow == nil {
            calibrationWindow = makeWindow(
                title: "Calibration",
                size: NSSize(width: 560, height: 520),
                rootView: CalibrationWizard(appState: appState).environment(appState)
            )
            calibrationWindow?.delegate = self
        }

        showWindow(calibrationWindow)
    }

    private func presentSettingsWindow() {
        guard let appState = AppState.current else { return }
        activateForWindowPresentation()

        if settingsWindow == nil {
            settingsWindow = makeWindow(
                title: "\(AppConstants.appName) Settings",
                size: NSSize(width: 820, height: 560),
                rootView: SettingsView(appState: appState).environment(appState)
            )
            settingsWindow?.delegate = self
        }

        showWindow(settingsWindow)
    }

    private func makeWindow<V: View>(title: String, size: NSSize, rootView: V) -> NSWindow {
        let host = NSHostingController(rootView: rootView)
        let window = NSWindow(contentViewController: host)
        window.title = title
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(size)
        window.minSize = NSSize(width: 720, height: 480)
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        return window
    }

    private func showWindow(_ window: NSWindow?) {
        guard let window else { return }
        if window.isMiniaturized {
            window.deminiaturize(nil)
        }
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }

    /// Menu-bar-only apps must switch out of `.accessory` to present normal windows.
    private func activateForWindowPresentation() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func restoreAccessoryPolicyIfNeeded() {
        let hasVisibleUtilityWindow = [settingsWindow, calibrationWindow].contains { window in
            guard let window else { return false }
            return window.isVisible && !window.isMiniaturized
        }
        if !hasVisibleUtilityWindow {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    func windowWillClose(_ notification: Notification) {
        restoreAccessoryPolicyIfNeeded()
    }
}
