import Foundation

struct CustomPosition: Codable, Identifiable, Sendable, Equatable {
    let id: UUID
    var name: String
    var icon: String
    var height: Float

    init(id: UUID = UUID(), name: String, icon: String, height: Float) {
        self.id = id
        self.name = name
        self.icon = icon
        self.height = height
    }
}

struct KeyCombo: Codable, Sendable, Equatable, Hashable {
    var keyCode: UInt16
    var modifiers: UInt
}

struct HotkeyBindings: Codable, Sendable, Equatable {
    var moveSit: KeyCombo?
    var moveStand: KeyCombo?
    var moveUp: KeyCombo?
    var moveDown: KeyCombo?
    var cycleProfiles: KeyCombo?
    var emergencyStop: KeyCombo?

    private static let defaultModifiers: UInt = 0x1C_0000 // control + option + command

    static let defaults = HotkeyBindings(
        moveSit: KeyCombo(keyCode: 1, modifiers: defaultModifiers),
        moveStand: KeyCombo(keyCode: 2, modifiers: defaultModifiers),
        moveUp: KeyCombo(keyCode: 126, modifiers: defaultModifiers),
        moveDown: KeyCombo(keyCode: 125, modifiers: defaultModifiers),
        cycleProfiles: KeyCombo(keyCode: 35, modifiers: defaultModifiers),
        emergencyStop: KeyCombo(keyCode: 47, modifiers: defaultModifiers)
    )
}

enum ScheduleMode: String, Codable, Sendable, CaseIterable {
    case hourly
    case interval
    case custom
}

enum ScheduleAction: Codable, Sendable, Equatable {
    case stand
    case sit
    case moveToHeight(Float)
    case preset(UUID)
}

struct ScheduleEntry: Codable, Identifiable, Sendable, Equatable {
    let id: UUID
    var startTime: DateComponents
    var endTime: DateComponents
    var action: ScheduleAction
}

struct AutoStandConfig: Codable, Sendable, Equatable {
    var enabled: Bool
    var standMinutesPerHour: Double
    var inactivityThreshold: Double
    var notificationEnabled: Bool
    var scheduleMode: ScheduleMode
    var customSchedule: [ScheduleEntry]
    var intervalStandMinutes: Double
    var intervalSitMinutes: Double
    var activeHourStart: DateComponents
    var activeHourEnd: DateComponents
    var activeWeekdays: [Int]
    var notifyBeforeMinutes: Double
    var quietHoursStart: DateComponents
    var quietHoursEnd: DateComponents
    var suppressDuringFocusModes: [String]
    var breakRemindersEnabled: Bool
    var breakReminderIntervalMinutes: Double

    static let `default` = AutoStandConfig(
        enabled: false,
        standMinutesPerHour: 10,
        inactivityThreshold: 5,
        notificationEnabled: true,
        scheduleMode: .hourly,
        customSchedule: [],
        intervalStandMinutes: 45,
        intervalSitMinutes: 10,
        activeHourStart: DateComponents(hour: 9, minute: 0),
        activeHourEnd: DateComponents(hour: 17, minute: 0),
        activeWeekdays: [2, 3, 4, 5, 6],
        notifyBeforeMinutes: 2,
        quietHoursStart: DateComponents(hour: 22, minute: 0),
        quietHoursEnd: DateComponents(hour: 7, minute: 0),
        suppressDuringFocusModes: ["DoNotDisturb", "Work"],
        breakRemindersEnabled: false,
        breakReminderIntervalMinutes: 60
    )
}

struct DeskProfile: Codable, Identifiable, Sendable, Equatable {
    let id: UUID
    var deskDeviceId: UUID
    var name: String
    var icon: String
    var sitHeight: Float
    var standHeight: Float
    var customPositions: [CustomPosition]
    var hotkeys: HotkeyBindings
    var autoStand: AutoStandConfig
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        deskDeviceId: UUID,
        name: String,
        icon: String = "desktopcomputer",
        sitHeight: Float = 72,
        standHeight: Float = 112,
        customPositions: [CustomPosition] = [],
        hotkeys: HotkeyBindings = .defaults,
        autoStand: AutoStandConfig = .default,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.deskDeviceId = deskDeviceId
        self.name = name
        self.icon = icon
        self.sitHeight = sitHeight
        self.standHeight = standHeight
        self.customPositions = customPositions
        self.hotkeys = hotkeys
        self.autoStand = autoStand
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
