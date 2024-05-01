//
//  Optional+Ext.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 01/03/2024.
//

import Foundation

extension Optional where Wrapped == String {
    var _bound: String? {
        get {
            return self
        }
        set {
            self = newValue
        }
    }
    public var bound: String {
        get {
            return _bound ?? ""
        }
        set {
            _bound = newValue.isEmpty ? nil : newValue
        }
    }
}

extension Optional where Wrapped == Date {
    var _bound: Date? {
        get {
            return self
        }
        set {
            self = newValue
        }
    }
    public var bound: Date {
        get {
            return _bound ?? Date()
        }
        set {
            _bound = newValue == Date() ? nil : newValue
        }
    }
}

extension Optional where Wrapped == Int {
    var _bound: Int? {
        get {
            return self
        }
        set {
            self = newValue
        }
    }
    public var bound: Int {
        get {
            return _bound ?? 0
        }
        set {
            _bound = newValue == 0 ? nil : newValue
        }
    }
}





