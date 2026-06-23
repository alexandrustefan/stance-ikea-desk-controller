import XCTest
@testable import Stance

@MainActor
final class ProfileManagerTests: XCTestCase {
    private var defaults: UserDefaults!
    private var store: AppDataStore!
    private var manager: ProfileManager!

    override func setUp() async throws {
        let suiteName = "stance.tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        store = AppDataStore(userDefaults: defaults)
        manager = ProfileManager(store: store)
    }

    override func tearDown() async throws {
        if let defaults {
            defaults.removePersistentDomain(forName: defaults.description)
        }
        defaults = nil
        store = nil
        manager = nil
    }

    func testCreateProfileSetsActive() {
        let deskID = UUID()
        let profile = manager.createProfile(name: "Work", deskDeviceId: deskID, sitHeight: 72, standHeight: 112)

        XCTAssertEqual(manager.profiles.count, 1)
        XCTAssertEqual(manager.activeProfile?.id, profile.id)
        XCTAssertEqual(profile.name, "Work")
    }

    func testProfilesForDeskFiltersByDevice() {
        let deskA = UUID()
        let deskB = UUID()
        _ = manager.createProfile(name: "A1", deskDeviceId: deskA, sitHeight: 70, standHeight: 110)
        _ = manager.createProfile(name: "B1", deskDeviceId: deskB, sitHeight: 71, standHeight: 111)

        XCTAssertEqual(manager.profiles(for: deskA).count, 1)
        XCTAssertEqual(manager.profiles(for: deskA).first?.name, "A1")
        XCTAssertEqual(manager.profiles(for: deskB).count, 1)
    }

    func testCycleActiveProfileStaysWithinDesk() {
        let deskA = UUID()
        let deskB = UUID()
        let a1 = manager.createProfile(name: "A1", deskDeviceId: deskA, sitHeight: 70, standHeight: 110)
        let a2 = manager.createProfile(name: "A2", deskDeviceId: deskA, sitHeight: 71, standHeight: 111)
        _ = manager.createProfile(name: "B1", deskDeviceId: deskB, sitHeight: 72, standHeight: 112)

        manager.setActiveProfile(a1)
        manager.cycleActiveProfile(for: deskA)
        XCTAssertEqual(manager.activeProfile?.id, a2.id)

        manager.cycleActiveProfile(for: deskA)
        XCTAssertEqual(manager.activeProfile?.id, a1.id)

        manager.cycleActiveProfile(for: deskB)
        XCTAssertEqual(manager.activeProfile?.name, "B1")
    }

    func testDeleteProfileRequiresAtLeastOneRemaining() {
        let deskID = UUID()
        let only = manager.createProfile(name: "Only", deskDeviceId: deskID, sitHeight: 72, standHeight: 112)

        manager.deleteProfile(only)
        XCTAssertEqual(manager.profiles.count, 1)
    }

    func testDeleteProfileSwitchesActiveWhenNeeded() {
        let deskID = UUID()
        let first = manager.createProfile(name: "First", deskDeviceId: deskID, sitHeight: 72, standHeight: 112)
        let second = manager.createProfile(name: "Second", deskDeviceId: deskID, sitHeight: 73, standHeight: 113)

        manager.setActiveProfile(first)
        manager.deleteProfile(first)

        XCTAssertEqual(manager.profiles.count, 1)
        XCTAssertEqual(manager.activeProfile?.id, second.id)
    }

    func testDuplicateProfileAppendsCopy() {
        let deskID = UUID()
        let original = manager.createProfile(name: "Work", deskDeviceId: deskID, sitHeight: 72, standHeight: 112)

        manager.duplicateProfile(original)

        XCTAssertEqual(manager.profiles.count, 2)
        XCTAssertEqual(manager.profiles.last?.name, "Work Copy")
        XCTAssertEqual(manager.profiles.last?.sitHeight, 72)
    }

    func testImportExportJSONRoundTrip() throws {
        let deskID = UUID()
        _ = manager.createProfile(name: "Exported", deskDeviceId: deskID, sitHeight: 72, standHeight: 112)

        let data = try manager.exportJSON()

        let isolatedDefaults = UserDefaults(suiteName: "stance.tests.import.\(UUID().uuidString)")!
        let importManager = ProfileManager(store: AppDataStore(userDefaults: isolatedDefaults))
        try importManager.importJSON(data)

        XCTAssertEqual(importManager.profiles.count, 1)
        XCTAssertEqual(importManager.profiles.first?.name, "Exported")
    }

    func testUpdateProfilePersistsChanges() {
        let deskID = UUID()
        var profile = manager.createProfile(name: "Work", deskDeviceId: deskID, sitHeight: 72, standHeight: 112)
        profile.standHeight = 115
        manager.updateProfile(profile)

        XCTAssertEqual(manager.activeProfile?.standHeight, 115)

        let reloaded = ProfileManager(store: store)
        XCTAssertEqual(reloaded.activeProfile?.standHeight, 115)
    }
}
