//
//  Int+Ext.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 07/04/2024.
//

import Foundation

extension Int {
    
    func timeString() -> String {
        let hours = self / 3600
        let remainingSecondsAfterHours = self % 3600
        let minutes = remainingSecondsAfterHours / 60
        let remainingSeconds = remainingSecondsAfterHours % 60
        
        var timeString = ""
        
        if hours > 0 {
            timeString += "\(hours) hour\(hours == 1 ? "" : "s") "
        }
        
        if minutes > 0 {
            timeString += "\(minutes) minute\(minutes == 1 ? "" : "s") "
        }
        
        if remainingSeconds > 0 || timeString.isEmpty {
            timeString += "\(remainingSeconds) second\(remainingSeconds == 1 ? "" : "s")"
        }
        
        return timeString
    }
}
