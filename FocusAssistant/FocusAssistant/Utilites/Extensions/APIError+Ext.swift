//
//  APIError+Ext.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 17/05/2024.
//

import Foundation
import SwiftOpenAI

extension APIError: LocalizedError {
    public var localizedDescription: String {
        return self.displayDescription
    }

    public var errorDescription: String? {
        return self.displayDescription
    }
}
