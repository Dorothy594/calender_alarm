import SwiftUI
import SwiftData

struct AddAlarmView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var alarms: [Alarm]
    @Query private var leaveDays: [LeaveDay]
    @State private var time = Date()
    @State private var selectedWeekdays = Set([2, 3, 4, 5, 6])
    @State private var skipHoliday = true
    @State private var skipLeave = true

    var body: some View {
        Form {
            DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)

            Section("Repeat") {
                ForEach(1...7, id: \.self) { weekday in
                    Toggle(Calendar.current.weekdaySymbols[weekday - 1], isOn: Binding(
                        get: { selectedWeekdays.contains(weekday) },
                        set: { selected in
                            if selected { selectedWeekdays.insert(weekday) }
                            else { selectedWeekdays.remove(weekday) }
                        }
                    ))
                }
            }

            Section("Skip the alarm on") {
                Toggle("England & Wales bank holidays", isOn: $skipHoliday)
                Toggle("My leave dates", isOn: $skipLeave)
            }
        }
        .navigationTitle("New Alarm")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(selectedWeekdays.isEmpty)
            }
        }
    }

    private func save() {
        let hour = Calendar.current.component(.hour, from: time)
        let minute = Calendar.current.component(.minute, from: time)
        let alarm = Alarm(hour: hour, minute: minute, repeatDays: selectedWeekdays.sorted(), skipHoliday: skipHoliday, skipLeave: skipLeave)
        context.insert(alarm)
        Task {
            let holidays = (try? await HolidayService.shared.fetchHolidays()) ?? []
            await NotificationManager.shared.rebuildSchedule(alarms: alarms + [alarm], leaveDays: leaveDays, holidays: holidays)
        }
        dismiss()
    }
}
