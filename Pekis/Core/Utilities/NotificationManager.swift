import UserNotifications
import UIKit

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            if granted {
                DispatchQueue.main.async {
                    self.scheduleNotifications(reunionDate: Couple.loadFromCache()?.reunionDate)
                }
            }
        }
    }

    // Handle foreground notifications
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    func scheduleNotifications(reunionDate: Date?) {
        guard let targetDate = reunionDate, targetDate > Date() else {
            // No upcoming reunion date — clear stale countdown notifications
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            return
        }

        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let calendar = Calendar.current

        for i in 0..<60 {
            guard let notificationDate = calendar.date(byAdding: .day, value: i, to: Date()) else { continue }

            let components = calendar.dateComponents([.day], from: notificationDate, to: targetDate)
            guard let daysRemaining = components.day, daysRemaining >= 0 else { continue }

            let content = UNMutableNotificationContent()
            content.title = "\(daysRemaining) Dias para Pekis🤍"
            content.sound = .default

            var triggerComponents = calendar.dateComponents([.year, .month, .day], from: notificationDate)
            triggerComponents.hour = 10
            triggerComponents.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
            let request = UNNotificationRequest(
                identifier: "pekis_countdown_\(i)",
                content: content,
                trigger: trigger
            )
            center.add(request, withCompletionHandler: nil)
        }
    }
}
