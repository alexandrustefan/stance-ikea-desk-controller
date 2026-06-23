import Foundation

enum HotkeyConflictChecker {
    static func conflicts(
        for candidate: KeyCombo,
        in bindings: HotkeyBindings,
        excluding excludedAction: HotKeyService.HotkeyAction? = nil
    ) -> [HotKeyService.HotkeyAction] {
        HotKeyService.HotkeyAction.allCases.filter { action in
            guard action != excludedAction else { return false }
            guard let existing = combo(for: action, in: bindings) else { return false }
            return existing == candidate
        }
    }

    static func hasConflict(
        for candidate: KeyCombo,
        in bindings: HotkeyBindings,
        excluding excludedAction: HotKeyService.HotkeyAction? = nil
    ) -> Bool {
        !conflicts(for: candidate, in: bindings, excluding: excludedAction).isEmpty
    }

    private static func combo(
        for action: HotKeyService.HotkeyAction,
        in bindings: HotkeyBindings
    ) -> KeyCombo? {
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
