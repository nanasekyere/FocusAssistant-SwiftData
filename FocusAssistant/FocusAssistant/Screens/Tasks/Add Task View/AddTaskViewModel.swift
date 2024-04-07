//
//  
//  AddTaskViewModel.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 07/04/2024.
//
//

import Foundation
import Observation

@Observable class AddTaskViewModel {
    var name = ""
    var duration: Int = 0
    var startTime: Date?
    var priority: Priority = Priority.low
    var imageURL: String?
    var details: String?
    var pomodoro = false
    var isExpired = false
    var pomodoroCounter: Int?
    var isShowingIconPicker = false
    var showDurationPicker = false
    
    var isComplete: Bool {
        if pomodoro { return name != "" && name != " "} else { return name != "" && name != " " && duration > 0 && startTime != nil }
    }
}
