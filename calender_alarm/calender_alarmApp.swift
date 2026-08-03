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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(
            for:[
                Alarm.self,
                LeaveDay.self
            ]
        )
    }
}
