//
//  
//  HomeViewModel.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 08/04/2024.
//
//

import Foundation
import Observation

@Observable class HomeViewModel {
    var isDisplayingAddView = false
    
    var taskDetails: UserTask?
    var taskToEdit: UserTask?
}
