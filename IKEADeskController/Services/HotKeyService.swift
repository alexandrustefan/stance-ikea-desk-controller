import AppKit
import Foundation

@MainActor
final class HotKeyService {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var bindings = HotkeyBindings.defaults
    private var handlers: [HotkeyAction: () -> Void] = [:]
    private var onKeyUp: ((HotkeyAction) -> Void)?
    private var heldActions: Set<HotkeyAction> = []

    enum HotkeyAction: Hashable {
        case moveSit, moveStand, moveUp, moveDown, cycleProfiles, emergencyStop
    }

    func register(
        bindings: HotkeyBindings,
        handlers: [HotkeyAction: () -> Void],
        onKeyUp: ((HotkeyAction) -> Void)? = nil
    ) {
        self.bindings = bindings
        self.handlers = handlers
        self.onKeyUp = onKeyUp
        heldActions.removeAll()
        guard AccessibilityChecker.isInputMonitoringTrusted(prompt: false) else { return }
        installEventTap()
    }

    func stop() {
        heldActions.removeAll()
        if let eventTap {
            CFMachPortInvalidate(eventTap)
        }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    static func displayString(for combo: KeyCombo) -> String {
        var parts: [String] = []
        let flags = NSEvent.ModifierFlags(rawValue: combo.modifiers)
        if flags.contains(.control) { parts.append("⌃") }
        if flags.contains(.option) { parts.append("⌥") }
        if flags.contains(.shift) { parts.append("⇧") }
        if flags.contains(.command) { parts.append("⌘") }
        parts.append(KeyCodeTranslator.string(for: combo.keyCode))
        return parts.joined()
    }

    private func installEventTap() {
        if let eventTap {
            CFMachPortInvalidate(eventTap)
        }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        heldActions.removeAll()

        let keyDownMask = 1 << CGEventType.keyDown.rawValue
        let keyUpMask = 1 << CGEventType.keyUp.rawValue
        let mask = CGEventMask(keyDownMask | keyUpMask)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, type, event, userInfo in
                guard let userInfo else { return Unmanaged.passUnretained(event) }
                let service = Unmanaged<HotKeyService>.fromOpaque(userInfo).takeUnretainedValue()
                return service.handle(event: event, type: type)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else { return }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        if let runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    private func handle(event: CGEvent, type: CGEventType) -> Unmanaged<CGEvent>? {
        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        let flags = event.flags.rawValue & UInt64(NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue)

        Task { @MainActor in
            switch type {
            case .keyDown:
                for (action, handler) in handlers where matches(action: action, keyCode: keyCode, flags: flags) {
                    if action == .moveUp || action == .moveDown {
                        guard !heldActions.contains(action) else { continue }
                        heldActions.insert(action)
                    }
                    handler()
                }
            case .keyUp:
                for action in HotkeyAction.allCases where matches(action: action, keyCode: keyCode, flags: flags) {
                    if heldActions.contains(action) {
                        heldActions.remove(action)
                        onKeyUp?(action)
                    }
                }
            default:
                break
            }
        }
        return nil
    }

    private func matches(action: HotkeyAction, keyCode: UInt16, flags: UInt64) -> Bool {
        guard let combo = combo(for: action) else { return false }
        return combo.keyCode == keyCode && UInt64(combo.modifiers) == flags
    }

    private func combo(for action: HotkeyAction) -> KeyCombo? {
        switch action {
        case .moveSit: bindings.moveSit
        case .moveStand: bindings.moveStand
        case .moveUp: bindings.moveUp
        case .moveDown: bindings.moveDown
        case .cycleProfiles: bindings.cycleProfiles
        case .emergencyStop: bindings.emergencyStop
        }
    }
}

extension HotKeyService.HotkeyAction: CaseIterable {
    static var allCases: [HotKeyService.HotkeyAction] {
        [.moveSit, .moveStand, .moveUp, .moveDown, .cycleProfiles, .emergencyStop]
    }
}

private enum KeyCodeTranslator {
    static func string(for keyCode: UInt16) -> String {
        switch keyCode {
        case 1: "S"
        case 2: "D"
        case 35: "P"
        case 47: "."
        case 125: "↓"
        case 126: "↑"
        default: "#\(keyCode)"
        }
    }
}
