//
//  FocusAssistantApp.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 07/04/2024.
//

import SwiftUI
import SwiftData
import BackgroundTasks

@main
struct FocusAssistantApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserTask.self,
            BlendedTask.self
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
    @State private var activeTaskIDs: Set<PersistentIdentifier> = []
    @AppStorage("isOnboarding") var isOnboarding: Bool = true

    init() {
        registerBackgroundTasks()
    }

    var body: some Scene {
        WindowGroup {
            if isOnboarding {
                OnboardingView()
                    .environment(\.colorScheme, .dark)
            } else {
                FocusAssistantTabs()
                    .environment(activeTaskModel)
                    .environment(\.scenePhase, phase)
                    .environment(\.colorScheme, .dark)
                    .onReceive(activeTaskModel.timer) { _ in
                        if activeTaskModel.isStarted && !activeTaskModel.isShowing {
                            activeTaskModel.updateTimer()
                        }
                    }
            }
        }
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
            if newValue == .background {
                scheduleBackgroundTask()
            }

            if newValue == .active || newValue == .inactive {
                startBackgroundTask()
            }
        }
    }
    
    private func startBackgroundTask() {
        let actor = BackgroundSerialPersistenceActor(modelContainer: sharedModelContainer)
        DispatchQueue.global(qos: .background).async {
            while true {
                // Sleep for 15 seconds before checking again
                Thread.sleep(forTimeInterval: 15)
                Task {
                    let count = try? await actor.fetchCount(fetchDescriptor: FetchDescriptor<UserTask>())
                    if count != 0 {
                        if let taskToActivate = try? await actor.checkHighPriorityTasks(activeTaskIDs: activeTaskIDs) {
                            // Set the task as the active task
                            activeTaskModel.setActiveTask(taskToActivate)
                            activeTaskIDs.insert(taskToActivate.id)
                            // Start the timer
                            activeTaskModel.startTimer()
                            // Notify the user
                            notifyUser(for: taskToActivate)
                        }
                        try? await actor.checkExpiredTasks(activeTaskIDs: activeTaskIDs)
                    }
                }


            }
        }
    }


    private func notifyUser(for task: UserTask) {
        let content = UNMutableNotificationContent()
        content.title = "High Priority Task Timer Started"
        content.body = "Your high priority task timer for \(task.name) has started."
        content.sound = UNNotificationSound.default
        content.interruptionLevel = .timeSensitive
        let request = UNNotificationRequest(identifier: task.identity.uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.FocusAssistant.refreshTasks", using: nil) { task in
            // Downcast the parameter to an appropriate task type
            guard let task = task as? BGAppRefreshTask else { return }
            self.handleAppRefresh(task: task)
        }
    }

    private func handleAppRefresh(task: BGAppRefreshTask) {
        // Schedule a new refresh task
        scheduleBackgroundTask()

        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        // Your existing background task logic
        let actor = BackgroundSerialPersistenceActor(modelContainer: sharedModelContainer)
        Task {
            print("Background Task started")
            let count = try? await actor.fetchCount(fetchDescriptor: FetchDescriptor<UserTask>())
            if count != 0 {
                try? await actor.checkExpiredTasks(activeTaskIDs: activeTaskIDs)
                if let taskToActivate = try? await actor.checkHighPriorityTasks(activeTaskIDs: activeTaskIDs) {
                    DispatchQueue.main.async {
                        // Set the task as the active task
                        activeTaskModel.setActiveTask(taskToActivate)
                        activeTaskIDs.insert(taskToActivate.id)
                        // Start the timer
                        activeTaskModel.startTimer()
                        // Notify the user
                        notifyUser(for: taskToActivate)
                    }
                }
            }
        }
    }

    private func scheduleBackgroundTask() {
        let request = BGAppRefreshTaskRequest(identifier: "com.FocusAssistant.refreshTasks")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }


}
