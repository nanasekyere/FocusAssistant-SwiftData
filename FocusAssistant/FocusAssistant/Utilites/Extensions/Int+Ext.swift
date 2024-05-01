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

    func recurringTimeString() -> String {
            let minutes = self / 60
            let hours = minutes / 60
            let days = hours / 24

            let remainingHours = hours % 24
            let remainingMinutes = minutes % 60

            var timeString = ""

            if days > 0 {
                timeString += "\(days) day\(days == 1 ? "" : "s") "
            }

            if remainingHours > 0 {
                timeString += "\(remainingHours) hour\(remainingHours == 1 ? "" : "s") "
            }

            if remainingMinutes > 0 || timeString.isEmpty { // Add minutes or default to "0 minutes" if the string is still empty
                timeString += "\(remainingMinutes) minute\(remainingMinutes == 1 ? "" : "s")"
            }

            return timeString
        }
}
