//
//  Date+Ext.swift
//  Appetizers
//
//  Created by Nana Sekyere on 26/02/2024.
//

import Foundation

extension Date {
    func customFutureDate(daysAhead: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: daysAhead, to: Date())!
    }
    
    func toString(_ format: String)->String{
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
    
    func isDate(inRange startDate: Date, endDate: Date) -> Bool {
        return startDate <= self && self <= endDate
    }

    static func - (lhs: Date, rhs: Date) -> TimeInterval {
        return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
    }
}
