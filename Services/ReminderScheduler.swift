import Foundation
import UserNotifications

/// Schedules "come back and log something" local notifications.
///
/// The reminders are re-scheduled every time the app becomes active, always dated a few days out.
/// Because opening the app pushes them further into the future, they only ever fire when the user
/// has been away for that many days.
enum ReminderScheduler {

    private struct Reminder {
        let id: String
        let days: Int
        let body: String
    }

    private static let reminders = [
        Reminder(id: "dietbuddy.reminder.checkin.3d",
                 days: 3,
                 body: "It's been a few days — log your weight or a meal to stay on track."),
        Reminder(id: "dietbuddy.reminder.checkin.7d",
                 days: 7,
                 body: "Still here for you. Take a moment to log today's food or a weigh-in.")
    ]

    private static var identifiers: [String] { reminders.map(\.id) }

    /// The current notification authorization status.
    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    /// Requests notification authorization. Returns whether it was granted.
    @discardableResult
    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    /// Handles the settings toggle: request permission and schedule when on, cancel when off.
    static func setEnabled(_ enabled: Bool) async {
        guard enabled else {
            cancelAll()
            return
        }
        if await requestAuthorization() {
            await scheduleInactivityReminders()
        }
    }

    /// Call when the app becomes active to push the inactivity reminders further out.
    static func appBecameActive(remindersEnabled: Bool) async {
        guard remindersEnabled else { return }
        let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        guard status == .authorized || status == .provisional else { return }
        await scheduleInactivityReminders()
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private static func scheduleInactivityReminders() async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: identifiers)

        for reminder in reminders {
            let content = UNMutableNotificationContent()
            content.title = "DietBuddy check-in"
            content.body = reminder.body
            content.sound = .default

            let interval = TimeInterval(reminder.days * 24 * 60 * 60)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            let request = UNNotificationRequest(identifier: reminder.id, content: content, trigger: trigger)
            try? await center.add(request)
        }
    }
}
