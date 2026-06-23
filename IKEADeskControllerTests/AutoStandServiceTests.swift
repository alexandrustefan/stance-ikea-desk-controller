import XCTest
@testable import Stance

@MainActor
final class AutoStandServiceTests: XCTestCase {
    func testFormattedDurationMinutesOnly() {
        let service = AutoStandService()
        XCTAssertEqual(service.formattedDuration(45 * 60), "45m")
    }

    func testFormattedDurationHoursAndMinutes() {
        let service = AutoStandService()
        XCTAssertEqual(service.formattedDuration(90 * 60), "1h 30m")
    }

    func testTodayStandingDurationEmptyReturnsZero() {
        let service = AutoStandService()
        XCTAssertEqual(service.todayStandingDuration, 0)
    }

    func testTodaySessionCountEmptyReturnsZero() {
        let service = AutoStandService()
        XCTAssertEqual(service.todaySessionCount, 0)
    }

    func testSnoozeAndSkipDoNotCrash() {
        let service = AutoStandService()
        service.snooze(minutes: 5)
        service.skipCurrentTransition()
    }
}
