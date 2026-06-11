import Foundation

enum UnitConverter {
    static func formatHeight(_ cm: Float, useMetric: Bool) -> String {
        if useMetric {
            return "\(cm.rounded(toPlaces: 0)) cm"
        }
        let inches = cm.convertToInches()
        return "\(inches.rounded(toPlaces: 1)) in"
    }

    static func parseHeight(_ value: String, useMetric: Bool) -> Float? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let number = Float(trimmed.filter { "0123456789.".contains($0) }) else { return nil }
        if trimmed.lowercased().contains("in") || (!useMetric && !trimmed.lowercased().contains("cm")) {
            return number.convertToCentimeters()
        }
        return number
    }
}
