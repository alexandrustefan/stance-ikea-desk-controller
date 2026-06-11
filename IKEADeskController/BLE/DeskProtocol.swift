import Foundation

enum DeskCommand {
    static let up = Data([0x47, 0x00])
    static let down = Data([0x46, 0x00])
    static let stop = Data([0xFF, 0x00])
    static let wakeup = Data([0xFE, 0x00])
    static let referenceInputStop = Data([0x01, 0x80])
}

enum DeskProtocol {
    static func parsePositionData(_ data: Data, offsetCM: Float) -> DeskPosition? {
        guard data.count >= 4 else { return nil }
        let rawHeight = data.withUnsafeBytes { $0.load(as: UInt16.self) }
        let rawSpeed = data.withUnsafeBytes { $0.load(fromByteOffset: 2, as: Int16.self) }
        let heightCM = Float(rawHeight) / 100.0 + offsetCM
        return DeskPosition(heightCM: heightCM, speed: Float(rawSpeed))
    }

    static func referenceInputPayload(heightCM: Float, offsetCM: Float) -> Data {
        let raw = UInt16(max(0, min(Int(UInt16.max), Int((heightCM - offsetCM) * 100))))
        var value = raw.littleEndian
        return Data(bytes: &value, count: MemoryLayout<UInt16>.size)
    }

    static func defaultOffsetCM() -> Float {
        AppConstants.LINAK.defaultHeightOffsetCM
    }

    static func matchesDeskName(_ name: String?) -> Bool {
        guard let name else { return false }
        let lowered = name.lowercased()
        return lowered.contains("desk") || lowered.contains("idasen") || lowered.contains("linak")
    }
}
