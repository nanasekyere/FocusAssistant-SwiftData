//
//  BlendedTask.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 08/04/2024.
//

import Foundation
import SwiftData

@Model
class BlendedTask: Codable, Identifiable {
    var id = UUID()
    let name: String
    let subtasks: [Subtask]
    
    var task: UserTask {
        return UserTask(id: id, name: name, duration: 3, startTime: nil, priority: .medium, imageURL: "tornado", details: nil, pomodoro: true, pomodoroCounter: 0, blended: true)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, name, subtasks
    }
    
    // MARK: - Initializers
    
    init(name: String, subtasks: [Subtask]) {
        self.name = name
        self.subtasks = subtasks
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        subtasks = try container.decode([Subtask].self, forKey: .subtasks)
    }
    
    // MARK: - Convenience initializers
    
    convenience init(data: Data) throws {
        let decoder = newJSONDecoder()
        let decodedSelf = try decoder.decode(DecodedBlendedTask.self, from: data)
        var id = decodedSelf.id
        
        if id.isEmpty || UUID(uuidString: id) == nil {
            id = UUID().uuidString
        }
        
        self.init(name: decodedSelf.name, subtasks: decodedSelf.subtasks)
        self.id = UUID(uuidString: id) ?? UUID()
    }
    
    convenience init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }
    
    convenience init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }
    
    // MARK: - JSON Encoding/Decoding
    
    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }
    
    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
    
    func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(name, forKey: .name)
            try container.encode(subtasks, forKey: .subtasks)
        }
}

// MARK: - Subtask
struct Subtask: Codable, Identifiable, Hashable{
    var id = UUID()
    let name: String
    var details: [Detail]
    
    struct Detail: Codable, Identifiable, Hashable {
        var id = UUID()
        var description: String
        var isCompleted: Bool = false // Default value for isCompleted
        
        init(description: String) {
            self.description = description
        }
        
        mutating func toggleCompleted() {
            self.isCompleted.toggle()
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, name, details
    }
}


// MARK: Subtask convenience initializers and mutators

extension Subtask {
    
    init(data: Data) throws {
        let decoder = newJSONDecoder()
        let decodedSelf = try decoder.decode(DecodedSubtask.self, from: data)
        var id = decodedSelf.id
        
        // If id is empty or invalid, generate a new UUID
        if id.isEmpty || UUID(uuidString: id) == nil {
            id = UUID().uuidString
        }
        
        self.id = UUID(uuidString: id) ?? UUID() // Convert the id to UUID, or generate a new UUID if conversion fails
        self.name = decodedSelf.name
        self.details = decodedSelf.details
    }
    
    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }
    
    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }
    
    func jsonData() throws -> Data {
        return try JSONEncoder().encode(self)
    }
    
    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
    
    func with(
        name: String? = nil,
        details: [Detail]? = nil
    ) -> Subtask {
        return Subtask(
            name: name ?? self.name,
            details: details ?? self.details
        )
    }
}

extension Subtask {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        
        var detailsArray = try container.nestedUnkeyedContainer(forKey: .details)
        var details = [Detail]()
        
        while !detailsArray.isAtEnd {
            let detailString = try detailsArray.decode(String.self)
            let detail = Detail(description: detailString)
            details.append(detail)
        }
        
        self.details = details
    }
}

extension Subtask {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        
        var subtasksContainer = container.nestedUnkeyedContainer(forKey: .details)
        for detail in details {
            try subtasksContainer.encode(detail.description)
        }
    }
}

extension BlendedTask: Equatable {
    static func == (lhs: BlendedTask, rhs: BlendedTask) -> Bool {
        return lhs.name == rhs.name
    }
}

// Define a separate struct for decoding with a String id field
private struct DecodedBlendedTask: Codable {
    let id: String
    let name: String
    let subtasks: [Subtask]
}

private struct DecodedSubtask: Codable {
    let id: String
    let name: String
    let details: [Subtask.Detail]
}

// MARK: - Helper functions for creating encoders and decoders

func newJSONDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
        decoder.dateDecodingStrategy = .iso8601
    }
    return decoder
}

func newJSONEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
        encoder.dateEncodingStrategy = .iso8601
    }
    return encoder
}

var mockBlendedTask: BlendedTask = try! .init(serviceInfo.mockTask)
var mockBlendedTask2: BlendedTask = try! .init(serviceInfo.mockTask2)

var sampleBlendedTasks = [mockBlendedTask, mockBlendedTask2]
