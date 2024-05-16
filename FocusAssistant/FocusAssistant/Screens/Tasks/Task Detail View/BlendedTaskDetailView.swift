//
//  BlendedTaskDetailView.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 06/04/2024.
//

import SwiftUI
import SwiftData

struct BlendedTaskDetailView: View {
    // Environment variables
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    // Query to fetch blended tasks
    @Query var bTasks: [BlendedTask]

    // State variables
    @State private var isAnimated = false
    @State private var taskToActivate: UserTask?
    @Bindable var blendedTask: BlendedTask

    var body: some View {
        NavigationStack {
            ZStack {
                // Background color
                Color.BG.ignoresSafeArea()

                // Displaying blended task details
                if let bTask = bTasks.first(where: { $0.id == blendedTask.id }) {
                    List {
                        ForEach(bTask.sortedSubtasks.indices, id: \.self) { i  in
                            VStack(alignment: .center) {
                                // Task name
                                Text("Task: \(bTask.sortedSubtasks[i].name)")
                                    .font(.headline)
                                    .foregroundStyle(.white)

                                // Displaying task details
                                ForEach(bTask.sortedSubtasks[i].sortedDetails.indices, id: \.self) { j in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(bTask.sortedSubtasks[i].sortedDetails[j].desc)
                                        }
                                        Spacer()

                                        // Checkbox to mark completion
                                        Button(action: {
                                            withAnimation {
                                                bTask.sortedSubtasks[i].sortedDetails[j].isCompleted.toggle()
                                            }
                                        }, label: {
                                            Image(systemName: bTask.sortedSubtasks[i].sortedDetails[j].isCompleted ? "checkmark.circle.fill" : "circle")
                                                .contentTransition(.symbolEffect(.replace))
                                        })
                                        .frame(width: 35, height: 35)
                                        .foregroundStyle(bTask.sortedSubtasks[i].sortedDetails[j].isCompleted ? .green : .white)

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
                        // Toolbar items
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                dismiss()
                            } label: {
                                // Custom button to dismiss view
                                XDismissButton()
                            }
                            .padding(2)
                            .padding(.top, 5)
                        }

                        ToolbarItem(placement: .topBarTrailing) {
                            // Start button
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
        // Full screen cover to display active task
        .fullScreenCover(item: $taskToActivate) { task in
            // Displaying active task view
            ActiveTaskView(task: task)
        }
    }
}

struct myPreview: View {
    var body: some View {
        NavigationStack {
            Text("")
                .sheet(isPresented: .constant(true), content: {
                    // Creating blended task detail view for preview
                    let config = ModelConfiguration(isStoredInMemoryOnly: true)
                    let container = try! ModelContainer(for: UserTask.self, BlendedTask.self, configurations: config)

                    BlendedTaskDetailView(blendedTask: try! decodeBlendedTask(from: serviceInfo.mockTask2, modelContext: container.mainContext))
                        .modelContainer(container)
                })
        }
    }
}

#Preview {
   // Displaying preview of blended task detail view
   myPreview()
}
