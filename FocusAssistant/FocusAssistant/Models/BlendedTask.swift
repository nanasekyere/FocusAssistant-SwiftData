//
//  BlendedTask.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 08/04/2024.
//

import Foundation
import SwiftData

/// Represents a blended task containing multiple subtasks.
@Model class BlendedTask {
    var identity = UUID() // Unique identifier for the task
    var name: String // Name of the blended task

    // Relationship to subtasks with cascade delete rule
    @Relationship(deleteRule: .cascade, inverse: \Subtask.blendedTask)
    var subtasks = [Subtask]()

    // Computed property to get sorted subtasks by index
    var sortedSubtasks: [Subtask] {
        return subtasks.sorted(by: { $0.index < $1.index })
    }

    // Relationship to the corresponding UserTask with cascade delete rule
    @Relationship(deleteRule: .cascade, inverse: \UserTask.blendedTask)
    var correspondingTask: UserTask?

    // Initializer to create a BlendedTask from a DummyTask
    init(from dummyTask: DummyTask) {
        self.name = dummyTask.name
        self.subtasks = []
    }

    // Function to convert BlendedTask to a UserTask
    func toTask() -> UserTask {
        return UserTask(identity: identity, name: name, duration: UserDefaults.standard.integer(forKey: "taskTime"), priority: .medium, pomodoro: true, pomodoroCounter: 0, blendedTask: self)
    }

    // Initializer to create a BlendedTask with a name and subtasks
    init(name: String, subtasks: [Subtask]) {
        self.name = name
        self.subtasks = subtasks
    }
}

/// Represents a subtask within a blended task.
@Model class Subtask {
    var name: String // Name of the subtask

    // Relationship to details with cascade delete rule
    @Relationship(deleteRule: .cascade, inverse: \Detail.subtask)
    var details = [Detail]()

    // Computed property to get sorted details by index
    var sortedDetails: [Detail] {
        return details.sorted(by: { $0.index < $1.index })
    }

    var index: Int // Index of the subtask in the parent BlendedTask
    var blendedTask: BlendedTask? // Reference to the parent BlendedTask

    // Initializer to create a Subtask with name, details, and index
    init(name: String, details: [Detail], index: Int) {
        self.name = name
        self.details = details
        self.index = index
    }

    // Initializer to create a Subtask from a DummySubtask
    init(from dummySubtask: DummySubtask, index: Int) {
        self.name = dummySubtask.name
        self.details = []
        self.index = index
    }
}

/// Represents a detail within a subtask.
@Model class Detail {
    var desc: String // Description of the detail
    var isCompleted: Bool // Flag to indicate if the detail is completed
    var subtask: Subtask? // Reference to the parent Subtask
    var index: Int = 0 // Index of the detail in the parent Subtask

    // Initializer to create a Detail with description, completion status, and index
    init(desc: String, isCompleted: Bool, index: Int) {
        self.desc = desc
        self.isCompleted = isCompleted
        self.index = index
    }

    // Initializer to create a Detail from a DummyDetail
    init(from dummyDetail: DummyDetail, index: Int) {
        self.desc = dummyDetail.desc
        self.isCompleted = dummyDetail.isCompleted
        self.index = index
    }
}

/// Codable struct to represent a dummy task with a name and subtasks.
struct DummyTask: Codable {
    var name: String
    var subtasks = [DummySubtask]()

    private enum CodingKeys: String, CodingKey {
        case name, subtasks
    }

    // Initializer for creating a DummyTask
    init(name: String, subtasks: [DummySubtask]) {
        self.name = name
        self.subtasks = subtasks
    }

    // Initializer to decode a DummyTask from JSON
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        subtasks = try container.decodeIfPresent([DummySubtask].self, forKey: .subtasks) ?? []
    }

    // Function to encode a DummyTask to JSON
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(subtasks, forKey: .subtasks)
    }

    // Initializer to create a DummyTask from Data
    init(data: Data) throws {
        let me = try JSONDecoder().decode(DummyTask.self, from: data)
        self.init(name: me.name, subtasks: me.subtasks)
    }

    // Initializer to create a DummyTask from a JSON string
    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }
}

/// Codable struct to represent a dummy subtask with a name and details.
struct DummySubtask: Codable, Hashable {
    var name: String
    var details = [DummyDetail]()

    // Initializer for creating a DummySubtask
    init(name: String) {
        self.name = name
        self.details = []
    }

    private enum CodingKeys: String, CodingKey {
        case name, details
    }

    // Initializer to decode a DummySubtask from JSON
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        details = try container.decodeIfPresent([DummyDetail].self, forKey: .details) ?? []
    }

    // Function to encode a DummySubtask to JSON
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(details, forKey: .details)
    }

    // Equatable conformance to compare two DummySubtasks
    static func == (lhs: DummySubtask, rhs: DummySubtask) -> Bool {
        return lhs.name == rhs.name && lhs.details == rhs.details
    }

    // Hashable conformance to hash a DummySubtask
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(details)
    }
}

/// Codable struct to represent a dummy detail with a description and completion status.
struct DummyDetail: Codable, Equatable, Hashable {
    var desc: String
    var isCompleted: Bool

    // Initializer for creating a DummyDetail
    init(desc: String) {
        self.desc = desc
        self.isCompleted = false
    }

    private enum CodingKeys: String, CodingKey {
        case desc
        case isCompleted
    }

    // Initializer to decode a DummyDetail from JSON
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        desc = try container.decode(String.self, forKey: .desc)
        isCompleted = false
    }

    // Function to encode a DummyDetail to JSON
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(desc, forKey: .desc)
        try container.encode(isCompleted, forKey: .isCompleted)
    }

    // Equatable conformance to compare two DummyDetails
    static func == (lhs: DummyDetail, rhs: DummyDetail) -> Bool {
        return lhs.desc == rhs.desc && lhs.isCompleted == rhs.isCompleted
    }

    // Hashable conformance to hash a DummyDetail
    func hash(into hasher: inout Hasher) {
        hasher.combine(desc)
        hasher.combine(isCompleted)
    }
}
