//
//  TaskView.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 07/04/2024.
//

import SwiftUI
import SwiftData

struct TaskView: View {
    @Query var tasks: [UserTask]
    @Query var bTasks: [BlendedTask]
    @Query(filter: #Predicate<UserTask> { task in
        task.isCompleted && !task.isExpired && task.blendedTask == nil
    })
    var completedTasks: [UserTask]

    @Query(filter: #Predicate<UserTask> { task in
        !task.isCompleted && !task.isExpired && task.blendedTask == nil
    }, sort: \.startTime)
    var availableTasks: [UserTask]

    @Query(filter: #Predicate<UserTask> { task in
        task.isExpired
    })
    var expiredTasks: [UserTask]

    @Environment(\.modelContext) var context
    @Environment(ActiveTaskViewModel.self) var activeVM

    @State var vm = TaskViewModel()
    @State private var currentDay: Date = .init()
    @State var activeAnimator = true
    @State var priorityAnimator = true

    var body: some View {
        NavigationStack {
            ZStack {
                Color.BG
                    .ignoresSafeArea()
                VStack {
                    if tasks.isEmpty && bTasks.isEmpty {
                        ContentUnavailableView("No Tasks", systemImage: "tag.slash.fill", description: Text("You don't have any tasks currently, press the button to create one"))
                    } else {

                        List {

                            if let activeTask = activeVM.activeTask, tasks.contains(activeTask) {
                                Section("Active Task") {
                                    ActiveTaskCell(task: activeTask)
                                }
                            }

                            switch vm.status {
                                case .showAll:
                                    allTasksView()
                                case .showDaily:
                                    dailyTasksView()
                                case .showWeekly:
                                    weeklyTasksView()
                            }
                            Section("Blended Tasks (\(bTasks.count))", isExpanded: $vm.isShowingBlendedTasks) {
                                ForEach(bTasks) { task in
                                    TaskCell(task: task.correspondingTask!)
                                }
                            }

                            if !completedTasks.isEmpty {
                                Section("Completed Tasks (\(completedTasks.count))", isExpanded: $vm.isShowingCompleted) {
                                    ForEach(completedTasks) {task in
                                        TaskCell(task: task)
                                    }
                                }
                            }


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
                    AddTaskView()
                })

                .sheet(item: $vm.taskToEdit) { task in
                    EditTaskView(task: task)
                }

                .sheet(item: $vm.taskDetail) { task in
                    TaskDetailView(task: task)
                }

                .sheet(item: $vm.bTaskDetail) { task in
                    BlendedTaskDetailView(blendedTask: task)
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add", systemImage: "plus") {
                        vm.isDisplayingAddView = true
                    }
                    .tint(.activeFaPurple)
                }

                ToolbarItem(placement: .secondaryAction) {
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

    @ViewBuilder
    func allTasksView() -> some View {
        Section("To-do") {
            ForEach(availableTasks) { task in
                if activeVM.activeTask != task {
                    TaskCell(task: task)
                }
            }

        }
    }


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
                    if activeVM.activeTask != task {
                        TaskCell(task: task)
                    }
                }
            }
        }
    }

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
                if activeVM.activeTask != task {
                    TaskCell(task: task)
                }
            }
        }
    }

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
            vm.taskDetail = task
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
                    context.delete(task.blendedTask!)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
            if task.blendedTask == nil {
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
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [activeVM.activeTask!.id.entityName])
                activeVM.activeTask = nil
            } label: {
                Label("Stop", systemImage: "stop.circl")
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
