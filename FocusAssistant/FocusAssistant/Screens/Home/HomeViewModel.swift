//
//  HomeViewModel.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 08/04/2024.
//
//

import Foundation
import Observation

// Observable class for managing home view state
@Observable class HomeViewModel {
    // Flag for indicating whether the add task view is displayed
    var isDisplayingAddView = false

    // Optional user task for displaying task details
    var taskDetails: UserTask?

    // Optional user task for editing tasks
    var taskToEdit: UserTask?
}
