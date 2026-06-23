import ApplicationServices
import Foundation

enum AccessibilityChecker {
    static func isInputMonitoringTrusted(prompt: Bool) -> Bool {
        if CGPreflightListenEventAccess() { return true }
        if prompt {
            CGRequestListenEventAccess()
        }
        return CGPreflightListenEventAccess()
    }
}
