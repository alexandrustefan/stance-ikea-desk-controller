import AppIntents
import Foundation

enum DeskPositionIntentValue: String, AppEnum {
  case sit, stand

  nonisolated(unsafe) static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Position")
  nonisolated(unsafe) static var caseDisplayRepresentations: [DeskPositionIntentValue: DisplayRepresentation] = [
    .sit: "Sit",
    .stand: "Stand",
  ]
}

struct MoveDeskToPositionIntent: AppIntent {
  nonisolated(unsafe) static var title: LocalizedStringResource = "Move Desk to Position"
  nonisolated(unsafe) static var description = IntentDescription("Move the desk to sit or stand in the active profile.")

  @Parameter(title: "Position")
  var position: DeskPositionIntentValue

  static var parameterSummary: some ParameterSummary {
    Summary("Move desk to \(\.$position)")
  }

  @MainActor
  func perform() async throws -> some IntentResult & ProvidesDialog {
    guard let appState = AppState.current else {
      return .result(dialog: "\(AppConstants.appName) is not available.")
    }
    switch position {
    case .sit: appState.moveToSit()
    case .stand: appState.moveToStand()
    }
    return .result(dialog: "Moving desk to \(position == .sit ? "sit" : "stand").")
  }
}

struct MoveDeskToHeightIntent: AppIntent {
  nonisolated(unsafe) static var title: LocalizedStringResource = "Move Desk to Height"
  nonisolated(unsafe) static var description = IntentDescription("Move the desk to a specific height in centimeters.")

  @Parameter(title: "Height (cm)")
  var height: Double

  static var parameterSummary: some ParameterSummary {
    Summary("Move desk to \(\.$height) cm")
  }

  @MainActor
  func perform() async throws -> some IntentResult & ProvidesDialog {
    guard let appState = AppState.current else {
      return .result(dialog: "\(AppConstants.appName) is not available.")
    }
    await appState.moveToHeight(Float(height))
    return .result(dialog: "Moving desk to \(Int(height)) centimeters.")
  }
}

struct NudgeDeskIntent: AppIntent {
  nonisolated(unsafe) static var title: LocalizedStringResource = "Nudge Desk"
  nonisolated(unsafe) static var description = IntentDescription("Nudge the desk up toward stand or down toward sit.")

  @Parameter(title: "Direction")
  var direction: DeskPositionIntentValue

  static var parameterSummary: some ParameterSummary {
    Summary("Nudge desk \(\.$direction)")
  }

  @MainActor
  func perform() async throws -> some IntentResult & ProvidesDialog {
    AppState.current?.nudge(toward: direction)
    return .result(dialog: "Nudging desk \(direction == .stand ? "up" : "down").")
  }
}

struct GetDeskHeightIntent: AppIntent {
  nonisolated(unsafe) static var title: LocalizedStringResource = "Get Desk Height"
  nonisolated(unsafe) static var description = IntentDescription("Returns the current desk height in centimeters.")

  @MainActor
  func perform() async throws -> some IntentResult & ReturnsValue<Double> {
    let height = AppState.current?.currentHeightCM ?? 0
    return .result(value: height, dialog: "Desk height is \(Int(height)) centimeters.")
  }
}

struct SwitchProfileIntent: AppIntent {
  nonisolated(unsafe) static var title: LocalizedStringResource = "Switch Profile"
  nonisolated(unsafe) static var description = IntentDescription("Switch to a saved desk profile.")

  @Parameter(title: "Profile")
  var profile: ProfileEntity

  static var parameterSummary: some ParameterSummary {
    Summary("Switch to \(\.$profile)")
  }

  @MainActor
  func perform() async throws -> some IntentResult & ProvidesDialog {
    guard let appState = AppState.current else {
      return .result(dialog: "\(AppConstants.appName) is not available.")
    }
    guard let match = appState.profileManager.profiles.first(where: { $0.id.uuidString == profile.id }) else {
      return .result(dialog: "Profile not found.")
    }
    appState.profileManager.setActiveProfile(match)
    appState.registerHotkeys()
    return .result(dialog: "Switched to \(match.name).")
  }
}

struct GetActiveProfileIntent: AppIntent {
  nonisolated(unsafe) static var title: LocalizedStringResource = "Get Active Profile"
  nonisolated(unsafe) static var description = IntentDescription("Returns the name of the active desk profile.")

  @MainActor
  func perform() async throws -> some IntentResult & ReturnsValue<String> {
    let name = AppState.current?.activeProfileName ?? "None"
    return .result(value: name, dialog: "Active profile is \(name).")
  }
}

struct GetStandingSessionSummaryIntent: AppIntent {
  nonisolated(unsafe) static var title: LocalizedStringResource = "Get Standing Session Summary"
  nonisolated(unsafe) static var description = IntentDescription("Returns how long you've stood at your desk today.")

  @MainActor
  func perform() async throws -> some IntentResult & ReturnsValue<String> {
    let summary = AppState.current?.standingSessionSummary ?? "0m standing today"
    return .result(value: summary, dialog: "\(summary).")
  }
}

struct IKEADeskShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: MoveDeskToPositionIntent(),
      phrases: [
        "Move my desk to \(\.$position) with \(.applicationName)",
        "Stand up with \(.applicationName)",
        "Sit down with \(.applicationName)",
      ],
      shortTitle: "Move Desk",
      systemImageName: "desk.fill"
    )
    AppShortcut(
      intent: SwitchProfileIntent(),
      phrases: [
        "Switch to \(\.$profile) in \(.applicationName)",
      ],
      shortTitle: "Switch Profile",
      systemImageName: "person.crop.rectangle.stack"
    )
  }
}
