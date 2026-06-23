import XCTest
@testable import Stance

@MainActor
final class HotKeyServiceTests: XCTestCase {
    func testDisplayStringFormatsDefaultModifiers() {
        let combo = HotkeyBindings.defaults.moveSit!
        let display = HotKeyService.displayString(for: combo)
        XCTAssertTrue(display.contains("⌃"))
        XCTAssertTrue(display.contains("⌥"))
        XCTAssertTrue(display.contains("⌘"))
        XCTAssertTrue(display.contains("S"))
    }

    func testDisplayStringIncludesArrowForMoveUp() {
        let combo = HotkeyBindings.defaults.moveUp!
        let display = HotKeyService.displayString(for: combo)
        XCTAssertTrue(display.contains("↑"))
    }

    func testDisplayStringUsesKeyCodeFallbackForUnknownKeys() {
        let combo = KeyCombo(keyCode: 99, modifiers: 0)
        XCTAssertEqual(HotKeyService.displayString(for: combo), "#99")
    }
}
