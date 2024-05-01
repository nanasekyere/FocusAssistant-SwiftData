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
    var isRecurring = false
    var repeatEvery: Int?
    var pomodoroCounter: Int?
    var showClashAlert = false
    var clashingTask: UserTask?

    var isShowingIconPicker = false
    var showDurationPicker = false
    var showRepetitionPicker = false

    var isComplete: Bool {
        if pomodoro {
            return name != "" && name != " "
        } else if isRecurring {
            return name != "" && name != " " && duration > 0 && startTime != nil && repeatEvery != nil
        } else {
            return name != "" && name != " " && duration > 0 && startTime != nil
        }
    }

}
