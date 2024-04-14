//
//  TabView.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 07/04/2024.
//

import SwiftUI
import SwiftData
import SwiftOpenAI

struct FocusAssistantTabs: View {
    @Query var tasks: [UserTask]
    
    @Environment(ActiveTaskViewModel.self) var activeTaskModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var context
    
    @State private var activeTaskIDs: Set<PersistentIdentifier> = []
    
    var body: some View {
        @Bindable var activeTaskModel = activeTaskModel
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house") }
            
            TaskView()
                .tabItem { Label("Tasks", systemImage: "note.text") }
            
            BlenderChoiceView()
                .tabItem { Label("Task Blender", systemImage: "tornado") }

            HelpView()
                .tabItem { Label("Help", systemImage: "questionmark") }

        }
        .onAppear {
            startBackgroundTask()
        }
        .onChange(of: activeTaskModel.isFinished) { oldValue, newValue in
            if newValue == true && !activeTaskModel.isBreak && activeTaskModel.isShowing == false {
                activeTaskModel.activeTask?.increaseCounter()
            }
        }
        .alert(activeTaskModel.alertMessage, isPresented: $activeTaskModel.isFinished) {
            if activeTaskModel.isFinished {
                if let activeTask = activeTaskModel.activeTask, !activeTaskModel.isShowing {
                    if activeTask.pomodoro {
                        if shouldStartBreak() {
                            startBreakButtons()
                        } else if activeTaskModel.isBreak {
                            startTaskButtons()
                        } else {
                            completeTaskButton()
                        }
                    } else {
                        startNewTaskButtons()
                    }
                }
            }
            
        }
    }
    
    func shouldStartBreak() -> Bool {
        return activeTaskModel.activeTask!.pomodoroCounter! < 4 && !activeTaskModel.isBreak
    }
    
    func startBreakButtons() -> some View {
       Group {
           Button("Start Break", role: .cancel) {
               activeTaskModel.isBreak = true
               activeTaskModel.startPomodoroBreak()
           }
           Button("Close", role: .destructive) {
               activeTaskModel.endTimer()
               dismiss()
           }
           completeTaskButton()
       }
   }

    @ViewBuilder
    func startTaskButtons() -> some View {
       Group {
           Button("Start Task", role: .cancel) {
               activeTaskModel.isBreak = false
               activeTaskModel.setActiveTask(activeTaskModel.activeTask!)
               activeTaskModel.startTimer()
           }
           Button("Close", role: .destructive) {
               activeTaskModel.endTimer()
               dismiss()
           }
       }
   }

    @ViewBuilder
    func completeTaskButton() -> some View {
       Button("Complete task", role: .destructive) {
           activeTaskModel.endTimer()
           activeTaskModel.activeTask!.isCompleted = true
           updateTask(activeTaskModel.activeTask!)
           UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [activeTaskModel.activeTask!.id.entityName])
           activeTaskModel.activeTask = nil
           dismiss()
       }
   }

    @ViewBuilder
    func startNewTaskButtons() -> some View {
       Group {
           Button("Start New", role: .cancel) {
               activeTaskModel.endTimer()
               activeTaskModel.addNewTimer = true
           }
           Button("Close", role: .destructive) {
               activeTaskModel.endTimer()
               activeTaskModel.activeTask!.isCompleted = true
               updateTask(activeTaskModel.activeTask!)
               activeTaskModel.activeTask = nil
               dismiss()
           }
       }
   }

    private func startBackgroundTask() {
        let actor = BackgroundSerialPersistenceActor(modelContainer: context.container)
        DispatchQueue.global(qos: .background).async {
            while true {
                // Sleep for 15 seconds before checking again
                Thread.sleep(forTimeInterval: 15)
                Task {
                    let count = try? await actor.fetchCount(fetchDescriptor: FetchDescriptor<UserTask>())
                    if count != 0 {
                        try? await actor.checkExpiredTasks(activeTaskIDs: activeTaskIDs)
                        if let taskToActivate = try? await actor.checkHighPriorityTasks(activeTaskIDs: activeTaskIDs) {
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
    }

    
    private func notifyUser(for task: UserTask) {
        let content = UNMutableNotificationContent()
        content.title = "High Priority Task Timer Started"
        content.body = "Your high priority task timer for \(task.name) has started."
        content.sound = UNNotificationSound.default
        content.interruptionLevel = .timeSensitive
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func updateTask(_ taskToUpdate: UserTask) {
        for var task in tasks {
            if taskToUpdate.id == task.id {
                task = taskToUpdate
            }
        }
    }
}

#Preview {
    FocusAssistantTabs()
        .modelContainer(DataController.previewContainer)
        .environment(ActiveTaskViewModel(activeTask: mockTask))
}
