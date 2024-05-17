//
//  OpenAI.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 08/04/2024.
//

import Foundation
import SwiftOpenAI

enum serviceInfo {
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

/// Service for interacting with the OpenAI API.
var APIService: OpenAIService {
    #if DEBUG && targetEnvironment(simulator)
    return OpenAIServiceFactory.service(
        aiproxyPartialKey: "v1|3af3250e|1|ihchDO25XUMdu1zc",
        aiproxyDeviceCheckBypass: "4832550d-b2c7-43fa-a16b-512f0072fd9e"
    )
    #else
    return OpenAIServiceFactory.service(
        aiproxyPartialKey: "v1|3af3250e|1|ihchDO25XUMdu1zc"
    )
    #endif
}
