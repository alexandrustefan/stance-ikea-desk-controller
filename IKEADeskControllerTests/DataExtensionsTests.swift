import XCTest
@testable import Stance

final class DataExtensionsTests: XCTestCase {
    func testHexStringInitParsesBytes() {
        let data = Data(hexString: "4700")
        XCTAssertEqual(data, Data([0x47, 0x00]))
    }

    func testHexStringInitReturnsNilForInvalidInput() {
        XCTAssertNil(Data(hexString: "GG"))
    }

    func testHexStringInitReturnsEmptyForOddLength() {
        XCTAssertEqual(Data(hexString: "4"), Data())
    }

    func testFloatRounding() {
        XCTAssertEqual(Float(72.456).rounded(toPlaces: 1), 72.5, accuracy: 0.001)
        XCTAssertEqual(Float(72.44).rounded(toPlaces: 0), 72, accuracy: 0.001)
    }
}
