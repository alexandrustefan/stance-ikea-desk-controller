import ApplicationServices
import Foundation

enum AccessibilityChecker {
    static func isInputMonitoringTrusted(prompt: Bool) -> Bool {
        if prompt {
            return AXIsProcessTrustedWithOptions([
                "kAXTrustedCheckOptionPrompt": true,
            ] as CFDictionary)
        }
        return AXIsProcessTrusted()
    }
}
