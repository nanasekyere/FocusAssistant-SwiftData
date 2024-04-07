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
    @Query(filter: #Predicate<UserTask> { task in
        task.isCompleted
    })
    var completedTasks: [UserTask]
    @Query(filter: #Predicate<UserTask> { task in
        !(task.isCompleted && task.isExpired)
    })
    var availableTasks: [UserTask]
    @Query(filter: #Predicate<UserTask> { task in
        task.isExpired
    })
    var expiredTasks: [UserTask]
    
    @EnvironmentObject var activeVM: ActiveTaskViewModel
    
    @State var vm = TaskViewModel()
    @State private var currentDay: Date = .init()
    @State var activeAnimator = true
    @State var priorityAnimator = true
    
    var body: some View {
        ZStack {
            Color.BG
                .ignoresSafeArea()
            VStack {
                
                
                if tasks.isEmpty {
                    ContentUnavailableView("No Tasks", systemImage: "tag.slash.fill", description: Text("You don't have any tasks currently, press the button to create one"))
                } else {
                    
                    List {
                        switch vm.status {
                        case .showAll:
                            allTasksView()
                        case .showDaily:
                            dailyTasksView()
                        case .showWeekly:
                            weeklyTasksView()
                        }
                        
                        Section("Completed Tasks (\(completedTasks.count))", isExpanded: $vm.isShowingCompleted) {
                            ForEach(completedTasks) {task in
                                    TaskCell(task: task)
                            }
                        }
                        
                        Section("Expired Tasks (\(expiredTasks.count))", isExpanded: $vm.isShowingExpiredTasks) {
                            ForEach(expiredTasks) {task in
                                    TaskCell(task: task)
                            }
                        }
                    }
                    .listRowSpacing(10)
                    .scrollContentBackground(.hidden)
                }
                
                Spacer()
                
                HStack {
                    Button {
                        vm.isDisplayingAddView = true
                    } label: {
                        Text("Add new task")
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                    
                    Spacer()
                    
                    Menu(content: {
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
                        Button(vm.isShowingCompleted ? "Hide Completed tasks" : "Show Completed tasks", action: {vm.isShowingCompleted.toggle()})
                        
                        Button(vm.isShowingExpiredTasks ? "Hide Expired tasks" : "Show Expired tasks", action: {vm.isShowingExpiredTasks.toggle()})
                        
                        Button("Clear Completed", role: .destructive) {
//                            vm.user.clearCompleted()
                        }
                        .disabled(completedTasks.count < 1)
                    }, label: {
                        Image(systemName: "line.3.horizontal.circle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .foregroundStyle(.primary)
                    })
                    .padding()
                }
                
                .padding()
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
        }
        
        
        
    }
    
    @ViewBuilder
    func allTasksView() -> some View {
        Section("To-do") {
            ForEach(availableTasks) { task in
//                if activeVM.activeTask != task {
                    TaskCell(task: task)
//                }
            }
            
        }
    }
    
    @ViewBuilder
    func TaskCell(task: UserTask) -> some View {
        
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
                Text("\(task.duration.timeString())")
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
                    
                } else if task.blended {
                    Color.darkPurple
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
            Button(role: .destructive) {  } label: {
                Label("Delete", systemImage: "trash")
            }
            if !task.blended {
                Button(action: {
                    vm.taskToEdit = task
                }, label: {
                    Label("Edit", systemImage: "square.and.pencil")
                })
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
}

#Preview {
    TaskView()
        .modelContainer(for: UserTask.self, inMemory: true)
        .environmentObject(ActiveTaskViewModel(activeTask: mockTask))
}
