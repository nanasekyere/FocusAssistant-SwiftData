//
//  BlendedTaskDetailView.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 06/04/2024.
//

import SwiftUI
import SwiftData

struct BlendedTaskDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query var bTasks: [BlendedTask]
    
    @State private var isAnimated = false

    @State private var taskToActivate: UserTask?
    @Bindable var blendedTask: BlendedTask
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.BG.ignoresSafeArea()
                if let bTask = bTasks.first(where: {$0.id == blendedTask.id}) {
                    List {
                        ForEach(bTask.subtasks.indices, id: \.self) { i  in
                            VStack(alignment: .center) {
                                Text("Task: \(bTask.subtasks[i].name)")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                
                                ForEach(bTask.subtasks[i].details.indices, id: \.self) { j in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(bTask.subtasks[i].details[j].desc)
                                        }
                                        Spacer()
                                        
                                        Button(action: {
                                            withAnimation {
                                                print("-view OLD: \(bTask.subtasks[i].details[j].isCompleted)")
                                                bTask.subtasks[i].details[j].isCompleted.toggle()
                                                print("-view NEW: \(bTask.subtasks[i].details[j].isCompleted)")
                                            }
                                        }, label: {
                                            Image(systemName: bTask.subtasks[i].details[j].isCompleted ? "checkmark.circle.fill" : "circle")
                                                .contentTransition(.symbolEffect(.replace))
                                            
                                        })
                                        .frame(width: 35, height: 35)
                                        .foregroundStyle(bTask.subtasks[i].details[j].isCompleted ? .green : .white)
                                        
                                    }
                                    .padding(.vertical, 5)
                                    .padding(.horizontal, 10)
                                    .background(Color.darkPurple)
                                    .cornerRadius(10)
                                    .foregroundStyle(.white)
                                    .shadow(radius: 5)
                                    
                                }
                                
                            }
                        }
                        .listRowBackground(Color.faPurple)
                    }

                    .buttonStyle(BorderlessButtonStyle())
                    .listRowSpacing(10)
                    .scrollContentBackground(.hidden)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                dismiss()
                            } label: {
                                XDismissButton()
                            }
                            .padding(2)
                            .padding(.top, 5)
                        }

                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Start") {
                                if let task = blendedTask.correspondingTask {
                                    taskToActivate = task
                                } else {
                                    print("error")
                                }
                            }
                            .buttonStyle(.bordered)
                            .tint(.activeFaPurple)
                            .controlSize(.small)
                            .padding(2)
                            .padding(.top, 5)
                        }
                    }


                }
                
            }
            .navigationTitle("\(blendedTask.name)")
        }
        .fullScreenCover(item: $taskToActivate) { task in
            ActiveTaskView(task: task)
        }
    }
    
}

struct myPreview: View {
    var body: some View {
        NavigationStack {
            Text("")
                .sheet(isPresented: .constant(true), content: {
                    let config = ModelConfiguration(isStoredInMemoryOnly: true)
                    let container = try! ModelContainer(for: UserTask.self, BlendedTask.self, configurations: config)
                    
                    BlendedTaskDetailView(blendedTask: try! decodeBlendedTask(from: serviceInfo.mockTask2, modelContext: container.mainContext))
                        .modelContainer(container)
                })
        }
    }
}

#Preview {
   myPreview()
}
