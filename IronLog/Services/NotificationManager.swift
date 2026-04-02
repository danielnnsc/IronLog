import Foundation
import UserNotifications

/// Schedules and cancels local notifications for missed training days.
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {

    static let shared = NotificationManager()

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    // Show notification banners + play sound even when app is in the foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // MARK: - Permission

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    // MARK: - Schedule Reminder for a Session

    /// Schedules a notification that fires at `reminderHour` on the session's designated date,
    /// reminding the user they have a session scheduled.
    func scheduleReminder(for session: QueuedSession, atHour reminderHour: Int = 8) {
        guard let date = session.designatedDate else { return }

        let center = UNUserNotificationCenter.current()
        let identifier = "session-\(session.id.uuidString)"

        let content = UNMutableNotificationContent()
        content.title = "Gym Day: \(session.displayName)"
        content.body = "Your session is queued and ready. Tap to start."
        content.sound = .default

        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = reminderHour
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        center.add(request)
    }

    /// Schedules an overdue notification (fires the morning after a missed session).
    func scheduleOverdueReminder(for session: QueuedSession, atHour reminderHour: Int = 8) {
        guard let date = session.designatedDate else { return }
        guard let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: date) else { return }

        let center = UNUserNotificationCenter.current()
        let identifier = "overdue-\(session.id.uuidString)"

        let content = UNMutableNotificationContent()
        content.title = "Missed Session: \(session.displayName)"
        content.body = "No worries — it's still queued and ready when you are."
        content.sound = .default

        var components = Calendar.current.dateComponents([.year, .month, .day], from: nextDay)
        components.hour = reminderHour
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        center.add(request)
    }

    // MARK: - Cancel

    func cancelReminder(for session: QueuedSession) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [
                "session-\(session.id.uuidString)",
                "overdue-\(session.id.uuidString)"
            ]
        )
    }

    func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Rest Timer Notification

    func scheduleRestComplete(in seconds: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Rest Complete"
        content.body = "Time for your next set!"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(max(1, seconds)), repeats: false)
        let request = UNNotificationRequest(identifier: "rest_complete", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelRestComplete() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["rest_complete"])
    }

    // MARK: - Reschedule All

    /// Cancels all pending reminders and reschedules for the current queue.
    func rescheduleAll(sessions: [QueuedSession], reminderHour: Int = 8) {
        cancelAllReminders()
        for session in sessions where session.status == .queued {
            scheduleReminder(for: session, atHour: reminderHour)
        }
    }
}
