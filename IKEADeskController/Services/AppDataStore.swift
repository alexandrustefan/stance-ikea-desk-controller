import Foundation

@MainActor
final class AppDataStore {
    private let defaults: UserDefaults

    init(userDefaults: UserDefaults? = nil) {
        defaults = userDefaults ?? UserDefaults(suiteName: AppConstants.appGroupID) ?? .standard
    }

    func loadDeskDevices() -> [DeskDevice] {
        decode([DeskDevice].self, forKey: AppConstants.UserDefaultsKey.deskDevices) ?? []
    }

    func saveDeskDevices(_ devices: [DeskDevice]) {
        encode(devices, forKey: AppConstants.UserDefaultsKey.deskDevices)
    }

    func loadProfiles() -> [DeskProfile] {
        decode([DeskProfile].self, forKey: AppConstants.UserDefaultsKey.profiles) ?? []
    }

    func saveProfiles(_ profiles: [DeskProfile]) {
        encode(profiles, forKey: AppConstants.UserDefaultsKey.profiles)
    }

    func loadActiveProfileID() -> UUID? {
        guard let string = defaults.string(forKey: AppConstants.UserDefaultsKey.activeProfileID) else { return nil }
        return UUID(uuidString: string)
    }

    func saveActiveProfileID(_ id: UUID?) {
        defaults.set(id?.uuidString, forKey: AppConstants.UserDefaultsKey.activeProfileID)
    }

    func loadActiveDeskID() -> UUID? {
        guard let string = defaults.string(forKey: AppConstants.UserDefaultsKey.activeDeskID) else { return nil }
        return UUID(uuidString: string)
    }

    func saveActiveDeskID(_ id: UUID?) {
        defaults.set(id?.uuidString, forKey: AppConstants.UserDefaultsKey.activeDeskID)
    }

    var useMetric: Bool {
        get {
            if defaults.object(forKey: AppConstants.UserDefaultsKey.useMetric) == nil { return true }
            return defaults.bool(forKey: AppConstants.UserDefaultsKey.useMetric)
        }
        set { defaults.set(newValue, forKey: AppConstants.UserDefaultsKey.useMetric) }
    }

    var launchAtLogin: Bool {
        get { defaults.bool(forKey: AppConstants.UserDefaultsKey.launchAtLogin) }
        set { defaults.set(newValue, forKey: AppConstants.UserDefaultsKey.launchAtLogin) }
    }

    var showHeightInMenuBar: Bool {
        get { defaults.bool(forKey: AppConstants.UserDefaultsKey.showHeightInMenuBar) }
        set { defaults.set(newValue, forKey: AppConstants.UserDefaultsKey.showHeightInMenuBar) }
    }

    var legacyMovementFallback: Bool {
        get { defaults.bool(forKey: AppConstants.UserDefaultsKey.legacyMovementFallback) }
        set { defaults.set(newValue, forKey: AppConstants.UserDefaultsKey.legacyMovementFallback) }
    }

    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: AppConstants.UserDefaultsKey.hasCompletedOnboarding) }
        set { defaults.set(newValue, forKey: AppConstants.UserDefaultsKey.hasCompletedOnboarding) }
    }

    var savedPeripheralUUID: UUID? {
        get {
            guard let string = defaults.string(forKey: AppConstants.UserDefaultsKey.savedPeripheralUUID) else { return nil }
            return UUID(uuidString: string)
        }
        set {
            defaults.set(newValue?.uuidString, forKey: AppConstants.UserDefaultsKey.savedPeripheralUUID)
        }
    }

    private func encode<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    private func decode<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
