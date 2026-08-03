import Foundation
import SwiftData

@Model
final class Alarm {
    var id: String
    var hour: Int
    var minute: Int
    var repeatDays: [Int]
    var skipHoliday: Bool
    var skipLeave: Bool
    var isEnabled: Bool

    init(
        hour: Int,
        minute: Int,
        repeatDays: [Int] = [2, 3, 4, 5, 6],
        skipHoliday: Bool = true,
        skipLeave: Bool = true,
        isEnabled: Bool = true
    ) {
        self.id = UUID().uuidString
        self.hour = hour
        self.minute = minute
        self.repeatDays = repeatDays
        self.skipHoliday = skipHoliday
        self.skipLeave = skipLeave
        self.isEnabled = isEnabled
    }

    var timeString: String {
        DateComponentsFormatter.shortTime(hour: hour, minute: minute)
    }

    var repeatDescription: String {
        repeatDays.sorted().map { Calendar.current.shortWeekdaySymbols[$0 - 1] }.joined(separator: ", ")
    }
}

extension DateComponentsFormatter {
    static func shortTime(hour: Int, minute: Int) -> String {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components)?
            .formatted(date: .omitted, time: .shortened) ?? String(format: "%02d:%02d", hour, minute)
    }
}
