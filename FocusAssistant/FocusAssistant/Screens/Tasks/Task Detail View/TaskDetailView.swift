//
//  TaskDetailView.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 07/04/2024.
//

import SwiftUI

struct TaskDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ActiveTaskViewModel.self) var activeVM

    @Bindable var task: UserTask
    @State var vm = TaskDetailViewModel()
    @State private var isAnimated = false
    
    var body: some View {
        NavigationStack{
            ZStack {
                Color.BG
                    .ignoresSafeArea()
                
                VStack {
                    Image(systemName: task.imageURL ?? "note.text")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150, height: 75)
                        .padding()
                    
                    Text(task.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(task.details ?? "")
                        .multilineTextAlignment(.center)
                        .font(.body)
                        .padding()
                    
                    HStack(alignment: .top, spacing: 25) {
                        
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
                    if task.blendedTask != nil  && task.isCompleted == true {
                        Button("Refresh Task") {
                            task.isCompleted = false
                            task.pomodoroCounter = 0
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        if let activeTask = activeVM.activeTask, activeTask.identity == task.identity {
                            Button(activeVM.timerStringValue) {}
                                .buttonStyle(.borderedProminent)
                        } else {
                            Button("Start Task") {
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
                                                        vm.isDisplayingContext = true
                                                    }
                                                } else {
                                                    vm.taskToActivate = task
                                                }
                                            case .high:
                                                withAnimation(.easeInOut) {
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
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: { Text("Back") }
                }
                
            }
            
        }
        
        .fullScreenCover(item: $vm.taskToActivate) { task in
            ActiveTaskView(task: task)
        }
        .alert("Can't start task, there is already an active task", isPresented: $vm.showAlert) {
            Button("OK", role: .cancel) {

            }
        }
    }
}

struct TaskInfo: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 5) {
            Text(title)
                .bold()
                .font(.caption)
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
