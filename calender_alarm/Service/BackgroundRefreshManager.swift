import BackgroundTasks
import SwiftData
import UIKit

enum AppData {
    static let modelContainer: ModelContainer = {
        do {
            return try ModelContainer(for: Alarm.self, LeaveDay.self)
        } catch {
            fatalError("Could not create the app data store: \(error)")
        }
    }()
}

final class BackgroundRefreshManager {
    static let shared = BackgroundRefreshManager()
    static let taskIdentifier = "com.dorothyma.calender-alarm.refresh"
    private init() {}

    func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.taskIdentifier, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            self.handle(refreshTask)
        }
    }

    /// The system decides the exact run time; submit a new request after every launch and run.
    func scheduleNextRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 12 * 60 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    private func handle(_ task: BGAppRefreshTask) {
        scheduleNextRefresh()
        let work = Task { @MainActor in
            let context = ModelContext(AppData.modelContainer)
            do {
                let alarms = try context.fetch(FetchDescriptor<Alarm>())
                let leaveDays = try context.fetch(FetchDescriptor<LeaveDay>())
                let holidays = (try? await HolidayService.shared.fetchHolidays()) ?? HolidayService.shared.cachedHolidays()
                await NotificationManager.shared.rebuildSchedule(alarms: alarms, leaveDays: leaveDays, holidays: holidays)
                task.setTaskCompleted(success: !Task.isCancelled)
            } catch {
                task.setTaskCompleted(success: false)
            }
        }
        task.expirationHandler = { work.cancel() }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        BackgroundRefreshManager.shared.register()
        BackgroundRefreshManager.shared.scheduleNextRefresh()
        return true
    }
}
