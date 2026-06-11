import AppKit
import SwiftUI

extension KeyCombo {
    var keyboardShortcut: KeyboardShortcut? {
        guard let key = keyEquivalent else { return nil }
        return KeyboardShortcut(key, modifiers: eventModifiers)
    }

    private var keyEquivalent: KeyEquivalent? {
        switch keyCode {
        case 0: KeyEquivalent("a")
        case 1: KeyEquivalent("s")
        case 2: KeyEquivalent("d")
        case 35: KeyEquivalent("p")
        case 47: KeyEquivalent(".")
        case 125: .downArrow
        case 126: .upArrow
        default: nil
        }
    }

    private var eventModifiers: EventModifiers {
        let flags = NSEvent.ModifierFlags(rawValue: modifiers)
        var result: EventModifiers = []
        if flags.contains(.control) { result.insert(.control) }
        if flags.contains(.option) { result.insert(.option) }
        if flags.contains(.shift) { result.insert(.shift) }
        if flags.contains(.command) { result.insert(.command) }
        return result
    }
}
