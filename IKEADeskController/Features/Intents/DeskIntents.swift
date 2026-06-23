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

enum HeightUnit: String, AppEnum {
    case centimeters
    case inches

    nonisolated(unsafe) static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Unit")
    nonisolated(unsafe) static var caseDisplayRepresentations: [HeightUnit: DisplayRepresentation] = [
        .centimeters: "Centimeters",
        .inches: "Inches",
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
  nonisolated(unsafe) static var description = IntentDescription("Move the desk to a specific height.")

  @Parameter(title: "Height")
  var height: Double

  @Parameter(title: "Unit", default: .centimeters)
  var unit: HeightUnit

  static var parameterSummary: some ParameterSummary {
    Summary("Move desk to \(\.$height) \(\.$unit)")
  }

  @MainActor
  func perform() async throws -> some IntentResult & ProvidesDialog {
    guard let appState = AppState.current else {
      return .result(dialog: "\(AppConstants.appName) is not available.")
    }
    let heightCM: Float = switch unit {
    case .centimeters: Float(height)
    case .inches: Float(height).convertToCentimeters()
    }
    await appState.moveToHeight(heightCM)
    let label = UnitConverter.formatHeight(heightCM, useMetric: unit == .centimeters)
    return .result(dialog: "Moving desk to \(label).")
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
  nonisolated(unsafe) static var description = IntentDescription("Returns the current desk height.")

  @Parameter(title: "Unit", default: .centimeters)
  var unit: HeightUnit

  @MainActor
  func perform() async throws -> some IntentResult & ReturnsValue<Double> & ProvidesDialog {
    let heightCM = Float(AppState.current?.currentHeightCM ?? 0)
    let useMetric = unit == .centimeters
    let formatted = UnitConverter.formatHeight(heightCM, useMetric: useMetric)
    let value: Double = switch unit {
    case .centimeters: Double(heightCM)
    case .inches: Double(heightCM.convertToInches())
    }
    let profile = AppState.current?.activeProfileName ?? "None"
    return .result(value: value, dialog: "Desk height is \(formatted) (\(profile) profile).")
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
  nonisolated(unsafe) static var description = IntentDescription("Returns the active desk profile with sit and stand heights.")

  @MainActor
  func perform() async throws -> some IntentResult & ReturnsValue<String> {
    guard let profile = AppState.current?.profileManager.activeProfile else {
      return .result(value: "None")
    }
    let summary = "\(profile.name) — sit \(Int(profile.sitHeight)) cm, stand \(Int(profile.standHeight)) cm"
    return .result(value: summary)
  }
}

struct GetStandingSessionSummaryIntent: AppIntent {
  nonisolated(unsafe) static var title: LocalizedStringResource = "Get Standing Session Summary"
  nonisolated(unsafe) static var description = IntentDescription("Returns how long you've stood at your desk today.")

  @MainActor
  func perform() async throws -> some IntentResult & ReturnsValue<String> {
    guard let appState = AppState.current else {
      return .result(value: "0m")
    }
    let summary = appState.standingSessionSummary
    let sessions = appState.autoStandService.todaySessionCount
    let full = "\(summary) across \(sessions) session\(sessions == 1 ? "" : "s")"
    return .result(value: full)
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
        "Move desk to \(\.$position) in \(.applicationName)",
      ],
      shortTitle: "Move Desk",
      systemImageName: "desk.fill"
    )
    AppShortcut(
      intent: GetDeskHeightIntent(),
      phrases: [
        "What's my desk height in \(.applicationName)",
        "How high is my desk in \(.applicationName)",
      ],
      shortTitle: "Desk Height",
      systemImageName: "ruler"
    )
    AppShortcut(
      intent: NudgeDeskIntent(),
      phrases: [
        "Nudge my desk \(\.$direction) with \(.applicationName)",
      ],
      shortTitle: "Nudge Desk",
      systemImageName: "arrow.up.arrow.down"
    )
    AppShortcut(
      intent: SwitchProfileIntent(),
      phrases: [
        "Switch to \(\.$profile) in \(.applicationName)",
        "Change desk profile to \(\.$profile) in \(.applicationName)",
      ],
      shortTitle: "Switch Profile",
      systemImageName: "person.crop.rectangle.stack"
    )
    AppShortcut(
      intent: GetStandingSessionSummaryIntent(),
      phrases: [
        "How long have I been standing today in \(.applicationName)",
        "Standing summary in \(.applicationName)",
      ],
      shortTitle: "Standing Summary",
      systemImageName: "figure.stand"
    )
  }
}
