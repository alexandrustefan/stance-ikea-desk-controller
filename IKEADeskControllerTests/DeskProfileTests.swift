import XCTest
@testable import Stance

final class DeskProfileTests: XCTestCase {
    func testDeskProfileJSONRoundTrip() throws {
        let profile = DeskProfile(
            deskDeviceId: UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890")!,
            name: "Office",
            icon: "desktopcomputer",
            sitHeight: 72,
            standHeight: 112,
            customPositions: [
                CustomPosition(name: "Meeting", icon: "person.3", height: 95)
            ],
            hotkeys: .defaults,
            autoStand: .default,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_700_000_100)
        )

        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(DeskProfile.self, from: data)

        XCTAssertEqual(decoded, profile)
    }

    func testAutoStandConfigJSONRoundTrip() throws {
        var config = AutoStandConfig.default
        config.enabled = true
        config.scheduleMode = .interval
        config.intervalStandMinutes = 50
        config.intervalSitMinutes = 15
        config.activeWeekdays = [2, 3, 4, 5]

        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(AutoStandConfig.self, from: data)

        XCTAssertEqual(decoded, config)
    }

    func testScheduleEntryJSONRoundTrip() throws {
        let entry = ScheduleEntry(
            id: UUID(uuidString: "11111111-2222-3333-4444-555555555555")!,
            startTime: DateComponents(hour: 9, minute: 30),
            endTime: DateComponents(hour: 10, minute: 0),
            action: .moveToHeight(105)
        )

        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(ScheduleEntry.self, from: data)

        XCTAssertEqual(decoded, entry)
    }

    func testScheduleActionPresetRoundTrip() throws {
        let presetID = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
        let action = ScheduleAction.preset(presetID)

        let data = try JSONEncoder().encode(action)
        let decoded = try JSONDecoder().decode(ScheduleAction.self, from: data)

        XCTAssertEqual(decoded, action)
    }
}
