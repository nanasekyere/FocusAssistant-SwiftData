//
//  UserTask.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 07/04/2024.
//

import Foundation
import SwiftData

@Model
final class UserTask {
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
    private(set) var blended: Bool = false
    
    func increaseCounter() {
        if pomodoro {
            pomodoroCounter! += 1
            print("incremented")
            
            if pomodoroCounter == 4 {
                isCompleted = true
            }
        }
    }
    
    init(name: String = "", duration: Int = 0, startTime: Date? = nil, priority: Priority = .low, imageURL: String? = nil, details: String? = nil, pomodoro: Bool = false,  pomodoroCounter: Int? = nil) {
        self.name = name
        self.duration = duration
        self.startTime = startTime
        self.priority = priority
        self.imageURL = imageURL
        self.details = details
        self.pomodoro = pomodoro
        self.pomodoroCounter = pomodoroCounter
    }
}

enum Priority: String, CaseIterable, Codable {
    case low, medium, high
}

//Samples
var sampleTasks: [UserTask] = [ UserTask(name: "Brush Teeth", duration: 12, startTime: Date.now.customFutureDate(daysAhead: 2), priority: .medium, imageURL: "drop.fill"),
                                           UserTask(name: "Shower", duration: 30, startTime: Date.now.customFutureDate(daysAhead: 1), priority: .medium, imageURL: "shower.fill"),
                                           mockPomodoroTask,
                                           UserTask(name: "Brush Teeth", duration: 12, startTime: Date.now.customFutureDate(daysAhead: 3), priority: .medium, imageURL: "drop.fill"),
                                           UserTask(name: "Shower", duration: 30, startTime: Date.now.customFutureDate(daysAhead: 4), priority: .medium, imageURL: "shower.fill"),
                                        
                                           UserTask(name: "Brush Teeth", duration: 12, startTime: Date.now, priority: .medium, imageURL: "drop.fill"),
                                           UserTask(name: "Shower", duration: 30, startTime: Date.now.customFutureDate(daysAhead: 6), priority: .medium, imageURL: "shower.fill"),
                                           mockPomodoroTask,
                                           UserTask(name: "Brush Teeth", duration: 12, startTime: Date.now.customFutureDate(daysAhead: 7), priority: .medium, imageURL: "drop.fill"),
                                           UserTask(name: "Shower", duration: 30, startTime: Date.now, priority: .high, imageURL: "shower.fill"),
                                           mockPomodoroTask
]

var mockTask = UserTask(name: "Shower", duration: 30, startTime: Date.now.customFutureDate(daysAhead: 2), priority: .high, imageURL: "shower.fill", details: "Don't forget to put the shampoo back in the cabinet. Remember to clean sink after brushing teeth")

var mockPomodoroTask = UserTask(name: "Work on assignment", priority: .medium, imageURL: "book.pages.fill", details: "Don't forget to save file after each change you make in the IDE", pomodoro: true, pomodoroCounter: 0)
