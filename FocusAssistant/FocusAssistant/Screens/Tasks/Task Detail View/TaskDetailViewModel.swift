//
//  TaskDetailViewModel.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 07/04/2024.
//

import Foundation

@Observable final class TaskDetailViewModel {

    var isDisplayingActiveTask = false
    var selectedTask: UserTask?
    var isDisplayingContext = false
    var taskToActivate: UserTask?
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
        
}
