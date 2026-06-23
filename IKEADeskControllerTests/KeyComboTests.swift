import XCTest
@testable import Stance

final class KeyComboTests: XCTestCase {
    func testKeyComboEqualityAndHashing() {
        let first = KeyCombo(keyCode: 35, modifiers: 0x1C_0000)
        let second = KeyCombo(keyCode: 35, modifiers: 0x1C_0000)
        let different = KeyCombo(keyCode: 36, modifiers: 0x1C_0000)

        XCTAssertEqual(first, second)
        XCTAssertNotEqual(first, different)
        XCTAssertEqual(Set([first, second]).count, 1)
    }

    func testHotkeyBindingsDefaultsContainAllActions() {
        let defaults = HotkeyBindings.defaults

        XCTAssertNotNil(defaults.moveSit)
        XCTAssertNotNil(defaults.moveStand)
        XCTAssertNotNil(defaults.moveUp)
        XCTAssertNotNil(defaults.moveDown)
        XCTAssertNotNil(defaults.cycleProfiles)
        XCTAssertNotNil(defaults.emergencyStop)
    }

    func testHotkeyBindingsJSONRoundTrip() throws {
        let bindings = HotkeyBindings.defaults
        let data = try JSONEncoder().encode(bindings)
        let decoded = try JSONDecoder().decode(HotkeyBindings.self, from: data)

        XCTAssertEqual(decoded, bindings)
    }
}
