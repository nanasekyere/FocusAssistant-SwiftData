//
//  
//  NewBlendedTaskView.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 14/04/2024.
//
//

import SwiftUI
import SwiftData


struct NewBlendedTaskView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) var dismiss

    @Bindable private var vm = NewBlendedTaskViewModel()

    @State private var isShowingDialog = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.BG.ignoresSafeArea()
                Form {
                    Section(header: Text("Task Name")) {
                        TextField("Task Name", text: $vm.taskName)
                    }
                    .listRowBackground(Color.darkPurple)

                    ForEach(vm.subtasks.indices, id: \.self) { index in
                        Section(header: Text(vm.subtasks[index].name == "" ? "Subtask" : "Subtask: \(vm.subtasks[index].name)")) {
                            TextField("Subtask Name", text: $vm.subtasks[index].name)

                            SubtaskView(subtask: $vm.subtasks[index])
                        }
                    }
                    .listRowBackground(Color.darkPurple)

                    Section {
                        Button(action: {
                            vm.subtasks.append(DummySubtask(name: ""))
                        }, label: {
                            Text("Add Subtask")
                        })
                    }
                    .listRowBackground(Color.darkPurple)

                    Section(header: Text("Preview")) {
                        Text("Task Name: \(vm.taskName)")
                        ForEach(vm.subtasks, id: \.self) { subtask in
                            @State var isExpanded = false
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
            }


            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") { isShowingDialog = true }
                    .disabled(!vm.isComplete())
                }
            }
            .confirmationDialog("Are you satisfied with this task?", isPresented: $isShowingDialog, actions: {
                Button("Create task") {
                    do {
                        let dummyTask = DummyTask(name: vm.taskName, subtasks: vm.subtasks)
                        try createTask(from: dummyTask, modelContext: context)
                        dismiss()
                    } catch {
                        print("error creating task: \(error)")
                    }
                }

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

struct SubtaskView: View {
    @Binding var subtask: DummySubtask

    var body: some View {
        ForEach(subtask.details.indices, id: \.self) { index in
            DetailView(detail: $subtask.details[index])
        }

        Button(action: {
            subtask.details.append(DummyDetail(desc: ""))
        }, label: {
            Text("Add Detail")
        })
    }
}

struct DetailView: View {
    @Binding var detail: DummyDetail

    var body: some View {
        TextField("Detail Description", text: $detail.desc)
    }
}

#Preview {
    NewBlendedTaskView()
        .modelContainer(DataController.previewContainer)
}
