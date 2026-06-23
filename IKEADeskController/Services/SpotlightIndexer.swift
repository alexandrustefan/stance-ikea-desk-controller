import CoreSpotlight
import Foundation

@MainActor
enum SpotlightIndexer {
    private static let profileIndexName = "com.alexandrustefan.ikea-desk-controller.profiles"
    private static let deskIndexName = "com.alexandrustefan.ikea-desk-controller.desk"

    static func indexProfiles(_ profiles: [DeskProfile]) {
        let entities = profiles.map(ProfileEntity.init)
        let indexName = profileIndexName
        Task {
            let index = CSSearchableIndex(name: indexName)
            try? await index.indexAppEntities(entities)
        }
    }

    static func deleteProfiles(ids: [UUID]) {
        let indexName = profileIndexName
        let idStrings = ids.map(\.uuidString)
        Task {
            let index = CSSearchableIndex(name: indexName)
            try? await index.deleteAppEntities(
                identifiedBy: idStrings,
                ofType: ProfileEntity.self
            )
        }
    }

    static func indexDesk(appState: AppState) {
        let name = appState.activeDesk?.title ?? AppConstants.appName
        let height = appState.currentHeightCM ?? 0
        let status: String = switch appState.deskManager.connectionState {
        case .connected: "Connected"
        case .connecting: "Connecting"
        case .scanning: "Scanning"
        case .disconnected: "Disconnected"
        }
        let id = appState.activeDesk?.id.uuidString ?? "active-desk"
        let entity = DeskEntity(id: id, name: name, heightCM: height, status: status)
        let indexName = deskIndexName
        Task {
            let index = CSSearchableIndex(name: indexName)
            try? await index.indexAppEntities([entity])
        }
    }
}
