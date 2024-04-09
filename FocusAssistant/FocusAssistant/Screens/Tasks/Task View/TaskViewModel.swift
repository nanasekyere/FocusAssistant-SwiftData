//
//  TaskViewModel.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 07/04/2024.
//

import SwiftUI
import Observation

@Observable final class TaskViewModel {
    var isDisplayingAddView = false
    var isShowingCompleted = false
    var isShowingAllTasks = false
    var isShowingDailyTasks = false
    var isShowingWeeklyTasks = false
    var isShowingCompletedTasks = false
    var isShowingExpiredTasks = false
    var isShowingActiveView = false
    var isShowingBlendedTasks = true
    
    var taskDetail: UserTask?
    var taskToEdit: UserTask?

    var status = Status.showAll
    
}

enum Status {
    case showDaily, showWeekly, showAll
}
