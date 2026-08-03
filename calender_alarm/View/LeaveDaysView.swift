import SwiftUI
import SwiftData

struct LeaveDaysView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \LeaveDay.date) private var leaveDays: [LeaveDay]
    @Query private var alarms: [Alarm]
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var note = "Annual leave"

    var body: some View {
        List {
            Section("Add leave period") {
                DatePicker("First day", selection: $startDate, displayedComponents: .date)
                DatePicker("Last day", selection: $endDate, in: startDate..., displayedComponents: .date)
                TextField("Label", text: $note)
                Button("Add leave period", action: addLeaveDay)
                    .disabled(note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            Section("Scheduled leave") {
                if leaveDays.isEmpty {
                    Text("No leave dates yet.").foregroundStyle(.secondary)
                }
                ForEach(leaveDays) { leaveDay in
                    NavigationLink {
                        EditLeaveView(leaveDay: leaveDay)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(leaveDay.date.formatted(date: .long, time: .omitted) + " – " + leaveDay.lastDate.formatted(date: .long, time: .omitted))
                            Text(leaveDay.note).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteLeaveDays)
            }
        }
        .navigationTitle("My Leave")
    }

    private func addLeaveDay() {
        let leaveDay = LeaveDay(date: startDate, endDate: endDate, note: note.trimmingCharacters(in: .whitespacesAndNewlines))
        context.insert(leaveDay)
        note = "Annual leave"
        rebuildSchedule(with: leaveDays + [leaveDay])
    }

    private func deleteLeaveDays(at offsets: IndexSet) {
        let remainingDays = leaveDays.enumerated().compactMap { offsets.contains($0.offset) ? nil : $0.element }
        for offset in offsets { context.delete(leaveDays[offset]) }
        rebuildSchedule(with: remainingDays)
    }

    private func rebuildSchedule(with days: [LeaveDay]) {
        Task {
            let holidays = (try? await HolidayService.shared.fetchHolidays()) ?? []
            await NotificationManager.shared.rebuildSchedule(alarms: alarms, leaveDays: days, holidays: holidays)
        }
    }
}

struct EditLeaveView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var alarms: [Alarm]
    @Query private var leaveDays: [LeaveDay]
    let leaveDay: LeaveDay
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var note: String

    init(leaveDay: LeaveDay) {
        self.leaveDay = leaveDay
        _startDate = State(initialValue: leaveDay.date)
        _endDate = State(initialValue: leaveDay.lastDate)
        _note = State(initialValue: leaveDay.note)
    }

    var body: some View {
        Form {
            DatePicker("First day", selection: $startDate, displayedComponents: .date)
            DatePicker("Last day", selection: $endDate, in: startDate..., displayedComponents: .date)
            TextField("Label", text: $note)
        }
        .navigationTitle("Edit Leave")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
                    .disabled(note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func save() {
        leaveDay.date = Calendar.uk.startOfDay(for: startDate)
        leaveDay.endDate = Calendar.uk.startOfDay(for: endDate)
        leaveDay.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        try? context.save()
        Task {
            let holidays = (try? await HolidayService.shared.fetchHolidays()) ?? HolidayService.shared.cachedHolidays()
            await NotificationManager.shared.rebuildSchedule(alarms: alarms, leaveDays: leaveDays, holidays: holidays)
        }
        dismiss()
    }
}
