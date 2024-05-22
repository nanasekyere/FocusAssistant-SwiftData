//
// ActiveTaskViewModel.swift
// FocusAssistant
//
// Created by Nana Sekyere on 03/03/2024.
//

import SwiftUI

// ViewModel responsible for managing active tasks and timers. This view model is accessed in @main
@Observable public final class ActiveTaskViewModel: NSObject, UNUserNotificationCenterDelegate {

    // MARK: - Properties

    // Progress of the timer
    var progress = CGFloat(1)
    // String value of the timer
    var timerStringValue = "00:00"
    // Flag to indicate if the timer is started
    var isStarted = false
    // Flag to indicate if a new timer is being added
    var addNewTimer = false
    // Hours component of the timer
    var hour = 0
    // Minutes component of the timer
    var minutes = 0
    // Seconds component of the timer
    var seconds = 0
    // Total seconds of the timer
    var totalSeconds = 0
    // Static total seconds of the timer
    var staticTotalSeconds = 0
    // Flag to indicate if the timer is finished
    var isFinished = false
    // Flag to indicate if it's break time
    var isBreak = false
    // Alert message to display when timer finishes
    var alertMessage = ""
    // Flag to indicate if the view is currently showing
    var isShowing = false
    // Timer instance
    var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // Active task being managed
    var activeTask: UserTask?
    
    init(activeTask: UserTask) {
        self.activeTask = activeTask
        super.init()
    }
    
    override init() {
        super.init()
        // Request authorization for notifications
        self.authorizeNotification()
    }


    // Update the alert message based on the active task.
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

    // Request authorization for notifications.
    func authorizeNotification(){
        UNUserNotificationCenter.current().requestAuthorization(options: [.sound,.alert,.badge]) { _, _ in
        }
        UNUserNotificationCenter.current().delegate = self
    }

    // Set the active task and update timer components based on task duration.
    func setActiveTask(_ task: UserTask) {
        self.activeTask = task
        self.hour = activeTask!.duration / 3600
        self.minutes = (activeTask!.duration / 60) % 60
        self.seconds = activeTask!.duration % 60
    }

    // Start a break timer.
    func startPomodoroBreak() {
        self.hour = 0
        self.minutes = (UserDefaults.standard.integer(forKey: "breakTime") / 60) % 60
        self.seconds = 0

        startTimer()
    }

    // Handle notification presentation.
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.sound, .banner])
    }

    // Start the timer.
    func startTimer() {
        isFinished = false
        withAnimation(.easeIn(duration: 0.25)) {
            isStarted = true
        }
        timerStringValue = "\(hour == 0 ? "" : "\(hour):") \(minutes >= 10 ? "\(minutes)" : "0\(minutes)"):\(seconds >= 10 ? "\(seconds)" : "0\(seconds)")"
        totalSeconds = (hour * 3600) + (minutes * 60) + seconds
        staticTotalSeconds = totalSeconds
        addNewTimer = false
        addNotification()
    }

    // Start an in-progress task timer.
    func startInProgress(_ task: UserTask) {
        guard !task.pomodoro, let startTime = task.startTime else { return }

        self.activeTask = task

        let endTime = startTime.addingTimeInterval(Double(task.duration))
        let remainingDuration = Int(endTime - Date.now)

        self.hour = remainingDuration / 3600
        self.minutes = (remainingDuration / 60)  % 60
        self.seconds = remainingDuration % 60

        startTimer()
    }

    // Stop the timer.
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

    // End the timer.
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

    // Update the timer.
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

    // Add notification for the timer.
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
            content.interruptionLevel = .timeSensitive

            let request = UNNotificationRequest(identifier: task.identity.uuidString, content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(staticTotalSeconds), repeats: false))

            UNUserNotificationCenter.current().add(request)
        }

    }
}
