//
// NewBlendedTaskView.swift
// FocusAssistant
//
// Created by Nana Sekyere on 14/04/2024.
//

import SwiftUI
import SwiftData

/// View for creating a new blended task.
struct NewBlendedTaskView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss

    // ViewModel for creating a new blended task
    @Bindable private var vm = NewBlendedTaskViewModel()

    @State private var isShowingDialog = false
    @State private var isExpanded = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background color
                Color.BG.ignoresSafeArea()
                // Form for input fields
                Form {
                    Section(header: Text("Task Name")) {
                        TextField("Task Name", text: $vm.taskName)
                    }
                    .listRowBackground(Color.darkPurple)

                    // Iterate through subtasks
                    ForEach(vm.subtasks.indices, id: \.self) { index in
                        Section(header: Text(vm.subtasks[index].name == "" ? "Subtask" : "Subtask: \(vm.subtasks[index].name)")) {
                            TextField("Subtask Name", text: $vm.subtasks[index].name)

                            SubtaskView(subtask: $vm.subtasks[index])
                        }
                    }
                    .listRowBackground(Color.darkPurple)

                    // Button to add new subtask
                    Section {
                        Button(action: {
                            vm.subtasks.append(DummySubtask(name: ""))
                        }, label: {
                            Text("Add Subtask")
                        })
                    }
                    .listRowBackground(Color.darkPurple)

                    // Preview section
                    Section(header: Text("Preview")) {
                        Text("Task Name: \(vm.taskName)")
                        ForEach(vm.subtasks, id: \.self) { subtask in
                            DisclosureGroup("\(subtask.name)", isExpanded: $isExpanded) {
                                ForEach(subtask.details, id: \.self) { detail in
                                    Text("Detail: \(detail.desc)")
                                }
                            }
                        }
                    }
                    .listRowBackground(Color.darkPurple)
                }
                .foregroundStyle(Color.white)
                .tint(.activeFaPurple)
                .scrollContentBackground(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }


            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    // Button to create the task
                    Button("Create") { isShowingDialog = true }
                    .disabled(!vm.isComplete())
                }
            }
            // Confirmation dialog for creating the task
            .confirmationDialog("Are you satisfied with this task?", isPresented: $isShowingDialog, actions: {
                // Button to confirm task creation
                Button("Create task") {
                    do {
                        let dummyTask = DummyTask(name: vm.taskName, subtasks: vm.subtasks)
                        try createTask(from: dummyTask, modelContext: context)
                        dismiss()
                    } catch {
                        print("error creating task: \(error)")
                    }
                }

                // Button to cancel task creation
                Button("Cancel", role: .destructive) {
                    isShowingDialog = false
                }

            }, message: {
                Text("Blended tasks cannot be edited once created")
            })
            .navigationTitle(vm.taskName == "" ? "New Task" :" Task: \(vm.taskName)")
        }
    }
}

/// View for displaying and editing subtasks.
struct SubtaskView: View {
    @Binding var subtask: DummySubtask

    var body: some View {
        // Iterate through details of the subtask
        ForEach(subtask.details.indices, id: \.self) { index in
            DetailView(detail: $subtask.details[index])
        }

        // Button to add a new detail to the subtask
        Button(action: {
            subtask.details.append(DummyDetail(desc: ""))
        }, label: {
            Text("Add Detail")
        })
    }
}

/// View for displaying and editing details of a subtask.
struct DetailView: View {
    @Binding var detail: DummyDetail

    var body: some View {
        TextField("Detail Description (min. 5 characters)", text: $detail.desc)
    }
}

#Preview {
    NewBlendedTaskView()
        .modelContainer(DataController.previewContainer)
}
