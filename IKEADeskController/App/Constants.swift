import Foundation

enum AppConstants {
    /// Product brand name shown in UI, menu bar, and Finder.
    static let appName = "Stance"
    static let appTagline = "Sit · Stand · Move"

    static let bundleID = "com.alexandrustefan.ikea-desk-controller"
    static let appGroupID = "group.com.alexandrustefan.ikea-desk-controller"
    static let githubURL = "https://github.com/alexandrustefan/stance-ikea-desk-controller"

    enum UserDefaultsKey {
        static let deskDevices = "deskDevices"
        static let profiles = "profiles"
        static let activeProfileID = "activeProfileID"
        static let activeDeskID = "activeDeskID"
        static let useMetric = "useMetric"
        static let launchAtLogin = "launchAtLogin"
        static let showHeightInMenuBar = "showHeightInMenuBar"
        static let legacyMovementFallback = "legacyMovementFallback"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let savedPeripheralUUID = "savedPeripheralUUID"
    }

    enum LINAK {
        static let controlService = "99FA0001-338A-1024-8A49-009C0215F78A"
        static let controlCharacteristic = "99FA0002-338A-1024-8A49-009C0215F78A"
        static let positionService = "99FA0020-338A-1024-8A49-009C0215F78A"
        static let positionCharacteristic = "99FA0021-338A-1024-8A49-009C0215F78A"
        static let referenceInputService = "99FA0030-338A-1024-8A49-009C0215F78A"
        static let referenceInputCharacteristic = "99FA0031-338A-1024-8A49-009C0215F78A"

        static let defaultHeightOffsetCM: Float = 61.5
        static let moveLoopInterval: TimeInterval = 0.1
        static let moveHeightToleranceMeters: Float = 0.005
        static let consecutiveZeroSpeedRequired = 2
        static let maxStallRetries = 3
    }
}
