//
//  ActiveTaskViewModel.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 03/03/2024.
//

import SwiftUI

@Observable final class ActiveTaskViewModel: NSObject, UNUserNotificationCenterDelegate {
    
    var progress = CGFloat(1)
    var timerStringValue = "00:00"
    var isStarted = false
    var addNewTimer = false
    var hour = 0
    var minutes = 0
    var seconds = 0
    var totalSeconds = 0
    var staticTotalSeconds = 0
    var isFinished = false
    var isBreak = false
    var alertMessage = ""
    var isShowing = false
    var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var activeTask: UserTask?
    
    init(activeTask: UserTask) {
        self.activeTask = activeTask
        super.init()
    }
    
    override init() {
        super.init()
        self.authorizeNotification()
    }
    
    func updateAlertMessage() {
        if let task = activeTask {
            if !task.pomodoro {
                alertMessage = "Task time for \(task.name) is finished."
            } else {
                if isBreak {
                    alertMessage = "Break time is finished."
                } else if task.isCompleted {
                    alertMessage = "You have completed the pomodoro cycles for task \(task.name)"
                } else { alertMessage = "Pomodoro cycle number \(task.pomodoroCounter! + 1) completed. Continue?" }
            }
        }
    }
    
    func authorizeNotification(){
        UNUserNotificationCenter.current().requestAuthorization(options: [.sound,.alert,.badge]) { _, _ in
        }
        UNUserNotificationCenter.current().delegate = self
    }
    
    func setActiveTask(_ task: UserTask) {
        self.activeTask = task
        self.hour = activeTask!.duration / 3600
        self.minutes = (activeTask!.duration / 60) % 60
        self.seconds = activeTask!.duration % 60
    }
    
    func startPomodoroBreak() {
        self.hour = 0
        self.minutes = 0
        self.seconds = 2
        
        startTimer()
    }
    
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.sound, .banner])
    }
    
    func startTimer() {
        withAnimation(.easeIn(duration: 0.25)) {
            isStarted = true
        }
        timerStringValue = "\(hour == 0 ? "" : "\(hour):") \(minutes >= 10 ? "\(minutes)" : "0\(minutes)"):\(seconds >= 10 ? "\(seconds)" : "0\(seconds)")"
        totalSeconds = (hour * 3600) + (minutes * 60) + seconds
        staticTotalSeconds = totalSeconds
        addNewTimer = false
        addNotification()
    }
    
    func stopTimer() {
        withAnimation {
            isStarted = false
            hour = 0
            minutes = 0
            seconds = 0
            progress = 1
        }
        totalSeconds = 0
        staticTotalSeconds = 0
        timerStringValue = "00:00"
        print("Timer finished")
    }
    
    func endTimer() {
        withAnimation {
            isStarted = false
            hour = 0
            minutes = 0
            seconds = 0
            progress = 1
        }
        totalSeconds = 0
        staticTotalSeconds = 0
        timerStringValue = "00:00"
        print("Timer stopped")
    }
    
    func updateTimer() {
        totalSeconds -= 1
        progress = CGFloat(totalSeconds) / CGFloat(staticTotalSeconds)
        progress = (progress < 0 ? 0 : progress)
        hour = totalSeconds / 3600
        minutes = (totalSeconds / 60) % 60
        seconds = (totalSeconds % 60)
        timerStringValue = "\(hour == 0 ? "" : "\(hour):") \(minutes >= 10 ? "\(minutes)" : "0\(minutes)"):\(seconds >= 10 ? "\(seconds)" : "0\(seconds)")"
        updateAlertMessage()
        if hour == 0 && seconds == 0 && minutes == 0 {
            isStarted = false
            isFinished = true
        }
    }
    
    
    func addNotification(){
        guard let task = self.activeTask else {
            print("There was an error setting notification for the task")
            return
        }
        
        if task.pomodoro {
            let content = UNMutableNotificationContent()
            content.title = isBreak ? "Break Timer" : "Task Timer"
            content.subtitle = isBreak ? "Break time for \(task.name) finished" : "Task time for task \(task.name) finished"
            content.sound = UNNotificationSound.default
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(staticTotalSeconds), repeats: false))
            
            UNUserNotificationCenter.current().add(request)
        } else {
            let content = UNMutableNotificationContent()
            content.title = "Task Timer"
            content.subtitle = "Task time for task \(task.name) finished"
            content.sound = UNNotificationSound.default
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(staticTotalSeconds), repeats: false))
            
            UNUserNotificationCenter.current().add(request)
        }
        
    }
    
    
}
