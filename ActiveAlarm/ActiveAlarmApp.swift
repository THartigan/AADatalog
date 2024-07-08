//
//  ActiveAlarmApp.swift
//  ActiveAlarm
//
//  Created by Thomas Hartigan on 07/06/2024.
//

import SwiftUI
import SwiftData

@main
struct ActiveAlarmApp: App {
    @StateObject var watchConnector = WatchConnector()
    
    var body: some Scene {
        WindowGroup {
            ContentView(watchConnector: watchConnector)
                .modelContainer(for: WorkoutDatas.self)
        }
    }
}
