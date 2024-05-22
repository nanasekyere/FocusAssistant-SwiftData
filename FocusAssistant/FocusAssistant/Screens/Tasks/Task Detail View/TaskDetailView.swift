//
//  TaskDetailView.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 07/04/2024.
//

import SwiftUI

struct TaskDetailView: View {
    // Environment variables
    @Environment(\.dismiss) private var dismiss
    @Environment(ActiveTaskViewModel.self) var activeVM

    // State variables
    @Bindable var task: UserTask
    @State var vm = TaskDetailViewModel()
    @State private var isAnimated = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background color
                Color.BG
                    .ignoresSafeArea()

                VStack {
                    // Task image
                    Image(systemName: task.imageURL ?? "note.text")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150, height: 75)
                        .padding()

                    // Task name
                    Text(task.name)
                        .font(.title2)
                        .fontWeight(.semibold)

                    // Task details
                    Text(task.details ?? "")
                        .multilineTextAlignment(.center)
                        .font(.body)
                        .padding()

                    // Task information (priority, times completed, duration, start time)
                    HStack(alignment: .top, spacing: 25) {
                        // Display task info based on priority or pomodoro completion
                        if task.pomodoro {
                            TaskInfo(title: "Priority", value: String(describing: task.priority))
                            TaskInfo(title: "Times Completed", value: String(task.pomodoroCounter!))
                        } else {
                            TaskInfo(title: "Duration", value: task.duration.timeString())
                            TaskInfo(title: "Priority", value: String(describing: task.priority))
                            TaskInfo(title: "Start Time", value: task.startTime!.formatted(date: .abbreviated, time: .shortened))
                        }
                    }
                    .padding()
                    Spacer()

                    // Button to refresh completed task or start task
                    if task.blendedTask != nil  && task.isCompleted == true {
                        Button("Refresh Task") {
                            task.isCompleted = false
                            task.pomodoroCounter = 0
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        // Button to start task or display active task timer
                        if let activeTask = activeVM.activeTask, activeTask.identity == task.identity {
                            Button(activeVM.timerStringValue) {}
                                .buttonStyle(.borderedProminent)
                        } else {
                            Button("Start Task") {
                                // Determine whether to start task based on priority and timing
                                if activeVM.activeTask == nil {
                                    if task.pomodoro {
                                        vm.taskToActivate = task
                                    } else {
                                        switch task.priority {
                                            case .low:
                                                vm.taskToActivate = task
                                            case .medium:
                                                if abs(task.startTime!.timeIntervalSince(Date.now)) > 600 {
                                                    withAnimation(.easeInOut(duration: 2)) {
                                                        vm.selectedTask = task
                                                        vm.isDisplayingContext = true
                                                    }
                                                } else {
                                                    vm.taskToActivate = task
                                                }
                                            case .high:
                                                withAnimation(.easeInOut) {
                                                    vm.selectedTask = task
                                                    vm.isDisplayingContext = true
                                                }
                                        }
                                    }
                                } else {
                                    vm.showAlert = true
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .popover(isPresented: $vm.isDisplayingContext, arrowEdge: .bottom) {
                                // Popover to display context for high-priority tasks
                                VStack {
                                    Text(vm.taskStartContext ?? "")
                                        .lineLimit(nil)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 10)
                                }
                                .frame(maxWidth: .infinity, minHeight: 80)
                                .presentationCompactAdaptation((.popover))
                            }
                        }
                    }
                }
                .padding(.top, 30)
            }
            .toolbar {
                // Toolbar item to dismiss view
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: { Text("Back") }
                }
            }
        }

        // Full screen cover to display active task view when a task is activated
        .fullScreenCover(item: $vm.taskToActivate) { task in
            ActiveTaskView(task: task)
        }

        // Alert to display when attempting to start a task while another task is active
        .alert("Can't start task, there is already an active task", isPresented: $vm.showAlert) {
            Button("OK", role: .cancel) {}
        }
    }
}

// Subview to display task information (title and value)
struct TaskInfo: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 5) {
            // Title of the task information
            Text(title)
                .bold()
                .font(.caption)
            // Value of the task information
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .italic()
        }
    }
}

#Preview {
    TaskDetailView(task: mockTask)
}
