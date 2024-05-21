//
//  TaskViewModel.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 07/04/2024.
//

import SwiftUI
import Observation

// Observable class for managing task-related state and behavior
@Observable final class TaskViewModel {
    // State properties
    var isDisplayingAddView = false
    var isDisplayingMapper = false
    var isShowingCompleted = false
    var isShowingAllTasks = false
    var isShowingDailyTasks = false
    var isShowingWeeklyTasks = false
    var isShowingCompletedTasks = false
    var isShowingExpiredTasks = false
    var isShowingActiveView = false
    var isShowingBlendedTasks = true

    // Properties for task details and editing
    var taskDetail: UserTask?  // For displaying details of a specific task
    var taskToEdit: UserTask?   // For editing a specific task
    var bTaskDetail: BlendedTask? // For displaying details of a blended task

    // Enum to represent different task status
    var status = Status.showAll

}

// Enum to represent different task status options
enum Status {
    case showDaily, showWeekly, showAll
}
