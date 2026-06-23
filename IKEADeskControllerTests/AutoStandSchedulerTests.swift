import XCTest
@testable import Stance

final class AutoStandSchedulerTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(year: Int, month: Int, day: Int, hour: Int, minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    private func makeConfig(
        enabled: Bool = true,
        scheduleMode: ScheduleMode = .hourly,
        customSchedule: [ScheduleEntry] = [],
        activeHourStart: DateComponents = DateComponents(hour: 9, minute: 0),
        activeHourEnd: DateComponents = DateComponents(hour: 17, minute: 0),
        activeWeekdays: [Int] = [2, 3, 4, 5, 6],
        quietHoursStart: DateComponents = DateComponents(hour: 22, minute: 0),
        quietHoursEnd: DateComponents = DateComponents(hour: 7, minute: 0)
    ) -> AutoStandConfig {
        var config = AutoStandConfig.default
        config.enabled = enabled
        config.scheduleMode = scheduleMode
        config.customSchedule = customSchedule
        config.activeHourStart = activeHourStart
        config.activeHourEnd = activeHourEnd
        config.activeWeekdays = activeWeekdays
        config.quietHoursStart = quietHoursStart
        config.quietHoursEnd = quietHoursEnd
        return config
    }

    func testIsActiveWeekdayMatchesConfiguredDays() {
        let config = makeConfig(activeWeekdays: [2, 3, 4, 5, 6])
        let monday = date(year: 2024, month: 1, day: 8, hour: 10) // Monday
        let sunday = date(year: 2024, month: 1, day: 7, hour: 10) // Sunday

        XCTAssertTrue(AutoStandScheduler.isActiveWeekday(monday, config: config, calendar: calendar))
        XCTAssertFalse(AutoStandScheduler.isActiveWeekday(sunday, config: config, calendar: calendar))
    }

    func testIsWithinActiveHoursDuringWorkday() {
        let config = makeConfig()
        let inside = date(year: 2024, month: 1, day: 8, hour: 12)
        let outside = date(year: 2024, month: 1, day: 8, hour: 8)

        XCTAssertTrue(AutoStandScheduler.isWithinActiveHours(inside, config: config, calendar: calendar))
        XCTAssertFalse(AutoStandScheduler.isWithinActiveHours(outside, config: config, calendar: calendar))
    }

    func testIsWithinQuietHoursOvernightRange() {
        let config = makeConfig()
        let lateNight = date(year: 2024, month: 1, day: 8, hour: 23)
        let earlyMorning = date(year: 2024, month: 1, day: 8, hour: 6)
        let midday = date(year: 2024, month: 1, day: 8, hour: 12)

        XCTAssertTrue(AutoStandScheduler.isWithinQuietHours(lateNight, config: config, calendar: calendar))
        XCTAssertTrue(AutoStandScheduler.isWithinQuietHours(earlyMorning, config: config, calendar: calendar))
        XCTAssertFalse(AutoStandScheduler.isWithinQuietHours(midday, config: config, calendar: calendar))
    }

    func testMatchingScheduleEntryFindsCustomBlock() {
        let entry = ScheduleEntry(
            id: UUID(),
            startTime: DateComponents(hour: 13, minute: 0),
            endTime: DateComponents(hour: 14, minute: 0),
            action: .stand
        )
        let config = makeConfig(scheduleMode: .custom, customSchedule: [entry])
        let matching = date(year: 2024, month: 1, day: 8, hour: 13, minute: 30)
        let nonMatching = date(year: 2024, month: 1, day: 8, hour: 15)

        XCTAssertEqual(AutoStandScheduler.matchingScheduleEntry(matching, config: config, calendar: calendar), entry)
        XCTAssertNil(AutoStandScheduler.matchingScheduleEntry(nonMatching, config: config, calendar: calendar))
    }

    func testShouldRunAutoStandRequiresEnabledWeekdayActiveHoursAndNotQuiet() {
        let config = makeConfig()
        let valid = date(year: 2024, month: 1, day: 8, hour: 10) // Monday 10:00
        let disabled = makeConfig(enabled: false)
        let weekend = date(year: 2024, month: 1, day: 7, hour: 10) // Sunday
        let quiet = date(year: 2024, month: 1, day: 8, hour: 23)

        XCTAssertTrue(AutoStandScheduler.shouldRunAutoStand(valid, config: config, calendar: calendar))
        XCTAssertFalse(AutoStandScheduler.shouldRunAutoStand(valid, config: disabled, calendar: calendar))
        XCTAssertFalse(AutoStandScheduler.shouldRunAutoStand(weekend, config: config, calendar: calendar))
        XCTAssertFalse(AutoStandScheduler.shouldRunAutoStand(quiet, config: config, calendar: calendar))
    }

    func testShouldRunAutoStandFalseWhenDisabled() {
        let config = makeConfig(enabled: false)
        let mondayMorning = date(year: 2024, month: 1, day: 8, hour: 10)
        XCTAssertFalse(AutoStandScheduler.shouldRunAutoStand(mondayMorning, config: config, calendar: calendar))
    }

    func testMatchingScheduleEntryReturnsNilForHourlyMode() {
        let entry = ScheduleEntry(
            id: UUID(),
            startTime: DateComponents(hour: 13, minute: 0),
            endTime: DateComponents(hour: 14, minute: 0),
            action: .stand
        )
        let config = makeConfig(scheduleMode: .hourly, customSchedule: [entry])
        let duringBlock = date(year: 2024, month: 1, day: 8, hour: 13, minute: 30)
        XCTAssertNil(AutoStandScheduler.matchingScheduleEntry(duringBlock, config: config, calendar: calendar))
    }

    func testActiveHoursWrapWhenStartEqualsEndIsFalse() {
        let config = makeConfig(
            activeHourStart: DateComponents(hour: 9, minute: 0),
            activeHourEnd: DateComponents(hour: 9, minute: 0)
        )
        let atNine = date(year: 2024, month: 1, day: 8, hour: 9)
        XCTAssertFalse(AutoStandScheduler.isWithinActiveHours(atNine, config: config, calendar: calendar))
    }
}
