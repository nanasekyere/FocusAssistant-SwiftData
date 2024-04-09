//
//  TaskDetailView.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 07/04/2024.
//

import SwiftUI

struct TaskDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var task: UserTask
    @State var viewModel = TaskDetailViewModel()
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
                    Button("Start Task") {
                        if task.pomodoro {
                            viewModel.taskToActivate = task
                        } else {
                            switch task.priority {
                            case .low:
                                viewModel.taskToActivate = task
                            case .medium:
                                if abs(task.startTime!.timeIntervalSince(Date.now)) > 600 {
                                    withAnimation(.easeInOut(duration: 2)) {
                                        viewModel.isDisplayingContext = true
                                    }
                                } else {
                                    viewModel.taskToActivate = task
                                }
                            case .high:
                                withAnimation(.easeInOut) {
                                    viewModel.isDisplayingContext = true
                                }
                            }
                        }
                        
                        
                        
                    }
                    .buttonStyle(.borderedProminent)
                    .popover(isPresented: $viewModel.isDisplayingContext, arrowEdge: .bottom) {
                        VStack {
                            Text(viewModel.taskStartContext ?? "")
                                .lineLimit(nil)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 10)
                        }
                        .frame(maxWidth: .infinity, minHeight: 80)
                        .presentationCompactAdaptation((.popover))
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
        
        .fullScreenCover(item: $viewModel.taskToActivate) { task in
            ActiveTaskView(task: task)
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
