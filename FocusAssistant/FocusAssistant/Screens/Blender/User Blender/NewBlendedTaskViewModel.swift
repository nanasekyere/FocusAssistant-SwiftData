//
//  
//  NewBlendedTaskViewModel.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 14/04/2024.
//
//

import Foundation
import Observation

@Observable class NewBlendedTaskViewModel {
    var taskName = ""
    var subtasks: [DummySubtask] = [DummySubtask(name: "")]

    func isComplete() -> Bool {
        let isTaskNameValid = taskName.count > 3
        let areSubtasksValid = subtasks.allSatisfy { subtask in
            subtask.name.count >= 3 && !subtask.details.isEmpty && subtask.details.allSatisfy { detail in
                detail.desc.count >= 5
            }
        }

        return isTaskNameValid && areSubtasksValid
    }
}
