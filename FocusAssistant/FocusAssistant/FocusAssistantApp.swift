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
    // Shared model container for data persistence
    var sharedModelContainer: ModelContainer = {
        // Define the schema and configuration for data persistence
        let schema = Schema([
            UserTask.self,
            BlendedTask.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        // Initialize the shared model container with the schema and configuration
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // ViewModel for the active task
    @State private var activeTaskModel: ActiveTaskViewModel = .init()

    @Environment(\.scenePhase) var phase // Tracks the scene phase (active, background, inactive)
    @State var lastActiveTimeStamp: Date? // Timestamp of the last active phase
    @State private var activeTaskIDs: Set<UUID> = [] // Set of active task IDs
    @State var taskStartedInBG = false // Flag to check if a task started in the background
    @State private var runBGchecks = true // Flag to control background task checks

    @AppStorage("isOnboarding") var isOnboarding: Bool = true // Flag for onboarding state

    // The body property defines the app's user interface and behavior.
    var body: some Scene {
        // WindowGroup represents the main window of the app.
        WindowGroup {
            // Conditionally display either the onboarding view or the main app interface based on the onboarding state.
            if isOnboarding {
                // Show onboarding view if in onboarding state
                OnboardingView()
                    .environment(\.colorScheme, .dark)
            } else {
                // Show main app interface if not in onboarding state
                FocusAssistantTabs()
                    .environment(activeTaskModel)
                    .environment(\.scenePhase, phase)
                    .environment(\.colorScheme, .dark)
                    .onReceive(activeTaskModel.timer) { _ in
                        // Update timer if task is started and not showing
                        if activeTaskModel.isStarted && !activeTaskModel.isShowing {
                            activeTaskModel.updateTimer()
                        }
                    }
                    .onAppear {
                        runBGchecks = true
                        startBackgroundTask() // Start background task checks when the app appears
                    }
                    .alert("Task Started Automatically", isPresented: $taskStartedInBG, presenting: activeTaskModel.activeTask) { task in
                        Button("Ok") {}
                    } message: { task in
                        // Notify the user about the automatic task start
                        Text("\(task.name) started automatically as it is high priority")
                    }
            }
        }
        // Provide the shared model container to the environment
        .modelContainer(sharedModelContainer)
        // Handle changes in scene phase
        .onChange(of: phase) { oldValue, newValue in
            if activeTaskModel.isStarted {
                if newValue == .background {
                    lastActiveTimeStamp = Date() // Save timestamp when app goes to background
                }

                if newValue == .active {
                    // Calculate time difference and update the task timer when app becomes active
                    if let timeStamp = lastActiveTimeStamp {
                        let currentTimeStampDiff = Date().timeIntervalSince(timeStamp)
                        if activeTaskModel.totalSeconds - Int(currentTimeStampDiff) <= 0 {
                            // If the remaining time is zero or negative, mark the task as finished
                            activeTaskModel.isStarted = false
                            activeTaskModel.totalSeconds = 0
                            activeTaskModel.isFinished = true
                        } else {
                            // Otherwise, update the remaining time
                            activeTaskModel.totalSeconds -= Int(currentTimeStampDiff)
                        }
                    }
                }
            }

            if newValue == .active || newValue == .inactive {
                // Handle high priority tasks when app is active or inactive
                let actor = BackgroundSerialPersistenceActor(modelContainer: sharedModelContainer)
                Task {
                    if let taskToActivate = try? await actor.startHighPriorityTasks(activeTaskIDs), activeTaskModel.activeTask == nil {
                        // If there is a high-priority task to activate and no active task, start it
                        activeTaskIDs.insert(taskToActivate.identity)
                        activeTaskModel.startInProgress(taskToActivate)
                        taskStartedInBG = true
                    }
                }
                runBGchecks = true
            }

            if newValue == .background {
                runBGchecks = false // Stop background checks when app goes to background
            }
        }
    }

    // Function to start a background task to check for high-priority tasks
    private func startBackgroundTask() {
        let actor = BackgroundSerialPersistenceActor(modelContainer: sharedModelContainer)
        DispatchQueue.global(qos: .background).async {
            while runBGchecks {
                // Sleep for 15 seconds before checking again
                Thread.sleep(forTimeInterval: 15)
                Task {
                    let count = try? await actor.fetchCount(fetchDescriptor: FetchDescriptor<UserTask>())
                    if count != 0 {
                        if let taskToActivate = try? await actor.checkHighPriorityTasks(activeTaskIDs) {
                            // Set the task as the active task
                            activeTaskModel.setActiveTask(taskToActivate)
                            activeTaskIDs.insert(taskToActivate.identity)
                            // Start the timer
                            activeTaskModel.startTimer()
                            // Notify the user
                            notifyUser(for: taskToActivate)
                        }
                        try? await actor.checkExpiredTasks(activeTaskIDs: activeTaskIDs, activeModel: activeTaskModel)
                    }
                }
            }
        }
    }

    // Function to notify the user about a high-priority task
    private func notifyUser(for task: UserTask) {
        let content = UNMutableNotificationContent()
        content.title = "High Priority Task Timer Started"
        content.body = "Your high priority task timer for \(task.name) has started."
        content.sound = UNNotificationSound.default
        content.interruptionLevel = .timeSensitive
        let request = UNNotificationRequest(identifier: task.identity.uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
