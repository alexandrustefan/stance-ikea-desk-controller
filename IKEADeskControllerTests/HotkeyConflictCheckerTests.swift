import XCTest
@testable import Stance

final class HotkeyConflictCheckerTests: XCTestCase {
    private let duplicateCombo = KeyCombo(keyCode: 1, modifiers: 0x1C_0000)

    func testDetectsDuplicateBinding() {
        var bindings = HotkeyBindings.defaults
        bindings.moveStand = duplicateCombo

        let conflicts = HotkeyConflictChecker.conflicts(for: duplicateCombo, in: bindings, excluding: .moveSit)

        XCTAssertEqual(conflicts, [.moveStand])
        XCTAssertTrue(HotkeyConflictChecker.hasConflict(for: duplicateCombo, in: bindings, excluding: .moveSit))
    }

    func testExcludingActionIgnoresSelfConflict() {
        var bindings = HotkeyBindings.defaults
        bindings.moveSit = duplicateCombo

        let conflicts = HotkeyConflictChecker.conflicts(for: duplicateCombo, in: bindings, excluding: .moveSit)

        XCTAssertTrue(conflicts.isEmpty)
        XCTAssertFalse(HotkeyConflictChecker.hasConflict(for: duplicateCombo, in: bindings, excluding: .moveSit))
    }

    func testUniqueComboHasNoConflict() {
        let unique = KeyCombo(keyCode: 99, modifiers: 0x1C_0000)
        let conflicts = HotkeyConflictChecker.conflicts(for: unique, in: .defaults)

        XCTAssertTrue(conflicts.isEmpty)
        XCTAssertFalse(HotkeyConflictChecker.hasConflict(for: unique, in: .defaults))
    }
}
