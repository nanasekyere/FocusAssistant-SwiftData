//
//  UserDefaults+Ext.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 02/03/2024.
//

import Foundation

extension UserDefaults {
    
    func resetUser(){
        removeObject(forKey: "user")
    }
}
