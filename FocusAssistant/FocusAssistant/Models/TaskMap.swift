//
//  TaskMap.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 16/05/2024.
//

import Foundation

struct TaskMap: Codable, Identifiable {
    var id = UUID()
    var name: String
    var mapping: Int
    var reason: String

    private enum CodingKeys: String, CodingKey {
        case name, mapping, reason
    }
}

extension TaskMap {
    init(_ jsonString: String) throws {
            guard let data = jsonString.data(using: .utf8) else {
                throw NSError(domain: "JSONDecoding", code: 0, userInfo: [NSLocalizedDescriptionKey: "Cannot convert JSON string to data."])
            }
            self = try JSONDecoder().decode(TaskMap.self, from: data)
        }

    init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            name = try container.decode(String.self, forKey: .name)

            let mappingString = try container.decode(String.self, forKey: .mapping)
            guard let mappingInt = Int(mappingString) else {
                throw NSError(domain: "DecodingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Mapping must be convertible to an integer."])
            }
            mapping = mappingInt

            reason = try container.decode(String.self, forKey: .reason)
        }
}
var mockMappedTask = TaskMap(name: "Design an ADHD time management app for adults", mapping: 2, reason: "The task 'design an ADHD time management app for adults' is categorized as Important but Not Urgent (Quadrant II) because it is crucial for supporting individuals with ADHD in managing their time more effectively, yet it does not typically require immediate action and allows for thoughtful planning and development.")
