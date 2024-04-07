//
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
    @Query var tasks: [UserTask]
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) private var dismiss
    
    @FocusState private var isFocused: Bool
    @Bindable var vm = AddTaskViewModel()
    
    @State private var shake = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgDark.ignoresSafeArea()
                
                VStack {
                    Form {
                        Section("Task Details") {
                            TextField("Name", text: $vm.name)
                                .focused($isFocused)
                                .autocorrectionDisabled(true)
                            Toggle("Pomodoro Task?", isOn: $vm.pomodoro)
                            
                                .onChange(of: vm.pomodoro) { oldValue, newValue in
                                    if newValue == true {
                                        vm.duration = 1500
                                        vm.startTime = nil
                                    }
                                }
                            if !vm.pomodoro {
                                DatePicker("Start Time", selection: $vm.startTime.bound, displayedComponents: [.date, .hourAndMinute])
                                
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
                            
                            Picker("Priority", selection: $vm.priority) {
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
                            
                            TextField(text: $vm.details.bound) {
                                Text("Describe the task")
                            }
                            .focused($isFocused)
                            Section {
                                Button("Save changes") {
                                    if vm.isComplete {
                                        let newTask = UserTask(name: vm.name, duration: vm.duration, startTime: vm.startTime, priority: vm.priority, imageURL: vm.imageURL, details: vm.details, pomodoro: vm.pomodoro, pomodoroCounter: vm.pomodoroCounter)
                                        context.insert(newTask)
                                        
                                        dismiss()
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
                }
            }
            .preferredColorScheme(.dark)
            .navigationTitle("New Task")
        }
    }
    
    
}

struct EditTaskView: View {
    @Query var tasks: [UserTask]
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) private var dismiss
    
    @FocusState private var isFocused: Bool
    @Bindable var vm = AddTaskViewModel()
    @Bindable var task: UserTask
    @State private var shake = false
    
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
                                        task.duration = 1500
                                        task.startTime = nil
                                    }
                                }
                            if !task.pomodoro {
                                DatePicker("Start Time", selection: $task.startTime.bound, displayedComponents: [.date, .hourAndMinute])
                                
                                Button(task.duration == 0 ? "Choose Duration" : "Duration: \(task.duration.timeString())" ) {
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
                                    dismiss()
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
                }
            }
            .preferredColorScheme(.dark)
            .navigationTitle("Edit Task")
        }
    }
  
}

#Preview {
    
    AddTaskView()
        .modelContainer(for: UserTask.self, inMemory: true)
}
