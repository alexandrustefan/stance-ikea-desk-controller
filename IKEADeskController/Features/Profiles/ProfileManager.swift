import Foundation

@MainActor
@Observable
final class ProfileManager {
    private(set) var profiles: [DeskProfile] = []
    var activeProfileID: UUID?

    private let store: AppDataStore

    init(store: AppDataStore) {
        self.store = store
        load()
    }

    var activeProfile: DeskProfile? {
        guard let activeProfileID else { return profiles.first }
        return profiles.first { $0.id == activeProfileID } ?? profiles.first
    }

    func profiles(for deskId: UUID) -> [DeskProfile] {
        profiles.filter { $0.deskDeviceId == deskId }
    }

    func load() {
        profiles = store.loadProfiles()
        activeProfileID = store.loadActiveProfileID() ?? profiles.first?.id
    }

    func save() {
        store.saveProfiles(profiles)
        store.saveActiveProfileID(activeProfileID)
        SpotlightIndexer.indexProfiles(profiles)
    }

    func createProfile(name: String, deskDeviceId: UUID, sitHeight: Float, standHeight: Float) -> DeskProfile {
        let profile = DeskProfile(
            deskDeviceId: deskDeviceId,
            name: name,
            sitHeight: sitHeight,
            standHeight: standHeight
        )
        profiles.append(profile)
        activeProfileID = profile.id
        save()
        return profile
    }

    func updateProfile(_ profile: DeskProfile) {
        guard let index = profiles.firstIndex(where: { $0.id == profile.id }) else { return }
        var updated = profile
        updated.updatedAt = .now
        profiles[index] = updated
        save()
    }

    func deleteProfile(_ profile: DeskProfile) {
        guard profiles.count > 1 else { return }
        SpotlightIndexer.deleteProfiles(ids: [profile.id])
        profiles.removeAll { $0.id == profile.id }
        if activeProfileID == profile.id {
            activeProfileID = profiles.first?.id
        }
        save()
    }

    func duplicateProfile(_ profile: DeskProfile) {
        let copy = DeskProfile(
            deskDeviceId: profile.deskDeviceId,
            name: "\(profile.name) Copy",
            icon: profile.icon,
            sitHeight: profile.sitHeight,
            standHeight: profile.standHeight,
            customPositions: profile.customPositions,
            hotkeys: profile.hotkeys,
            autoStand: profile.autoStand
        )
        profiles.append(copy)
        save()
    }

    func setActiveProfile(_ profile: DeskProfile) {
        activeProfileID = profile.id
        save()
    }

    func cycleActiveProfile() {
        guard !profiles.isEmpty else { return }
        guard let current = activeProfile,
              let index = profiles.firstIndex(where: { $0.id == current.id })
        else {
            activeProfileID = profiles.first?.id
            save()
            return
        }
        let nextIndex = (index + 1) % profiles.count
        activeProfileID = profiles[nextIndex].id
        save()
    }

    func exportJSON() throws -> Data {
        try JSONEncoder().encode(profiles)
    }

    func importJSON(_ data: Data) throws {
        let imported = try JSONDecoder().decode([DeskProfile].self, from: data)
        profiles = imported
        activeProfileID = imported.first?.id
        save()
    }
}
