//
//  HomeView.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 08/04/2024.
//
//

import SwiftUI
import SwiftData

struct HomeView: View {
    // Query for fetching user tasks
    @Query var tasks: [UserTask]

    // Environment object for accessing model context
    @Environment(\.modelContext) var context

    // State variable for current day and home view model
    @State private var currentDay: Date = .init()
    @Bindable var vm = HomeViewModel()

    // App storage for user name
    @AppStorage("userName") var userName: String?

    var body: some View {
        ZStack {
            // Background color
            Color.BG.ignoresSafeArea(.all)

            // Check if tasks are empty
            if tasks.isEmpty {
                // Show content unavailable view
                ContentUnavailableView("No Tasks", systemImage: "tag.slash.fill", description: Text("You don't have any tasks currently, head to the tasks tab to create one"))
            } else {
                // Show timeline view
                ScrollView(.vertical, showsIndicators: false) {
                    TimelineView()
                        .padding(15)
                }
                .safeAreaInset(edge: .top,spacing: 0) {
                    // Show header view
                    HeaderView()
                }
                .sheet(item: $vm.taskToEdit, content: { task in
                    EditTaskView(taskID: task.id, in: context.container)
                })
                .sheet(isPresented: $vm.isDisplayingAddView, content: {
                    AddTaskView()
                })
                .sheet(item: $vm.taskDetails) { task in
                    TaskDetailView(task: task)
                }
            }
        }
    }

    /// Timeline View
    @ViewBuilder
    func TimelineView()->some View{
        ScrollViewReader { proxy in
            let hours = Calendar.current.hours
            let midHour = hours[hours.count / 2]
            VStack{
                ForEach(hours,id: \.self){hour in
                    TimelineViewRow(hour)
                        .id(hour)
                }
            }
            .onAppear {
                proxy.scrollTo(midHour)
            }
        }

    }

    /// Timeline View Row
    @ViewBuilder
    func TimelineViewRow(_ date: Date)->some View{
        HStack(alignment: .top) {
            Text(date.toString("h a"))
                .font(.system(size: 16))
                .fontWeight(.regular)
                .frame(width: 45,alignment: .leading)

            // Filtering Tasks
            let calendar = Calendar.current
            let filteredTasks = tasks.filter{
                if let hour = calendar.dateComponents([.hour], from: date).hour,
                   let startTime = $0.startTime,
                   let taskHour = calendar.dateComponents([.hour], from: startTime).hour,
                   hour == taskHour && calendar.isDate(startTime, inSameDayAs: currentDay) && !$0.isCompleted && !$0.isExpired {
                    return true
                }
                return false
            }

            if filteredTasks.isEmpty{
                Rectangle()
                    .stroke(.gray.opacity(0.5), style: StrokeStyle(lineWidth: 0.5, lineCap: .butt, lineJoin: .bevel, dash: [5], dashPhase: 5))
                    .frame(height: 0.5)
                    .offset(y: 10)
            }else{
                // Task View
                VStack(spacing: 10){
                    ForEach(filteredTasks){task in
                        TaskRow(task)
                            .onTapGesture {
                                vm.taskDetails = task
                            }
                            .contextMenu {
                                Button("Show Details") {
                                    vm.taskDetails = task
                                }

                                Button("Edit Task") {
                                    vm.taskToEdit = task
                                }

                                Button("Delete Task", role: .destructive) {
                                    context.delete(task)
                                }

                            }
                    }
                }
            }
        }
        .hAlign(.leading)
        .padding(.vertical,15)
    }

    /// Task Row
    @ViewBuilder
    func TaskRow(_ task: UserTask)->some View{
        var highP: Bool {
            if task.priority == .high {
                false
            } else { true }
        }

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let taskImage = task.imageURL {
                    Image(systemName: taskImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 22, height: 22)
                        .foregroundStyle(highP ? .faPurple : .red)
                }

                Text(task.name.uppercased())
                    .font(.system(size: 16))
                    .fontWeight(.regular)
                    .foregroundStyle(highP ? .faPurple : .red)
                    .lineLimit(1)


                if task.details != nil {
                    Text(task.details!)
                        .font(.system(size: 14))
                        .fontWeight(.light)
                        .foregroundStyle(highP ? .faPurple.opacity(0.8) : .red.opacity(0.8))
                        .lineLimit(6)
                }
            }
        }
        .hAlign(.leading)
        .padding(12)
        .background {
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(highP ? .faPurple : .red)
                    .frame(width: 4)

                Rectangle()
                    .fill(highP ? .faPurple.opacity(0.25) : .red.opacity(0.25))
            }
        }
    }

    /// Header View
    @ViewBuilder
    func HeaderView()->some View{
        VStack{
            HStack{
                VStack(alignment: .leading, spacing: 6) {
                    Text("Today")
                        .font(.largeTitle)
                        .fontWeight(.light)

                    Text(userName == nil ? "Welcome" : "Welcome, \(userName!)")
                        .font(.subheadline)
                        .fontWeight(.light)
                }
                .hAlign(.leading)

                Button {
                    vm.isDisplayingAddView = true
                } label: {
                    HStack(spacing: 10){
                        Image(systemName: "plus")
                        Text("Add Task")
                    }
                } .buttonStyle(.borderedProminent)
            }

            // Today Date in String
            Text(Date().toString("MMM YYYY"))
                .hAlign(.leading)
                .padding(.top,15)

            // Current Week Row
            WeekRow()
        }
        .padding(15)
        .background {
            VStack(spacing: 0) {
                Color.BG

                // Gradient Opacity Background
                Rectangle()
                    .fill(.linearGradient(colors: [
                        .BG,
                        .clear
                    ], startPoint: .top, endPoint: .bottom))
                    .frame(height: 20)
            }
            .ignoresSafeArea()
        }
    }

    /// Week Row
    @ViewBuilder
    func WeekRow()->some View{
        HStack(spacing: 0){
            ForEach(Calendar.current.currentWeek){weekDay in
                let status = Calendar.current.isDate(weekDay.date, inSameDayAs: currentDay)
                VStack(spacing: 6){
                    Text(weekDay.string.prefix(3))
                        .font(.system(size: 14))
                        .fontWeight(.medium)
                    Text(weekDay.date.toString("dd"))
                        .font(.system(size: 18))
                        .fontWeight(status ? .medium : .regular)
                }
                .overlay(alignment: .bottom, content: {
                    if weekDay.isToday{
                        Circle()
                            .frame(width: 6, height: 6)
                            .offset(y: 12)
                    }
                })
                .foregroundColor(status ? Color(.faPurple) : .gray)
                .hAlign(.center)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)){
                        currentDay = weekDay.date
                    }
                }
            }
        }
        .padding(.vertical,10)
        .padding(.horizontal,-15)
    }
}

// Preview of the HomeView
#Preview {
    HomeView()
        .modelContainer(DataController.previewContainer)
}

// Extension to align view horizontally
extension View {
    func hAlign(_ alignment: Alignment)->some View{
        self
            .frame(maxWidth: .infinity,alignment: alignment)
    }

    // Extension to align view vertically
    func vAlign(_ alignment: Alignment)->some View{
        self
            .frame(maxHeight: .infinity,alignment: alignment)
    }
}
