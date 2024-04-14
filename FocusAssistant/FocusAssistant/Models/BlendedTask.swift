//
//  BlendedTask.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 08/04/2024.
//

import Foundation
import SwiftData

@Model class BlendedTask {
    var id = UUID()
    var name: String
    @Relationship(deleteRule: .cascade, inverse: \Subtask.blendedTask)
    var subtasks = [Subtask]()
    var isCompleted = false
    
    init(from dummyTask: DummyTask) {
        self.name = dummyTask.name
        self.subtasks = []
    }
    
    func toTask() -> UserTask {
        return UserTask(id: id, name: name, duration: 3, priority: .medium, pomodoro: true, pomodoroCounter: 0, blended: true)
    }
    
    
    init(name: String, subtasks: [Subtask]) {
        self.name = name
        self.subtasks = subtasks
    }
    
}

@Model class Subtask {
    var name: String
    @Relationship(deleteRule: .cascade, inverse: \Detail.subtask)
    var details = [Detail]()
    var blendedTask: BlendedTask?
    
    init(name: String, details: [Detail]) {
        self.name = name
        self.details = details
    }
    
    init(from dummySubtask: DummySubtask) {
        self.name = dummySubtask.name
        self.details = []
    }
    
}

@Model class Detail {
    var desc: String
    var isCompleted: Bool
    var subtask: Subtask?
    
    init(desc: String, isCompleted: Bool) {
        self.desc = desc
        self.isCompleted = isCompleted
    }
    
    init(from dummyDetail: DummyDetail) {
        self.desc = dummyDetail.desc
        self.isCompleted = dummyDetail.isCompleted
    }
}

struct DummyTask: Codable {
    var name: String
    var subtasks = [DummySubtask]()
    
    private enum CodingKeys: String, CodingKey {
        case name, subtasks
    }
    
    init(name: String, subtasks: [DummySubtask]) {
        self.name = name
        self.subtasks = subtasks
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        subtasks = try container.decodeIfPresent([DummySubtask].self, forKey: .subtasks) ?? []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(subtasks, forKey: .subtasks)
    }
    
    init(data: Data) throws {
        let me = try JSONDecoder().decode(DummyTask.self, from: data)
        self.init(name: me.name, subtasks: me.subtasks)
    }
    
    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }
}

struct DummySubtask: Codable {
    var name: String
    var details = [DummyDetail]()
    
    private enum CodingKeys: String, CodingKey {
        case name, details
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        details = try container.decodeIfPresent([DummyDetail].self, forKey: .details) ?? []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(details, forKey: .details)
    }
}

struct DummyDetail: Codable {
    var desc: String
    var isCompleted: Bool
    
    private enum CodingKeys: String, CodingKey {
        case desc
        case isCompleted
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        desc = try container.decode(String.self, forKey: .desc)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(desc, forKey: .desc)
        try container.encode(isCompleted, forKey: .isCompleted)
    }
}



