import Foundation
import Intents

enum FocusModeChecker {
    static func shouldSuppress(config: AutoStandConfig) -> Bool {
        guard config.suppressDuringFocusModes.contains("DoNotDisturb") else { return false }
        return INFocusStatusCenter.default.focusStatus.isFocused == true
    }
}
