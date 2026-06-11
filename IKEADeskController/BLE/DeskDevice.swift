import Foundation

struct DeskCalibration: Codable, Sendable, Equatable {
    var minHeight: Float
    var maxHeight: Float
    var rawMin: UInt16
    var rawMax: UInt16
    var heightOffset: Float
    var calibratedAt: Date

    func displayHeightCM(fromRaw raw: UInt16) -> Float {
        Float(raw) / 100.0 + heightOffset
    }

    func rawValue(forHeightCM height: Float) -> UInt16 {
        UInt16(max(0, (height - heightOffset) * 100))
    }

    var rangePercent: ClosedRange<Float> { 0 ... 100 }

    func percentInRange(heightCM: Float) -> Float {
        guard maxHeight > minHeight else { return 0 }
        let clamped = min(max(heightCM, minHeight), maxHeight)
        return ((clamped - minHeight) / (maxHeight - minHeight)) * 100
    }
}

struct DeskDevice: Codable, Identifiable, Sendable, Equatable {
    let id: UUID
    var peripheralUUID: UUID
    var bleName: String
    /// User-facing label shown in Settings and the menu bar.
    var displayName: String
    var calibration: DeskCalibration?
    var lastConnectedAt: Date
    var isPaired: Bool

    init(
        id: UUID = UUID(),
        peripheralUUID: UUID,
        bleName: String,
        displayName: String? = nil,
        calibration: DeskCalibration? = nil,
        lastConnectedAt: Date = .now,
        isPaired: Bool = true
    ) {
        self.id = id
        self.peripheralUUID = peripheralUUID
        self.bleName = bleName
        self.displayName = displayName ?? bleName
        self.calibration = calibration
        self.lastConnectedAt = lastConnectedAt
        self.isPaired = isPaired
    }

    var title: String {
        displayName.isEmpty ? bleName : displayName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        peripheralUUID = try container.decode(UUID.self, forKey: .peripheralUUID)
        bleName = try container.decode(String.self, forKey: .bleName)
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName) ?? bleName
        calibration = try container.decodeIfPresent(DeskCalibration.self, forKey: .calibration)
        lastConnectedAt = try container.decodeIfPresent(Date.self, forKey: .lastConnectedAt) ?? .now
        isPaired = try container.decodeIfPresent(Bool.self, forKey: .isPaired) ?? true
    }
}
