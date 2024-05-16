//
//  TaskDetailViewModel.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 07/04/2024.
//

import Foundation

// ViewModel class for TaskDetailView
@Observable final class TaskDetailViewModel {

    // State variables
    var isDisplayingActiveTask = false // Flag to indicate whether an active task is being displayed
    var selectedTask: UserTask? // Selected task to display details
    var isDisplayingContext = false // Flag to indicate whether task start context is being displayed
    var taskToActivate: UserTask? // Task to activate (start)

    // Computed property to determine the task start context message based on priority
    var taskStartContext: String? {
        if let task = selectedTask {
            if task.priority == .medium {
                return "Medium priority tasks can only be started 10 minutes before or after their start time"
            }

            if task.priority == .high {
                return "High priority tasks start automatically at their start time"
            }

            if task.priority == .low {
                return nil
            }
        }
        return nil
    }

    // Flag to display an alert when attempting to start a task while another task is active
    var showAlert = false
}
