//
//  FocusAssistantTabs.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 07/04/2024.
//

import SwiftUI
import SwiftData
import SwiftOpenAI

struct FocusAssistantTabs: View {
    // Query for fetching user tasks
    @Query var tasks: [UserTask]

    // Environment objects for managing active task, dismissing views, and accessing model context
    @Environment(ActiveTaskViewModel.self) var activeTaskModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var context

    var body: some View {
        // Binding for active task model
        @Bindable var activeTaskModel = activeTaskModel

        // TabView containing different views for the app
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house") }

            TaskView()
                .tabItem { Label("Tasks", systemImage: "note.text") }

            BlenderChoiceView()
                .tabItem { Label("Task Blender", systemImage: "tornado") }

            SettingsView()
                .tabItem { Label("Help & Settings", systemImage: "questionmark") }

        }
        // Perform actions when the active task's state changes
        .onChange(of: activeTaskModel.isFinished) { oldValue, newValue in
            if newValue == true && !activeTaskModel.isBreak && activeTaskModel.isShowing == false {
                activeTaskModel.activeTask?.increaseCounter()
            }
        }
        // Present alert based on the active task's state
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

    // Function to determine if a break should be started
    func shouldStartBreak() -> Bool {
        return activeTaskModel.activeTask!.pomodoroCounter! < 4 && !activeTaskModel.isBreak
    }

    // Function to present buttons for starting a break
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

    // Function to present buttons for starting a task
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

    // Function to present button for completing a task
    @ViewBuilder
    func completeTaskButton() -> some View {
       Button("Complete task", role: .destructive) {
           activeTaskModel.activeTask!.completeTask()
           updateTask(activeTaskModel.activeTask!)
           UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [activeTaskModel.activeTask!.identity.uuidString])
           activeTaskModel.activeTask = nil
           activeTaskModel.endTimer()
           dismiss()
       }
   }

    // Function to present buttons for starting a new task
    @ViewBuilder
    func startNewTaskButtons() -> some View {
       Group {
           Button("Start New", role: .cancel) {
               activeTaskModel.endTimer()
               activeTaskModel.addNewTimer = true
           }
           Button("Close", role: .destructive) {
               activeTaskModel.endTimer()
               activeTaskModel.activeTask!.completeTask()
               updateTask(activeTaskModel.activeTask!)
               activeTaskModel.activeTask = nil
               dismiss()
           }
       }
   }

    // Function to update a task in the database
    private func updateTask(_ taskToUpdate: UserTask) {
        for var task in tasks {
            if taskToUpdate.id == task.id {
                task = taskToUpdate
            }
        }
    }
}

// Preview of the FocusAssistantTabs view
#Preview {
    FocusAssistantTabs()
        .modelContainer(DataController.previewContainer)
        .environment(ActiveTaskViewModel(activeTask: mockTask))
}
