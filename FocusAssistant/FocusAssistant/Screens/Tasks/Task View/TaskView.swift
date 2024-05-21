//
//  TaskView.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 07/04/2024.
//

import SwiftUI
import SwiftData

struct TaskView: View {
    // Querying tasks from the database
    @Query var tasks: [UserTask]
    @Query var bTasks: [BlendedTask]
    // Querying completed tasks excluding blended tasks
    @Query(filter: #Predicate<UserTask> { task in
        task.isCompleted && !task.isExpired && task.blendedTask == nil
    })
    var completedTasks: [UserTask]
    // Querying available tasks excluding completed and blended tasks, sorted by start time
    @Query(filter: #Predicate<UserTask> { task in
        !task.isCompleted && !task.isExpired && task.blendedTask == nil
    }, sort: \.startTime)
    var availableTasks: [UserTask]
    // Querying expired tasks
    @Query(filter: #Predicate<UserTask> { task in
        task.isExpired
    })
    var expiredTasks: [UserTask]

    // Environment variables
    @Environment(\.modelContext) var context
    @Environment(ActiveTaskViewModel.self) var activeVM

    // State variables
    @State var vm = TaskViewModel()
    @State private var currentDay: Date = .init()
    @State var activeAnimator = true
    @State var priorityAnimator = true

    var body: some View {
        NavigationStack {
            ZStack {
                // Background color
                Color.BG
                    .ignoresSafeArea()
                VStack {
                    if tasks.isEmpty && bTasks.isEmpty {
                        // If there are no tasks, display content unavailable view
                        ContentUnavailableView("No Tasks", systemImage: "tag.slash.fill", description: Text("You don't have any tasks currently, press the button to create one"))
                    } else {
                        // Display tasks
                        List {
                            // Active task section
                            if let activeTask = activeVM.activeTask, ((try? context.fetchIdentifiers(FetchDescriptor<UserTask>()).contains(activeTask.id)) != nil){
                                Section("Active Task") {
                                    ActiveTaskCell(task: activeTask)
                                }
                            }

                            // Switch statement based on view model status
                            switch vm.status {
                                case .showAll:
                                    allTasksView()
                                case .showDaily:
                                    dailyTasksView()
                                case .showWeekly:
                                    weeklyTasksView()
                            }

                            // Blended tasks section
                            Section("Blended Tasks (\(bTasks.count))", isExpanded: $vm.isShowingBlendedTasks) {
                                ForEach(bTasks) { task in
                                    TaskCell(task: task.correspondingTask!)
                                }
                            }

                            // Completed tasks section
                            if !completedTasks.isEmpty {
                                Section("Completed Tasks (\(completedTasks.count))", isExpanded: $vm.isShowingCompleted) {
                                    ForEach(completedTasks) {task in
                                        TaskCell(task: task)
                                    }
                                }
                            }

                            // Expired tasks section
                            if !expiredTasks.isEmpty {
                                Section("Expired Tasks (\(expiredTasks.count))", isExpanded: $vm.isShowingExpiredTasks) {
                                    ForEach(expiredTasks) {task in
                                        TaskCell(task: task)
                                    }
                                }
                            }
                        }
                        .listRowSpacing(10)
                        .scrollContentBackground(.hidden)

                    }

                }
                .sheet(isPresented: $vm.isDisplayingAddView, content: {
                    TaskMapperView()
                })

                .sheet(item: $vm.taskToEdit) { task in
                    EditTaskView(taskID: task.id, in: context.container)
                }

                .sheet(item: $vm.taskDetail) { task in
                    TaskDetailView(task: task)
                }

                .sheet(item: $vm.bTaskDetail) { task in
                    BlendedTaskDetailView(blendedTask: task)
                }

                .sheet(isPresented: $vm.isShowingActiveView, content: {
                    ActiveTaskView(task: activeVM.activeTask!)
                })


            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    // Add button
                    Button("Add", systemImage: "plus") {
                        vm.isDisplayingAddView = true
                    }
                    .tint(.activeFaPurple)
                }

                ToolbarItem(placement: .secondaryAction) {
                    // Filters menu
                    Menu("Filters", content: {
                        Button("Show All tasks", action: {
                            vm.status = .showAll
                        })
                        .disabled(vm.status == .showAll)
                        Button("Show Weekly tasks", action: {
                            vm.status = .showWeekly
                        }
                        )
                        .disabled(vm.status == .showWeekly)
                        Button("Show Daily tasks", action: {
                            vm.status = .showDaily
                        })
                        .disabled(vm.status == .showDaily)

                        Button(vm.isShowingBlendedTasks ? "Hide Blended tasks" : "Show Blended tasks", action: {vm.isShowingBlendedTasks.toggle()})

                        Button(vm.isShowingCompleted ? "Hide Completed tasks" : "Show Completed tasks", action: {vm.isShowingCompleted.toggle()})

                        Button(vm.isShowingExpiredTasks ? "Hide Expired tasks" : "Show Expired tasks", action: {vm.isShowingExpiredTasks.toggle()})

                        Button("Clear Completed", role: .destructive) {
                            try! context.delete(model: UserTask.self, where: #Predicate<UserTask> { task in
                                task.isCompleted
                            })
                        }
                        .disabled(completedTasks.count < 1)
                    })
                    .padding(.horizontal, 20)
                    .padding(.top, 5)

                }
            }
        }

    }

    // View for displaying all tasks
    @ViewBuilder
    func allTasksView() -> some View {
        Section("To-do") {
            ForEach(availableTasks) { task in
                if activeVM.activeTask?.identity != task.identity {
                    TaskCell(task: task)
                }
            }

        }
    }

    // View for displaying weekly tasks
    @ViewBuilder
    func weeklyTasksView() -> some View {
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter
        }()

        let thisWeekTasksByDate = (0..<7).compactMap { index -> (Date, [UserTask])? in
            let date = Calendar.current.date(byAdding: .day, value: index, to: Date()) ?? Date()
            let tasksForDay = availableTasks.filter { task in
                if let startTime = task.startTime {
                    return Calendar.current.isDate(startTime, inSameDayAs: date)
                } else {
                    return false
                }
            }
            return tasksForDay.isEmpty ? nil : (date, tasksForDay)
        }

        ForEach(thisWeekTasksByDate, id: \.0) { date, tasksForDay in
            Section(header: Text("\(date, formatter: dateFormatter)")) {
                ForEach(tasksForDay) { task in
                    if activeVM.activeTask?.identity != task.identity {
                        TaskCell(task: task)
                    }
                }
            }
        }
    }

    // View for displaying daily tasks
    @ViewBuilder
    func dailyTasksView() -> some View {
        Section("Today's Tasks") {
            ForEach(availableTasks.filter { task in
                if let startTime = task.startTime {
                    return Calendar.current.isDateInToday(startTime)
                } else {
                    return false
                }
            }) { task in
                if activeVM.activeTask?.identity != task.identity {
                    TaskCell(task: task)
                }
            }
        }
    }

    // View for individual task cell
    @ViewBuilder
    func TaskCell(task: UserTask) -> some View {

        HStack(spacing: 20) {
            if task.blendedTask == nil {
                Image(systemName: task.imageURL ?? "note.text")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .foregroundStyle(.white)
            } else {
                Image(systemName: "tornado")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .foregroundStyle(.white)
            }


            VStack(alignment: .leading) {
                Text(task.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(alignment: .leading)
                Text(task.pomodoro ? "\(task.pomodoroCounter!) completions" : "\(task.duration.timeString())")
                    .foregroundStyle(.white)
            }
            Spacer()

            if task.pomodoro {
                Image(systemName: "repeat.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .foregroundStyle(.white)
                Text(String(task.pomodoroCounter!))
                    .foregroundStyle(.white)
            } else {
                WeightingIndicator(weight: task.priority)
                    .frame(alignment: .trailing)
            }

        }
        .contentShape(Rectangle())
        .onTapGesture {
            if task.blendedTask == nil && !task.isCompleted{
                vm.taskDetail = task
            } else {
                vm.bTaskDetail = task.blendedTask!
            }
        }
        .listRowBackground(
            ZStack {
                if task.priority == .high {
                    LinearGradient(colors: [.faPurple, priorityAnimator ? .red : .faPurple], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .animation(.easeInOut(duration: 2), value: priorityAnimator)

                } else if task.blendedTask != nil {
                    if task.isCompleted == true {
                        Color.gray
                    } else {
                        Color.darkPurple
                    }

                } else {
                    Color.faPurple
                }
            }


        )
        .onAppear {
            if task.priority == .high {
                Timer.scheduledTimer(withTimeInterval: 1.25, repeats: true) { timer in
                    priorityAnimator.toggle()
                }
            }
        }
        .swipeActions() {
            Button(role: .destructive) {
                task.descheduleNotification()
                if task.blendedTask == nil {
                    context.delete(task)
                } else {
                    if let bTask = bTasks.first(where: { $0.identity == task.identity}) {
                        context.delete(bTask)
                    }
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
            if task.blendedTask == nil && !task.isExpired {
                Button(action: {
                    vm.taskToEdit = task
                }, label: {
                    Label("Edit", systemImage: "square.and.pencil")
                })
            } else if task.blendedTask != nil && task.isCompleted == true {
                Button {
                    task.isCompleted = false
                    task.pomodoroCounter = 0
                } label: {
                    Label("Refresh Task", systemImage: "arrow.circlepath")
                }

            }
        }

    }

    // View for active task cell
    @ViewBuilder
    func ActiveTaskCell(task: UserTask) -> some View {

        HStack(spacing: 20) {
            Image(systemName: task.imageURL ?? "note.text")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .foregroundStyle(.white)

            VStack(alignment: .leading) {
                Text(task.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(alignment: .leading)
                Text(activeVM.timerStringValue)
                    .foregroundStyle(.white)
            }
            Spacer()

            Image(systemName: "deskclock.fill")
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundStyle(.white)

        }

        .contentShape(Rectangle())
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.75, repeats: true) { timer in
                activeAnimator.toggle()
            }

        }
        .onTapGesture {
            vm.isShowingActiveView = true
        }
        .listRowBackground(
            ZStack {
                Rectangle()
                    .fill(Color.faPurple)
                    .opacity(activeAnimator ? 1 : 0)

                Rectangle()
                    .fill(Color.activeFaPurple)
                    .opacity(activeAnimator ? 0 : 1)

            }
                .animation(.easeInOut(duration: 0.75), value: activeAnimator)
        )
        .swipeActions() {
            Button(role: .destructive) {
                activeVM.endTimer()
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [activeVM.activeTask!.identity.uuidString])
                activeVM.activeTask = nil
            } label: {
                Label("Stop", systemImage: "stop.circle")
            }
        }


    }

}

#Preview {
    struct PreviewWrapper: View {
        var body: some View {
            TaskView()
                .modelContainer(DataController.previewContainer)
                .environment(ActiveTaskViewModel(activeTask: mockTask))
        }
    }

    return PreviewWrapper()
}
