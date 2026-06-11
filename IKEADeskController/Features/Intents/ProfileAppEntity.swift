import AppIntents
import CoreSpotlight
import Foundation

struct ProfileEntity: AppEntity, IndexedEntity {
  static let defaultQuery = ProfileEntityQuery()

  nonisolated(unsafe) static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Profile")

  var id: String
  @Property(title: "Name") var name: String

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(name)")
  }

  var attributeSet: CSSearchableItemAttributeSet {
    let attributes = defaultAttributeSet
    attributes.keywords = ["desk", "profile", "sit", "stand"]
    return attributes
  }

  init(from profile: DeskProfile) {
    id = profile.id.uuidString
    name = profile.name
  }
}

struct ProfileEntityQuery: EntityStringQuery {
  func entities(for identifiers: [ProfileEntity.ID]) async throws -> [ProfileEntity] {
    await MainActor.run {
      guard let appState = AppState.current else { return [] }
      return appState.profileManager.profiles
        .filter { identifiers.contains($0.id.uuidString) }
        .map(ProfileEntity.init)
    }
  }

  func entities(matching string: String) async throws -> [ProfileEntity] {
    await MainActor.run {
      guard let appState = AppState.current else { return [] }
      return appState.profileManager.profiles
        .filter { $0.name.localizedCaseInsensitiveContains(string) }
        .map(ProfileEntity.init)
    }
  }

  func suggestedEntities() async throws -> [ProfileEntity] {
    await MainActor.run {
      guard let appState = AppState.current else { return [] }
      if let active = appState.profileManager.activeProfile {
        return [ProfileEntity(from: active)]
      }
      return appState.profileManager.profiles.prefix(5).map(ProfileEntity.init)
    }
  }
}
