//
//  String+Ext.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 02/03/2024.
//

import Foundation

extension String {
    func trimWhiteSpace() -> String {
            return self.trimmingCharacters(in: .whitespacesAndNewlines)
        }
}

