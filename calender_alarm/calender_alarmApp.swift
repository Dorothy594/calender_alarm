//
//  calender_alarmApp.swift
//  calender_alarm
//
//  Created by Dorothy on 26/07/2026.
//

import SwiftUI
import SwiftData

@main
struct SmartAlarmApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(AppData.modelContainer)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                BackgroundRefreshManager.shared.scheduleNextRefresh()
            }
        }
    }
}
