import Foundation
import SwiftData

@Model
final class LeaveDay {
    var id: String
    var date: Date
    var note: String

    init(date: Date, note: String = "Annual leave") {
        self.id = UUID().uuidString
        self.date = Calendar.uk.startOfDay(for: date)
        self.note = note
    }
}

extension Calendar {
    static var uk: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London") ?? .current
        return calendar
    }()
}
