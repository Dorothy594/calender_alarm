import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Alarm.hour) private var alarms: [Alarm]
    @Query(sort: \LeaveDay.date) private var leaveDays: [LeaveDay]
    @State private var holidays: [Holiday] = []
    @State private var holidayError: String?

    var body: some View {
        NavigationStack {
            List {
                Section("Alarms") {
                    if alarms.isEmpty {
                        ContentUnavailableView("No alarms", systemImage: "alarm", description: Text("Add an alarm to get started."))
                    }
                    ForEach(alarms) { alarm in
                        AlarmRow(alarm: alarm, onEnabledChanged: rebuildSchedule)
                            .swipeActions {
                                Button(role: .destructive) {
                                    context.delete(alarm)
                                    rebuildSchedule()
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }

                Section("Your leave") {
                    NavigationLink {
                        LeaveDaysView()
                    } label: {
                        HStack {
                            Label("Manage leave dates", systemImage: "calendar.badge.minus")
                            Spacer()
                            Text("\(leaveDays.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("England & Wales bank holidays") {
                    if let holidayError {
                        Label(holidayError, systemImage: "wifi.exclamationmark")
                            .foregroundStyle(.secondary)
                    } else if holidays.isEmpty {
                        ProgressView("Loading holidays…")
                    } else {
                        ForEach(upcomingHolidays.prefix(4)) { holiday in
                            HStack {
                                Text(holiday.title)
                                Spacer()
                                Text(holiday.dateValue?.formatted(date: .abbreviated, time: .omitted) ?? holiday.date)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Smart Alarm")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        AddAlarmView()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .task {
                _ = await NotificationManager.shared.requestPermission()
                await loadHolidaysAndSchedule()
            }
            .refreshable { await loadHolidaysAndSchedule() }
        }
    }

    private var upcomingHolidays: [Holiday] {
        holidays.filter { ($0.dateValue ?? .distantPast) >= Calendar.uk.startOfDay(for: Date()) }
    }

    private func loadHolidaysAndSchedule() async {
        do {
            let fetched = try await HolidayService.shared.fetchHolidays()
            holidays = fetched
            holidayError = nil
            await NotificationManager.shared.rebuildSchedule(alarms: alarms, leaveDays: leaveDays, holidays: fetched)
        } catch {
            holidayError = "Couldn’t update holidays. Pull to refresh when online."
            await NotificationManager.shared.rebuildSchedule(alarms: alarms, leaveDays: leaveDays, holidays: [])
        }
    }

    private func rebuildSchedule() {
        Task { await NotificationManager.shared.rebuildSchedule(alarms: alarms, leaveDays: leaveDays, holidays: holidays) }
    }
}

private struct AlarmRow: View {
    @Bindable var alarm: Alarm
    let onEnabledChanged: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "alarm")
                .font(.title2)
                .foregroundStyle(alarm.isEnabled ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
            VStack(alignment: .leading, spacing: 3) {
                Text(alarm.timeString)
                    .font(.title2.monospacedDigit())
                Text(alarm.repeatDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if alarm.skipHoliday || alarm.skipLeave {
                    Text([alarm.skipHoliday ? "Bank holidays" : nil, alarm.skipLeave ? "Leave" : nil].compactMap { $0 }.joined(separator: " + ") + " skipped")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Toggle("Enabled", isOn: $alarm.isEnabled)
                .labelsHidden()
                .onChange(of: alarm.isEnabled) { _, _ in onEnabledChanged() }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Alarm.self, LeaveDay.self], inMemory: true)
}
