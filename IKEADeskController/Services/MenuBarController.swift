import AppKit
import SwiftUI

@MainActor
final class MenuBarController: NSObject, NSPopoverDelegate {
    private let appState: AppState
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private var observationTask: Task<Void, Never>?
    private var globalRightClickMonitor: Any?
    private var lastContextMenuShownAt: TimeInterval = 0

    init(appState: AppState) {
        self.appState = appState
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        popover = NSPopover()
        super.init()

        popover.contentSize = NSSize(width: 300, height: 520)
        popover.behavior = .applicationDefined
        popover.animates = true
        popover.delegate = self

        configureButton()
        installGlobalRightClickMonitor()
        updateLabel()
        startObserving()
    }

    private func configureButton() {
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "table.furniture.fill", accessibilityDescription: AppConstants.appName)
        button.image?.isTemplate = true
        button.imagePosition = .imageLeading
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.action = #selector(statusItemClicked(_:))
        button.target = self
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        if let event = NSApp.currentEvent, shouldShowContextMenu(for: event) {
            showContextMenu()
            return
        }
        togglePopover(relativeTo: sender)
    }

    private func installGlobalRightClickMonitor() {
        globalRightClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.rightMouseDown]) { [weak self] event in
            Task { @MainActor in
                guard let self, self.isEventOnStatusItem(event) else { return }
                self.showContextMenu()
            }
        }
    }

    private func isEventOnStatusItem(_ event: NSEvent) -> Bool {
        guard let button = statusItem.button, let window = button.window else { return false }
        let buttonFrameInWindow = button.convert(button.bounds, to: nil)
        let buttonFrameOnScreen = window.convertToScreen(buttonFrameInWindow)
        return buttonFrameOnScreen.contains(NSEvent.mouseLocation)
    }

    private func shouldShowContextMenu(for event: NSEvent) -> Bool {
        switch event.type {
        case .rightMouseUp, .rightMouseDown, .otherMouseDown, .otherMouseUp:
            return true
        case .leftMouseUp, .leftMouseDown:
            return event.modifierFlags.contains(.control)
        default:
            return false
        }
    }

    private func showContextMenu() {
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastContextMenuShownAt > 0.3 else { return }
        lastContextMenuShownAt = now

        closePopover()
        guard let button = statusItem.button else { return }

        let menu = buildContextMenu()
        let popupPoint = NSPoint(x: 0, y: button.bounds.height)
        menu.popUp(positioning: nil, at: popupPoint, in: button)
    }

    private func togglePopover(relativeTo button: NSStatusBarButton) {
        if popover.isShown {
            closePopover()
            return
        }

        // Accessory apps must activate or the first click is swallowed by the system.
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        let host = NSHostingController(
            rootView: MenuBarPopover(appState: appState).environment(appState)
        )
        host.sizingOptions = [.intrinsicContentSize]
        popover.contentViewController = host

        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

        if let window = host.view.window {
            window.makeKeyAndOrderFront(nil)
            window.level = .floating
        }
    }

    private func closePopover() {
        popover.performClose(nil)
        restoreActivationPolicyIfNeeded()
    }

    private func restoreActivationPolicyIfNeeded() {
        let utilityWindowsOpen = NSApp.windows.contains { window in
            guard window.isVisible, !window.isMiniaturized else { return false }
            let title = window.title
            return title.contains("Settings") || title.contains("Calibration") || title.contains("Choose Desk")
        }
        if !utilityWindowsOpen {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    func popoverDidClose(_ notification: Notification) {
        restoreActivationPolicyIfNeeded()
    }

    func updateLabel() {
        guard let button = statusItem.button else { return }

        if appState.showHeightInMenuBar,
           let height = appState.deskManager.currentPosition?.heightCM {
            let formatted = UnitConverter.formatHeight(height, useMetric: appState.useMetric)
            let compact = formatted
                .replacingOccurrences(of: " cm", with: "")
                .replacingOccurrences(of: "\"", with: "")
            button.title = " \(compact)"
            button.image = NSImage(systemSymbolName: "table.furniture.fill", accessibilityDescription: nil)
            button.image?.isTemplate = true
        } else {
            button.title = ""
            button.image = NSImage(systemSymbolName: "table.furniture.fill", accessibilityDescription: AppConstants.appName)
            button.image?.isTemplate = true
        }
    }

    private func startObserving() {
        observationTask?.cancel()
        observationTask = Task { @MainActor [weak self] in
            guard let self else { return }
            withObservationTracking {
                _ = self.appState.showHeightInMenuBar
                _ = self.appState.useMetric
                _ = self.appState.deskManager.currentPosition?.heightCM
            } onChange: {
                Task { @MainActor in
                    self.updateLabel()
                    self.startObserving()
                }
            }
            updateLabel()
        }
    }

    private func buildContextMenu() -> NSMenu {
        let menu = NSMenu()
        let profile = appState.profileManager.activeProfile

        menu.addItem(actionItem("Move to Sit", combo: profile?.hotkeys.moveSit) { [weak self] in
            self?.appState.moveToSit()
        })
        menu.addItem(actionItem("Move to Stand", combo: profile?.hotkeys.moveStand) { [weak self] in
            self?.appState.moveToStand()
        })
        menu.addItem(.separator())
        menu.addItem(actionItem("Move Up", combo: profile?.hotkeys.moveUp) { [weak self] in
            self?.appState.deskManager.movement.moveUp()
        })
        menu.addItem(actionItem("Move Down", combo: profile?.hotkeys.moveDown) { [weak self] in
            self?.appState.deskManager.movement.moveDown()
        })
        menu.addItem(actionItem("Stop", combo: profile?.hotkeys.emergencyStop) { [weak self] in
            self?.appState.stopMovement()
        })
        menu.addItem(.separator())
        menu.addItem(actionItem("Settings…", combo: nil) { [weak self] in
            self?.appState.openSettings()
        })
        menu.addItem(actionItem("Recalibrate…", combo: nil) { [weak self] in
            self?.appState.openCalibration()
        })
        menu.addItem(.separator())
        menu.addItem(actionItem("Quit \(AppConstants.appName)", combo: nil) { [weak self] in
            self?.appState.quitApp()
        })
        return menu
    }

    private func actionItem(_ title: String, combo: KeyCombo?, action: @escaping () -> Void) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: #selector(contextMenuItemSelected(_:)), keyEquivalent: "")
        item.target = self
        item.representedObject = ContextMenuAction(handler: action)

        if let combo {
            item.keyEquivalent = keyEquivalentString(for: combo)
            item.keyEquivalentModifierMask = modifierFlags(for: combo)
        }
        return item
    }

    @objc private func contextMenuItemSelected(_ sender: NSMenuItem) {
        (sender.representedObject as? ContextMenuAction)?.handler()
    }

    private func keyEquivalentString(for combo: KeyCombo) -> String {
        switch combo.keyCode {
        case 0: "a"
        case 1: "s"
        case 2: "d"
        case 35: "p"
        case 47: "."
        case 125: String(UnicodeScalar(NSDownArrowFunctionKey)!)
        case 126: String(UnicodeScalar(NSUpArrowFunctionKey)!)
        default: ""
        }
    }

    private func modifierFlags(for combo: KeyCombo) -> NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(rawValue: combo.modifiers)
    }

    private final class ContextMenuAction {
        let handler: () -> Void
        init(handler: @escaping () -> Void) { self.handler = handler }
    }
}
