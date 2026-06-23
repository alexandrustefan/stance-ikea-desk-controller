import XCTest
@testable import Stance

final class DeskCalibrationTests: XCTestCase {
    private func sampleCalibration() -> DeskCalibration {
        DeskCalibration(
            minHeight: 62,
            maxHeight: 125,
            rawMin: 50,
            rawMax: 6350,
            heightOffset: 61.5,
            calibratedAt: Date(timeIntervalSince1970: 0)
        )
    }

    func testDisplayHeightCMFromRaw() {
        let calibration = sampleCalibration()
        XCTAssertEqual(calibration.displayHeightCM(fromRaw: 1050), 72, accuracy: 0.01)
    }

    func testRawValueForHeightCM() {
        let calibration = sampleCalibration()
        XCTAssertEqual(calibration.rawValue(forHeightCM: 72), 1050)
    }

    func testPercentInRangeAtMinAndMax() {
        let calibration = sampleCalibration()
        XCTAssertEqual(calibration.percentInRange(heightCM: 62), 0, accuracy: 0.01)
        XCTAssertEqual(calibration.percentInRange(heightCM: 125), 100, accuracy: 0.01)
    }

    func testPercentInRangeMidpoint() {
        let calibration = sampleCalibration()
        XCTAssertEqual(calibration.percentInRange(heightCM: 93.5), 50, accuracy: 0.1)
    }

    func testPercentInRangeClampsBelowMin() {
        let calibration = sampleCalibration()
        XCTAssertEqual(calibration.percentInRange(heightCM: 40), 0, accuracy: 0.01)
    }

    func testPercentInRangeClampsAboveMax() {
        let calibration = sampleCalibration()
        XCTAssertEqual(calibration.percentInRange(heightCM: 200), 100, accuracy: 0.01)
    }

    func testPercentInRangeReturnsZeroWhenRangeInvalid() {
        var calibration = sampleCalibration()
        calibration.maxHeight = calibration.minHeight
        XCTAssertEqual(calibration.percentInRange(heightCM: 80), 0)
    }

    func testCalibrationJSONRoundTrip() throws {
        let original = sampleCalibration()
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DeskCalibration.self, from: data)
        XCTAssertEqual(decoded, original)
    }
}
