import Foundation
import SwiftData

@Model
final class LeaveDay {
    var id: String
    /// Start of the leave period, inclusive. Kept as `date` for lightweight migration from v1.
    var date: Date
    /// End of the leave period, inclusive.
    var endDate: Date?
    var note: String

    init(date: Date, endDate: Date? = nil, note: String = "Annual leave") {
        self.id = UUID().uuidString
        self.date = Calendar.uk.startOfDay(for: date)
        self.endDate = Calendar.uk.startOfDay(for: endDate ?? date)
        self.note = note
    }

    func contains(_ target: Date) -> Bool {
        let day = Calendar.uk.startOfDay(for: target)
        return day >= date && day <= lastDate
    }

    var lastDate: Date { endDate ?? date }
}

extension Calendar {
    static var uk: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London") ?? .current
        return calendar
    }()
}
