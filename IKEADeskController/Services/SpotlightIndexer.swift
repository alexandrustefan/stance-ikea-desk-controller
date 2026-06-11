import CoreSpotlight
import Foundation

@MainActor
enum SpotlightIndexer {
  private static let profileIndexName = "com.alexandrustefan.ikea-desk-controller.profiles"

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
}
