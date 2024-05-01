//
//  UserTask.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 07/04/2024.
//

import Foundation
import SwiftData
import UserNotifications

@Model
class UserTask {
    var identity = UUID()

    var name = ""
    var duration: Int = 0
    var startTime: Date?
    var priority: Priority = Priority.low
    var imageURL: String?
    var details: String?
    var pomodoro = false
    var isCompleted = false
    var pomodoroCounter: Int?
    var isExpired = false
    var isRecurring = false
    var repeatEvery: Int? = nil

    var blendedTask: BlendedTask?

    func increaseCounter() {
        if pomodoro {
            pomodoroCounter! += 1
            print("incremented")
            
            if pomodoroCounter == 4 {
                isCompleted = true
            }
        }
    }

    func completeTask() {
        if self.isRecurring, let startTime = self.startTime, let repeatEvery = self.repeatEvery {
            self.startTime = Date(timeInterval: TimeInterval(repeatEvery), since: startTime)
        } else {
            self.isCompleted = true
        }
    }

    init(name: String = "", duration: Int = 0, startTime: Date? = nil, priority: Priority = .low, 
         imageURL: String? = nil, details: String? = nil, pomodoro: Bool = false,  pomodoroCounter: Int? = nil, isRecurring: Bool = false, repeatEvery: Int? = nil) {
        self.name = name
        self.duration = duration
        self.startTime = startTime
        self.priority = priority
        self.imageURL = imageURL
        self.details = details
        self.pomodoro = pomodoro
        self.pomodoroCounter = pomodoroCounter
        self.isRecurring = isRecurring
        self.repeatEvery = repeatEvery
    }
    
    init(identity: UUID, name: String = "", duration: Int = 0, startTime: Date? = nil, priority: Priority = .low,
         imageURL: String? = nil, details: String? = nil, pomodoro: Bool = false,  pomodoroCounter: Int? = nil, blendedTask: BlendedTask? = nil) {
        self.identity = identity
        self.name = name
        self.duration = duration
        self.startTime = startTime
        self.priority = priority
        self.imageURL = imageURL
        self.details = details
        self.pomodoro = pomodoro
        self.pomodoroCounter = pomodoroCounter
        self.blendedTask = blendedTask
    }
    
    func scheduleNotification() {
        guard !self.pomodoro, let startTime = self.startTime, startTime > Date() else { return }
        
        if self.priority == .high {
            scheduleHighPriorityNotification()
        }

        let timeDifference = startTime.timeIntervalSinceNow
        guard timeDifference >= 300 else {
            // If the start time is less than 5 minutes away, don't schedule the notification
            return
        }
        
        let notificationTime = startTime.addingTimeInterval(-300) // 5 minutes before start time
        let content = UNMutableNotificationContent()
        content.title = "Task Reminder"
        content.body = "Your task \(self.name) is starting in 5 minutes!"
        content.sound = UNNotificationSound.default
        content.interruptionLevel = .timeSensitive
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: notificationTime.timeIntervalSinceNow, repeats: false)
        
        let request = UNNotificationRequest(identifier: self.identity.uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled for task \(self.name) at \(notificationTime.formatted(date: .omitted, time: .shortened))")
            }
        }
    }

    func scheduleHighPriorityNotification() {
        guard !self.pomodoro, self.priority == .high, let startTime = self.startTime, startTime > Date() else { return }

        let notificationTime = startTime
        let content = UNMutableNotificationContent()
        content.title = "Task Starting"
        content.body = "Your task \(self.name) is starting now!"
        content.sound = UNNotificationSound.default
        content.interruptionLevel = .timeSensitive

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: notificationTime.timeIntervalSinceNow, repeats: false)

        let request = UNNotificationRequest(identifier: self.identity.uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled for task \(self.name) at \(notificationTime.formatted(date: .omitted, time: .shortened))")
            }
        }
    }

    func descheduleNotification() {
            let notificationCenter = UNUserNotificationCenter.current()
            
            // Remove the notification request associated with the task ID
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [self.identity.uuidString])
        }
}

enum Priority: String, CaseIterable, Codable {
    case low, medium, high
}

//Samples
var sampleTasks: [UserTask] = [ UserTask(name: "Brush Teeth", duration: 120, startTime: Date.now.customFutureDate(daysAhead: 2), priority: .medium, imageURL: "drop.fill"),
                                           UserTask(name: "Shower", duration: 300, startTime: Date.now.customFutureDate(daysAhead: 1), priority: .medium, imageURL: "shower.fill"),
                                           mockPomodoroTask,
                                           UserTask(name: "Clean Desk", duration: 120, startTime: Date.now.customFutureDate(daysAhead: 3), priority: .medium, imageURL: "drop.fill"),
                                           UserTask(name: "Shower", duration: 300, startTime: Date.now.customFutureDate(daysAhead: 4), priority: .medium, imageURL: "shower.fill"),

                                           UserTask(name: "Brush Teeth", duration: 120, startTime: Date.now, priority: .medium, imageURL: "drop.fill"),
                                           UserTask(name: "Shower", duration: 300, startTime: Date.now.customFutureDate(daysAhead: 6), priority: .medium, imageURL: "shower.fill"),
                                           mockPomodoroTask,
                                           UserTask(name: "Brush Teeth", duration: 120, startTime: Date.now.customFutureDate(daysAhead: 7), priority: .medium, imageURL: "drop.fill"),
                                           UserTask(name: "Shower", duration: 300, startTime: Date.now, priority: .high, imageURL: "shower.fill"),
                                           mockPomodoroTask
]

var mockTask = UserTask(name: "Clean Desk", duration: 120, startTime: Date.now.customFutureDate(daysAhead: 3), priority: .medium, imageURL: "drop.fill")

var mockPomodoroTask = UserTask(name: "Work on assignment", priority: .medium, imageURL: "book.pages.fill", details: "Don't forget to save file after each change you make in the IDE", pomodoro: true, pomodoroCounter: 0)
