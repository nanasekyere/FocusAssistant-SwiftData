//
// NewBlendedTaskViewModel.swift
// FocusAssistant
//
// Created by Nana Sekyere on 14/04/2024.
//

import Foundation
import Observation

// View model for creating a new blended task.
@Observable class NewBlendedTaskViewModel {
    var taskName = "" // Name of the task
    var subtasks: [DummySubtask] = [DummySubtask(name: "")] // List of subtasks

    // Checks if all required fields are complete.
    func isComplete() -> Bool {
        // Check if task name is valid
        let isTaskNameValid = taskName.count > 3
        // Check if all subtasks are valid
        let areSubtasksValid = subtasks.allSatisfy { subtask in
            // Check if subtask name is valid and if all details are valid
            subtask.name.count >= 3 && !subtask.details.isEmpty && subtask.details.allSatisfy { detail in
                detail.desc.count >= 5
            }
        }

        // Return true if both task name and subtasks are valid
        return isTaskNameValid && areSubtasksValid
    }
}
