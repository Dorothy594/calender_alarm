import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private let prefix = "smart-alarm."
    private init() {}

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    /// Local notifications cannot evaluate holiday rules at delivery time. Instead, this creates
    /// dated notifications for the next 28 days, omitting dates that match the user's rules.
    func rebuildSchedule(alarms: [Alarm], leaveDays: [LeaveDay], holidays: [Holiday]) async {
        let center = UNUserNotificationCenter.current()
        let existing = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(withIdentifiers: existing.map(\.identifier).filter { $0.hasPrefix(prefix) })

        let holidayDates = Set(holidays.compactMap(\.dateValue).map { Calendar.uk.startOfDay(for: $0) })
        let calendar = Calendar.uk
        let today = calendar.startOfDay(for: Date())
        var requests: [(date: Date, request: UNNotificationRequest)] = []

        for offset in 0..<28 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            let dayStart = calendar.startOfDay(for: day)
            let weekday = calendar.component(.weekday, from: day)

            for alarm in alarms where alarm.isEnabled && alarm.repeatDays.contains(weekday) {
                if alarm.skipHoliday && holidayDates.contains(dayStart) { continue }
                if alarm.skipLeave && leaveDays.contains(where: { $0.contains(dayStart) }) { continue }
                guard let fireDate = calendar.date(bySettingHour: alarm.hour, minute: alarm.minute, second: 0, of: day), fireDate > Date() else { continue }

                let content = UNMutableNotificationContent()
                content.title = "Smart Alarm"
                content.body = "Time to get up"
                content.sound = .default
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate),
                    repeats: false
                )
                let identifier = "\(prefix)\(alarm.id).\(Int(fireDate.timeIntervalSince1970))"
                requests.append((fireDate, UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)))
            }
        }

        // iOS permits at most 64 pending local notifications.
        for item in requests.sorted(by: { $0.date < $1.date }).prefix(64) {
            try? await center.add(item.request)
        }
    }
}
