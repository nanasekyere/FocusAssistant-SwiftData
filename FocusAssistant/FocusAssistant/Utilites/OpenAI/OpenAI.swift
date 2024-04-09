//
//  OpenAI.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 08/04/2024.
//

import Foundation

enum serviceInfo {
    static var APIKey: String {
        guard let filePath = Bundle.main.path(forResource: "OpenAI-Info", ofType: "plist")
        else {
            fatalError("Couldn't find file 'OpenAI-Info.plist'.")
        }
        let plist = NSDictionary(contentsOfFile: filePath)
        guard let value = plist?.object(forKey: "API_KEY") as? String else {
            fatalError("Couldn't find key 'API_KEY' in 'OpenAI-Info.plist'.")
        }
        if value.starts(with: "_") {
            fatalError(
                "Could not get key from plist"
            )
        }
        return value
    }
    static var mockTask: String {
        guard let filePath = Bundle.main.path(forResource: "OpenAI-Info", ofType: "plist")
        else {
            fatalError("Couldn't find file 'OpenAI-Info.plist'.")
        }
        let plist = NSDictionary(contentsOfFile: filePath)
        guard let value = plist?.object(forKey: "JSON") as? String else {
            fatalError("Couldn't find key 'JSON' in 'OpenAI-Info.plist'.")
        }
        if value.starts(with: "_") {
            fatalError(
                "Could not get key from plist for mockTask"
            )
        }
        return value
    }
    
    static var mockTask2: String {
        guard let filePath = Bundle.main.path(forResource: "OpenAI-Info", ofType: "plist")
        else {
            fatalError("Couldn't find file 'OpenAI-Info.plist'.")
        }
        let plist = NSDictionary(contentsOfFile: filePath)
        guard let value = plist?.object(forKey: "JSON2") as? String else {
            fatalError("Couldn't find key 'JSON2' in 'OpenAI-Info.plist'.")
        }
        if value.starts(with: "_") {
            fatalError(
                "Could not get key from plist for mockTask2"
            )
        }
        return value
    }
}
