import UserNotifications
import UIKit

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
                DispatchQueue.main.async {
                    self.scheduleNotifications()
                }
            } else if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
    }

    // Handle foreground notifications
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    func scheduleNotifications() {
        let center = UNUserNotificationCenter.current()

        // Remove all pending notifications to reschedule with updated days
        center.removeAllPendingNotificationRequests()

        let calendar = Calendar.current
        // Target date: March 1, 2026
        var dateComponents = DateComponents()
        dateComponents.year = 2026
        dateComponents.month = 3
        dateComponents.day = 1

        guard let targetDate = calendar.date(from: dateComponents) else { return }

        // Schedule for the next 60 occurrences (daily)
        // 60 days coverage. App needs to be opened to reschedule further.
        for i in 0..<60 {
            let daysToAdd = i
            guard let notificationDate = calendar.date(byAdding: .day, value: daysToAdd, to: Date()) else { continue }

            // Calculate days remaining from this specific notification date to target
            let components = calendar.dateComponents([.day], from: notificationDate, to: targetDate)
            guard let daysRemaining = components.day, daysRemaining >= 0 else { continue }

            let content = UNMutableNotificationContent()
            content.title = "\(daysRemaining) Dias para Pekis🤍"
            content.sound = .default

            // Trigger at 10:00 AM on that specific date
            var triggerComponents = calendar.dateComponents([.year, .month, .day], from: notificationDate)
            triggerComponents.hour = 10
            triggerComponents.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

            let request = UNNotificationRequest(
                identifier: "pekis_countdown_\(i)",
                content: content,
                trigger: trigger
            )

            center.add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error.localizedDescription)")
                }
            }
        }
    }
}
