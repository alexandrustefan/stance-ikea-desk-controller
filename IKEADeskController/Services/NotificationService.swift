import Foundation
import UserNotifications

final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    enum Category: String {
        case autoStand = "AUTO_STAND"
    }

    enum Action: String {
        case standNow = "STAND_NOW"
        case skip = "SKIP"
        case snooze = "SNOOZE"
    }

    @MainActor
    func configure(appState: AppState) {
        UNUserNotificationCenter.current().delegate = self
        registerCategories()
    }

    @MainActor
    func requestAuthorization() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
    }

    @MainActor
    func notify(title: String, body: String, category: Category? = nil) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        if let category {
            content.categoryIdentifier = category.rawValue
        }
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let actionID = response.actionIdentifier
        await MainActor.run {
            guard let appState = AppState.current else { return }
            switch Action(rawValue: actionID) {
            case .standNow:
                appState.moveToStand()
            case .skip:
                appState.autoStandService.skipCurrentTransition()
            case .snooze:
                appState.autoStandService.snooze(minutes: 5)
            case .none:
                break
            }
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    @MainActor
    private func registerCategories() {
        let standNow = UNNotificationAction(
            identifier: Action.standNow.rawValue,
            title: "Stand Now",
            options: [.foreground]
        )
        let skip = UNNotificationAction(
            identifier: Action.skip.rawValue,
            title: "Skip",
            options: []
        )
        let snooze = UNNotificationAction(
            identifier: Action.snooze.rawValue,
            title: "Snooze 5 min",
            options: []
        )
        let category = UNNotificationCategory(
            identifier: Category.autoStand.rawValue,
            actions: [standNow, snooze, skip],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}
