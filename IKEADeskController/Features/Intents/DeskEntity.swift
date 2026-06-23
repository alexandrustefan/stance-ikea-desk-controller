import AppIntents
import CoreSpotlight
import Foundation

struct DeskEntity: AppEntity, IndexedEntity {
    static let defaultQuery = DeskEntityQuery()

    nonisolated(unsafe) static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Desk")

    var id: String
    @Property(title: "Name") var name: String
    @Property(title: "Height (cm)") var heightCM: Double
    @Property(title: "Status") var status: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(status) · \(Int(heightCM)) cm"
        )
    }

    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = defaultAttributeSet
        attributes.keywords = ["desk", "height", "sit", "stand", "idasen", "linak"]
        attributes.contentDescription = "\(status) at \(Int(heightCM)) cm"
        return attributes
    }

    init(id: String, name: String, heightCM: Double, status: String) {
        self.id = id
        self.name = name
        self.heightCM = heightCM
        self.status = status
    }
}

struct DeskEntityQuery: EntityStringQuery {
    func entities(for identifiers: [DeskEntity.ID]) async throws -> [DeskEntity] {
        await MainActor.run {
            guard let appState = AppState.current else { return [] }
            let entity = currentDeskEntity(from: appState)
            return identifiers.contains(entity.id) ? [entity] : []
        }
    }

    func entities(matching string: String) async throws -> [DeskEntity] {
        await MainActor.run {
            guard let appState = AppState.current else { return [] }
            let entity = currentDeskEntity(from: appState)
            guard entity.name.localizedCaseInsensitiveContains(string)
                || "desk".localizedCaseInsensitiveContains(string)
                || entity.status.localizedCaseInsensitiveContains(string)
            else { return [] }
            return [entity]
        }
    }

    func suggestedEntities() async throws -> [DeskEntity] {
        await MainActor.run {
            guard let appState = AppState.current else { return [] }
            return [currentDeskEntity(from: appState)]
        }
    }

    @MainActor
    private func currentDeskEntity(from appState: AppState) -> DeskEntity {
        let name = appState.activeDesk?.title ?? AppConstants.appName
        let height = appState.currentHeightCM ?? 0
        let status: String = switch appState.deskManager.connectionState {
        case .connected: "Connected"
        case .connecting: "Connecting"
        case .scanning: "Scanning"
        case .disconnected: "Disconnected"
        }
        let id = appState.activeDesk?.id.uuidString ?? "active-desk"
        return DeskEntity(id: id, name: name, heightCM: height, status: status)
    }
}
