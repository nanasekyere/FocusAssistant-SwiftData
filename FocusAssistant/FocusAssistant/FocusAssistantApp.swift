//
//  FocusAssistantApp.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 07/04/2024.
//

import SwiftUI
import SwiftData

@main
struct FocusAssistantApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            UserTask.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    @State private var activeTaskModel: ActiveTaskViewModel = .init()
    
    @Environment(\.scenePhase) var phase
    @State var lastActiveTimeStamp: Date?

    var body: some Scene {
        WindowGroup {
            FocusAssistantTabs()
        }
        .environmentObject(activeTaskModel)
        .modelContainer(sharedModelContainer)
        .onChange(of: phase) { oldValue, newValue in
            if activeTaskModel.isStarted {
                if newValue == .background {
                    lastActiveTimeStamp = Date()
                }
                
                if newValue == .active {
                    if let timeStamp = lastActiveTimeStamp {
                        let currentTimeStampDiff = Date().timeIntervalSince(timeStamp)
                        if activeTaskModel.totalSeconds - Int(currentTimeStampDiff) <= 0 {
                            activeTaskModel.isStarted = false
                            activeTaskModel.totalSeconds = 0
                            activeTaskModel.isFinished = true
                        } else { activeTaskModel.totalSeconds -= Int(currentTimeStampDiff) }
                    }
                }
            }
        }
    }
}
