import Foundation
import SwiftUI

extension Data {
    init?(hexString: String) {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        var index = hexString.startIndex
        for _ in 0 ..< len {
            let next = hexString.index(index, offsetBy: 2)
            guard let byte = UInt8(hexString[index ..< next], radix: 16) else { return nil }
            data.append(byte)
            index = next
        }
        self = data
    }
}

extension Float {
    func convertToInches() -> Float {
        Measurement(value: Double(self), unit: UnitLength.centimeters)
            .converted(to: .inches)
            .value
            .floatValue
    }

    func convertToCentimeters() -> Float {
        Measurement(value: Double(self), unit: UnitLength.inches)
            .converted(to: .centimeters)
            .value
            .floatValue
    }

    func rounded(toPlaces places: Int) -> Float {
        let divisor = pow(10.0, Float(places))
        return (self * divisor).rounded() / divisor
    }
}

private extension Double {
    var floatValue: Float { Float(self) }
}

extension Date {
    var nextHour: Date {
        let calendar = Calendar.current
        let minutes = calendar.component(.minute, from: self)
        return calendar.date(byAdding: DateComponents(hour: 1, minute: -minutes), to: self) ?? self
    }
}

enum MaterialStyles {
    @ViewBuilder
    static func popoverBackground() -> some View {
        if #available(macOS 26, *) {
            Color.clear
        } else {
            Color.clear.background(.regularMaterial)
        }
    }

    @ViewBuilder
    static func emphasisCard() -> some View {
        if #available(macOS 26, *) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.clear)
        } else {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.thickMaterial)
        }
    }
}
