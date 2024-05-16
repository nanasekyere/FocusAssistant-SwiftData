//
//  AddTaskView.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 07/04/2024.
//
//

import SwiftUI
import SwiftData
import SymbolPicker

struct AddTaskView: View {
    // Fetching tasks
    @Query var tasks: [UserTask]
    // Environment variables
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) private var dismiss

    // State variables
    @FocusState private var isFocused: Bool
    @Bindable var vm = AddTaskViewModel()
    @State private var shake = false

    // App storage for task time
    @AppStorage("taskTime") var taskTime: Int?


    var body: some View {
        NavigationStack {
            ZStack {
                // Background color
                Color.bgDark.ignoresSafeArea()

                VStack {
                    Form {
                        // Task details section
                        Section("Task Details") {
                            // Task name
                            TextField("Name", text: $vm.name)
                                .focused($isFocused)
                                .autocorrectionDisabled(true)
                            // Pomodoro task toggle
                            Toggle("Pomodoro Task?", isOn: $vm.pomodoro)
                                .onChange(of: vm.pomodoro) { oldValue, newValue in
                                    if newValue == true {
                                        vm.pomodoroCounter = 0
                                        vm.duration = taskTime ?? 1500
                                        vm.startTime = nil
                                        vm.isRecurring = false
                                        vm.repeatEvery = nil
                                    }

                                    if newValue == false {
                                        vm.pomodoroCounter = nil
                                        vm.duration = 0
                                    }
                                }
                            // Recurring task toggle
                            Toggle("Recurring Task?", isOn: $vm.isRecurring)
                                .onChange(of: vm.isRecurring) { oldValue, newValue in
                                    if newValue == true {
                                        vm.pomodoro = false
                                        vm.isRecurring = true
                                        vm.repeatEvery = 0
                                    }

                                    if newValue == false {
                                        vm.repeatEvery = nil
                                    }
                                }
                            // Start time date picker
                            if !vm.pomodoro {
                                DatePicker("Start Time", selection: $vm.startTime.bound, displayedComponents: [.date, .hourAndMinute])

                                // Duration picker button
                                Button(vm.duration == 0 ? "Choose Duration" : "Duration: \(vm.duration.timeString())" ) {
                                    vm.showDurationPicker = true
                                }
                                .tint(.white)

                                .popover(isPresented: $vm.showDurationPicker, arrowEdge: .top) {
                                    DurationPicker(duration: $vm.duration)
                                        .padding()
                                        .presentationCompactAdaptation((.popover))
                                }
                            }

                            // Repeat every duration picker button
                            if vm.isRecurring {
                                Button(vm.repeatEvery == 0 ? "Repeat Every:" : "Repeat Every: \(vm.repeatEvery?.timeString() ?? "")" ) {
                                    vm.showRepetitionPicker = true
                                }
                                .tint(.white)

                                .popover(isPresented: $vm.showRepetitionPicker, arrowEdge: .top) {
                                    RepeatPicker(duration: $vm.repeatEvery.bound)
                                        .padding()
                                        .presentationCompactAdaptation(.popover)
                                }
                            }

                            // Priority picker
                            Picker("Priority", selection: $vm.priority) {
                                ForEach(Priority.allCases, id: \.self) { priority in
                                    Text(priority.rawValue.capitalized)
                                }
                            }
                        }
                        .listRowBackground(Color.darkPurple)

                        // Optional details section
                        Section("Optional Details") {
                            // Icon picker button
                            Button {
                                vm.isShowingIconPicker = true
                            } label: {
                                HStack {
                                    Text(vm.imageURL == nil ? "Choose Icon" : "Change icon")
                                    Spacer()
                                    Image(systemName: vm.imageURL ?? "square.and.arrow.up")
                                        .frame(alignment: .trailing)
                                }
                            }
                            .tint(.white)
                            .sheet(isPresented: $vm.isShowingIconPicker) {
                                SymbolPicker(symbol: $vm.imageURL)
                            }

                            // Task description text field
                            TextField(text: $vm.details.bound) {
                                Text("Describe the task")
                            }
                            .focused($isFocused)
                            // Save button
                            Section {
                                Button("Save changes") {
                                    if vm.isComplete {
                                        let actor = BackgroundSerialPersistenceActor(modelContainer: context.container)
                                        let newTask = UserTask(name: vm.name.trimWhiteSpace(), duration: vm.duration, startTime: vm.startTime, priority: vm.priority, imageURL: vm.imageURL, details: vm.details, pomodoro: vm.pomodoro, pomodoroCounter: vm.pomodoroCounter, isRecurring: vm.isRecurring, repeatEvery: vm.repeatEvery)
                                        Task {
                                            if let clashingTask = try await actor.isTaskClashing(for: newTask) {
                                                vm.clashingTask = clashingTask
                                                vm.showClashAlert = true
                                                shake = true
                                            } else {
                                                newTask.scheduleNotification()
                                                context.insert(newTask)
                                                dismiss()
                                            }
                                        }
                                    } else {
                                        shake = true
                                    }
                                }
                                .tint(.white)
                            }
                            .listRowBackground(Color.activeFaPurple)
                            .shake($shake)
                        }
                        .listRowBackground(Color.darkPurple)
                    }
                    .foregroundStyle(Color.white)
                    .listRowSpacing(10)
                    .scrollContentBackground(.hidden)
                    .scrollDismissesKeyboard(.immediately)
                }
            }
            // Alert for clashing tasks
            .alert("Task is clashing with \(vm.clashingTask?.name ?? "")", isPresented: $vm.showClashAlert, presenting: vm.clashingTask, actions: { clashingTask in
                Button("OK") {
                    vm.clashingTask = nil
                }
            }, message: { clashingTask in
                Text("\(clashingTask.name) runs from \(clashingTask.startTime!.formatted(date: .omitted, time: .shortened)) to \(clashingTask.startTime!.addingTimeInterval(Double(clashingTask.duration)).formatted(date: .omitted, time: .shortened)) on \(clashingTask.startTime!.formatted(date: .numeric, time: .omitted)).\n\n Schedule the task at another time")
            })
            .preferredColorScheme(.dark)
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
        }

    }

}

struct EditTaskView: View {
    // Fetching tasks
    @Query var tasks: [UserTask]
    // Environment variables
    @Environment(\.dismiss) private var dismiss

    // State variables
    @FocusState private var isFocused: Bool
    @Bindable var vm = AddTaskViewModel()
    @Bindable var task: UserTask
    @State private var shake = false

    // App storage for task time
    @AppStorage("taskTime") var taskTime: Int?
    var modelContext: ModelContext

    init(taskID: PersistentIdentifier, in container: ModelContainer) {
        modelContext = ModelContext(container)
        modelContext.autosaveEnabled = false
        task = modelContext.model(for: taskID) as? UserTask ?? UserTask()
    }

    var body: some View {

        NavigationStack {
            ZStack {
                Color.bgDark.ignoresSafeArea()

                VStack {
                    Form {
                        Section("Task Details") {
                            TextField("Name", text: $task.name)
                                .focused($isFocused)
                                .autocorrectionDisabled(true)
                            Toggle("Pomodoro Task?", isOn: $task.pomodoro)
                                .onChange(of: task.pomodoro) { oldValue, newValue in
                                    if newValue == true {
                                        task.duration = taskTime ?? 1500
                                        task.startTime = nil
                                    }
                                }
                            if !task.pomodoro {
                                DatePicker("Start Time", selection: $task.startTime.bound, displayedComponents: [.date, .hourAndMinute])

                                Button(task.duration == 0 ? "Choose Duration" : "Duration: \(task.duration.recurringTimeString())" ) {
                                    vm.showDurationPicker = true
                                }
                                .tint(.white)

                                .popover(isPresented: $vm.showDurationPicker, arrowEdge: .top) {
                                    DurationPicker(duration: $task.duration)
                                        .padding()
                                        .presentationCompactAdaptation((.popover))

                                }
                            }

                            Picker("Priority", selection: $task.priority) {
                                ForEach(Priority.allCases, id: \.self) { priority in
                                    Text(priority.rawValue.capitalized)
                                }
                            }
                        }
                        .listRowBackground(Color.darkPurple)

                        Section("Optional Details") {
                            Button {
                                vm.isShowingIconPicker = true
                            } label: {
                                HStack {
                                    Text(task.imageURL == nil ? "Choose Icon" : "Change icon")
                                    Spacer()
                                    Image(systemName: task.imageURL ?? "square.and.arrow.up")
                                        .frame(alignment: .trailing)
                                }
                            }
                            .tint(.white)
                            .sheet(isPresented: $vm.isShowingIconPicker) {
                                SymbolPicker(symbol: $task.imageURL)

                            }

                            TextField(text: $task.details.bound) {
                                Text("Describe the task")
                            }
                            .focused($isFocused)
                            Section {
                                Button("Save changes") {
                                        let actor = BackgroundSerialPersistenceActor(modelContainer: modelContext.container)
                                        Task {
                                            if let clashingTask = try await actor.isTaskClashing(for: task) {
                                                vm.clashingTask = clashingTask
                                                vm.showClashAlert = true
                                                shake = true
                                            } else {
                                                task.descheduleNotification()
                                                task.scheduleNotification()
                                                try? modelContext.save()
                                                dismiss()
                                            }
                                        }
                                }
                                .tint(.white)

                            }
                            .listRowBackground(Color.activeFaPurple)
                            .shake($shake)

                        }
                        .listRowBackground(Color.darkPurple)
                    }
                    .foregroundStyle(Color.white)
                    .listRowSpacing(10)
                    .scrollContentBackground(.hidden)
                    .scrollDismissesKeyboard(.immediately)
                }

            }
            .alert("Task is clashing with \(vm.clashingTask?.name ?? "")", isPresented: $vm.showClashAlert, presenting: vm.clashingTask, actions: { clashingTask in
                Button("OK") {
                    vm.clashingTask = nil
                }
            }, message: { clashingTask in
                Text("\(clashingTask.name) runs from \(clashingTask.startTime!.formatted(date: .omitted, time: .shortened)) to \(clashingTask.startTime!.addingTimeInterval(Double(clashingTask.duration)).formatted(date: .omitted, time: .shortened)) on \(clashingTask.startTime!.formatted(date: .numeric, time: .omitted)).\n\n Schedule the task at another time")
            })
            .preferredColorScheme(.dark)
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

}

#Preview {
    struct PreviewWrapper: View {
        var body: some View {
            AddTaskView()
                .modelContainer(DataController.previewContainer)
        }
    }

    return PreviewWrapper()
}
