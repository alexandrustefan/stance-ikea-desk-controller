import XCTest
@testable import Stance

final class DeskProtocolTests: XCTestCase {
    func testParsePositionDataReturnsNilForShortData() {
        XCTAssertNil(DeskProtocol.parsePositionData(Data([0x01, 0x02, 0x03]), offsetCM: 0))
    }

    func testParsePositionDataDecodesHeightAndSpeed() {
        let rawHeight: UInt16 = 5050 // (112.0 - 61.5) * 100
        let rawSpeed: Int16 = 42
        var data = Data()
        data.append(contentsOf: withUnsafeBytes(of: rawHeight.littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: rawSpeed.littleEndian) { Array($0) })

        let position = DeskProtocol.parsePositionData(data, offsetCM: 61.5)

        XCTAssertNotNil(position)
        XCTAssertEqual(Double(position!.heightCM), 112.0, accuracy: 0.01)
        XCTAssertEqual(position!.speed, 42)
    }

    func testReferenceInputPayloadEncodesHeight() {
        let payload = DeskProtocol.referenceInputPayload(heightCM: 112, offsetCM: 61.5)

        XCTAssertEqual(payload.count, 2)
        let decoded = payload.withUnsafeBytes { $0.load(as: UInt16.self) }
        XCTAssertEqual(decoded, 5050)
    }

    func testReferenceInputPayloadClampsToUInt16Range() {
        let payload = DeskProtocol.referenceInputPayload(heightCM: 9999, offsetCM: 0)
        let decoded = payload.withUnsafeBytes { $0.load(as: UInt16.self) }
        XCTAssertEqual(decoded, UInt16.max)
    }

    func testDefaultOffsetCMMatchesAppConstants() {
        XCTAssertEqual(DeskProtocol.defaultOffsetCM(), AppConstants.LINAK.defaultHeightOffsetCM)
    }

    func testMatchesDeskNameRecognizesKnownNames() {
        XCTAssertTrue(DeskProtocol.matchesDeskName("IDASEN Desk"))
        XCTAssertTrue(DeskProtocol.matchesDeskName("My Linak Controller"))
        XCTAssertTrue(DeskProtocol.matchesDeskName("Standing desk"))
    }

    func testMatchesDeskNameRejectsUnknownNames() {
        XCTAssertFalse(DeskProtocol.matchesDeskName("Keyboard"))
        XCTAssertFalse(DeskProtocol.matchesDeskName(nil))
        XCTAssertFalse(DeskProtocol.matchesDeskName(""))
    }
}
