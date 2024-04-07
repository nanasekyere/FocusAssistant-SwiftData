//
//  ActiveTaskView.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 07/04/2024.
//

import SwiftUI
import AVFoundation
import SwiftData

struct ActiveTaskView: View {
    @Query var tasks: [UserTask]
    @EnvironmentObject var vm: ActiveTaskViewModel
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var task: UserTask
    @State var isBreak: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Text(task.name)
                    .font(.title2.bold())
                
                GeometryReader { proxy in
                    VStack(spacing: 15) {
                        ZStack{
                            Circle()
                                .fill(.white.opacity(0.03))
                                .padding(-40)
                            
                            Circle()
                                .trim(from: 0, to: vm.progress)
                                .stroke(.white.opacity(0.03), lineWidth: 80)
                            
                            Circle()
                                .stroke(Color(.faPurple), lineWidth: 5)
                                .blur(radius: 15)
                                .padding(-2)
                            
                            Circle()
                                .fill(Color(.BG))
                            
                            Circle()
                                .trim(from: 0, to: vm.progress)
                                .stroke(Color(.faPurple).opacity(0.7), lineWidth: 10)
                            
                            GeometryReader { proxy in
                                let size = proxy.size
                                
                                Circle()
                                    .fill(Color(.faPurple))
                                    .frame(width: 30, height: 30)
                                    .overlay(content: {
                                        Circle()
                                            .fill(Color.white)
                                            .padding(5)
                                    })
                                    .frame(width: size.width, height: size.height, alignment: .center)
                                    .offset(x: size.height /  2)
                                    .rotationEffect(.init(degrees: vm.progress * 360))
                            }
                            
                            Text(vm.timerStringValue)
                                .font(.system(size: 45, weight: .light))
                                .rotationEffect(.init(degrees: 90))
                                .animation(.none, value: vm.progress)
                            
                            
                        }
                        .padding(60)
                        .frame(height: proxy.size.width)
                        .rotationEffect(.init(degrees: -90))
                        .animation(.easeInOut, value: vm.progress)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        
                        Button {
                            if vm.isStarted {
                                vm.stopTimer()
                                UNUserNotificationCenter.current()
                                    .removeAllPendingNotificationRequests()
                            } else {
                                if vm.activeTask == nil {
                                    vm.setActiveTask(task)
                                    vm.startTimer()
                                } else { vm.addNewTimer = true }
                            }
                        } label: {
                            Image(systemName: !vm.isStarted ? "timer" : "stop.fill")
                                .font(.largeTitle.bold())
                                .foregroundStyle(Color.white)
                                .frame(width: 80, height: 80)
                                .background {
                                    Circle()
                                        .fill(Color.faPurple)
                                }
                                .shadow(color: .faPurple, radius: 8, x: 0, y: 0)
                        }
                        
                    }
                    .onTapGesture(perform: {
                        vm.progress = 0.5
                    })
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Back") {
                            dismiss()
                        }
                    }
                }
            }
            .background(.BG)
        }
        
        .padding()
        .background(.BG)
        .overlay(content: {
            ZStack {
                Color.black
                    .opacity(vm.addNewTimer ? 0.25 : 0)
                    .onTapGesture {
                        vm.hour = 0
                        vm.minutes = 0
                        vm.seconds = 0
                        vm.addNewTimer = false
                    }
                NewTimerView()
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .offset(y: vm.addNewTimer ? 0 : 400)
            }
            .animation(.easeInOut, value: vm.addNewTimer)
        })
        .onAppear {
            vm.isShowing = true
        }
        .onDisappear {
            vm.isShowing = false
        }
        .onReceive(vm.timer) { _ in
            if vm.isStarted {
                vm.updateTimer()
            }
        }
        
        .onChange(of: vm.isFinished) { oldValue, newValue in
            if newValue == true && !vm.isBreak {
                task.increaseCounter()
            }
        }
        .alert(vm.alertMessage, isPresented: $vm.isFinished) {
            if task.pomodoro {
                if shouldStartBreak() {
                    startBreakButtons()
                } else if vm.isBreak {
                    startTaskButtons()
                } else {
                    completeTaskButton()
                }
            } else {
                startNewTaskButtons()
            }
        }
    }
    
    func shouldStartBreak() -> Bool {
        return task.pomodoroCounter! < 4 && !vm.isBreak
    }
    
    @ViewBuilder
    func NewTimerView() -> some View {
        VStack(spacing: 15){
            Text("A New Timer")
                .font(.title2.bold())
                .foregroundStyle(Color.white)
                .padding(.top, 10)
            
            HStack(spacing: 15) {
                
                Menu {
                    ContextMenuOptions(maxValue: 12, hint: "hr") { value in
                        vm.hour = value
                    }
                } label: {
                    Text("\(vm.hour) hr")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.white.opacity(0.3))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background{
                            Capsule()
                                .fill(.white.opacity(0.07))
                        }
                }
                
                Menu {
                    ContextMenuOptions(maxValue: 60, hint: "min") { value in
                        vm.minutes = value
                    }
                } label: {
                    Text("\(vm.minutes) min")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.white.opacity(0.3))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background{
                            Capsule()
                                .fill(.white.opacity(0.07))
                        }
                }
                
                Menu {
                    ContextMenuOptions(maxValue: 60, hint: "sec") { value in
                        vm.seconds = value
                    }
                } label: {
                    Text("\(vm.seconds) sec")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.white.opacity(0.3))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background{
                            Capsule()
                                .fill(.white.opacity(0.07))
                        }
                }
                
            }
            .padding(.top, 20)
            
            Button {
                vm.startTimer()
            } label: {
                Text("Save")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background{
                        Capsule()
                            .fill(Color.faPurple)
                    }
            }
            .disabled(vm.seconds == 0 && vm.minutes == 0 && vm.hour == 0)
            .opacity(vm.seconds == 0 && vm.minutes == 0 && vm.hour == 0 ? 0.5 : 1)
            .padding(.top)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.BG)
                .ignoresSafeArea()
        }
        
        
        
    }
    
    @ViewBuilder
    func ContextMenuOptions(maxValue: Int, hint: String, onClick: @escaping (Int)->()) -> some View {
        
        ForEach(0...maxValue,id: \.self){ value in
            Button("\(value) \(hint)"){
                onClick(value)
            }
        }
    }
    
    
    
    func startBreakButtons() -> some View {
        Group {
            Button("Start Break", role: .cancel) {
                vm.isBreak = true
                vm.startPomodoroBreak()
            }
            Button("Close", role: .destructive) {
                vm.endTimer()
                dismiss()
            }
            Button("Complete task", role: .destructive) {
                vm.endTimer()
                task.isCompleted = true
                dismiss()
            }
        }
    }
    
    func startTaskButtons() -> some View {
        Group {
            Button("Start Task", role: .cancel) {
                vm.isBreak = false
                vm.setActiveTask(task)
                vm.startTimer()
            }
            Button("Close", role: .destructive) {
                vm.endTimer()
                dismiss()
            }
        }
    }
    
    func completeTaskButton() -> some View {
        Button("Complete task", role: .destructive) {
            vm.endTimer()
            task.isCompleted = true
            vm.activeTask = nil
            dismiss()
        }
    }
    
    func startNewTaskButtons() -> some View {
        Group {
            Button("Start New", role: .cancel) {
                vm.endTimer()
                vm.addNewTimer = true
            }
            Button("Close", role: .destructive) {
                vm.endTimer()
                task.isCompleted = true
                dismiss()
            }
        }
    }
    
    
}

#Preview {
    ActiveTaskView(task: mockTask)
        .modelContainer(for: UserTask.self, inMemory: true)
        .environmentObject(ActiveTaskViewModel())
}
