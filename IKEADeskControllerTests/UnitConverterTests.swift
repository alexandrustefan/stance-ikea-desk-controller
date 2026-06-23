import XCTest
@testable import Stance

final class UnitConverterTests: XCTestCase {
    func testFormatHeightMetric() {
        XCTAssertEqual(UnitConverter.formatHeight(72.4, useMetric: true), "72.0 cm")
    }

    func testFormatHeightImperial() {
        let formatted = UnitConverter.formatHeight(2.54, useMetric: false)
        XCTAssertEqual(formatted, "1.0 in")
    }

    func testParseHeightMetricValue() {
        XCTAssertEqual(UnitConverter.parseHeight("112 cm", useMetric: true), 112)
        XCTAssertEqual(UnitConverter.parseHeight("  90.5  ", useMetric: true), 90.5)
    }

    func testParseHeightImperialValue() {
        let parsed = UnitConverter.parseHeight("30 in", useMetric: false)
        XCTAssertEqual(parsed ?? 0, 76.2, accuracy: 0.1)
    }

    func testParseHeightImperialWithoutUnitWhenNotMetric() {
        let parsed = UnitConverter.parseHeight("30", useMetric: false)
        XCTAssertEqual(parsed ?? 0, 76.2, accuracy: 0.1)
    }

    func testParseHeightReturnsNilForInvalidInput() {
        XCTAssertNil(UnitConverter.parseHeight("abc", useMetric: true))
        XCTAssertNil(UnitConverter.parseHeight("", useMetric: true))
    }

    func testCentimeterInchRoundTrip() {
        let cm: Float = 100
        let inches = cm.convertToInches()
        let backToCM = inches.convertToCentimeters()
        XCTAssertEqual(backToCM, cm, accuracy: 0.01)
    }
}
