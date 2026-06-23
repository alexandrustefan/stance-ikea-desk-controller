import XCTest
@testable import Stance

final class DeskDeviceTests: XCTestCase {
    func testTitlePrefersDisplayName() {
        let desk = DeskDevice(
            peripheralUUID: UUID(),
            bleName: "LINAK Desk ABC",
            displayName: "Office Desk"
        )
        XCTAssertEqual(desk.title, "Office Desk")
    }

    func testTitleFallsBackToBleNameWhenDisplayNameEmpty() {
        let desk = DeskDevice(
            peripheralUUID: UUID(),
            bleName: "LINAK Desk ABC",
            displayName: ""
        )
        XCTAssertEqual(desk.title, "LINAK Desk ABC")
    }

    func testDecodingUsesBleNameWhenDisplayNameMissing() throws {
        let id = UUID()
        let peripheralID = UUID()
        let json = """
        {
          "id": "\(id.uuidString)",
          "peripheralUUID": "\(peripheralID.uuidString)",
          "bleName": "My IDÅSEN",
          "isPaired": true
        }
        """.data(using: .utf8)!

        let desk = try JSONDecoder().decode(DeskDevice.self, from: json)
        XCTAssertEqual(desk.displayName, "My IDÅSEN")
        XCTAssertEqual(desk.title, "My IDÅSEN")
    }

    func testDeskDeviceJSONRoundTrip() throws {
        let desk = DeskDevice(
            peripheralUUID: UUID(),
            bleName: "Desk",
            displayName: "Home",
            calibration: DeskCalibration(
                minHeight: 62,
                maxHeight: 125,
                rawMin: 1,
                rawMax: 6300,
                heightOffset: 61.5,
                calibratedAt: .now
            )
        )
        let data = try JSONEncoder().encode(desk)
        let decoded = try JSONDecoder().decode(DeskDevice.self, from: data)
        XCTAssertEqual(decoded, desk)
    }
}
