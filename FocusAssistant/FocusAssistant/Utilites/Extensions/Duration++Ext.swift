//
//  Duration++Ext.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 27/02/2024.
//

import Foundation

extension Duration {
    var toString: String {
        self.formatted(.units(allowed: [.hours, .minutes, .seconds]))
    }
    
    func isEmpty() -> Bool {
        if self.components.seconds > 0 {
            return false
        } else { return true }
    }
}
