//
//  
//  BlenderViewModel.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 08/04/2024.
//
//

import Foundation
import UIKit
import SwiftOpenAI

@Observable class BlenderViewModel {
    private let service: OpenAIService
    private var assistantID = "asst_9O1PqUY9zmUWzOtNpEMro4wt"
   
    var isShowingTask = false
    var userPrompt = ""
    var blendedTask: BlendedTask?
    var isLoading: Bool?
    
    init(service: OpenAIService) {
        self.service = service
    }
    
    func blendTask() async {
            isLoading = true
            let prompt = userPrompt
        
            do {
                guard (try await getAssistant()) != nil else { return }
                
                let thread = try await createThread()
                _ = try await createMessage(threadID: thread.id, prompt: prompt)
                var runObject = try await runThread(threadID: thread.id)
                let timestamp = Date.now
                while ["queued", "in_progress", "cancelling"].contains(runObject.status) {
                    if timestamp.timeIntervalSinceNow > 60 {
                        throw APIError.timeOutError
                    }
                    try await Task.sleep(nanoseconds:1 * 1_000_000_000)
                    runObject = try await service.retrieveRun(threadID: thread.id, runID: runObject.id)
                }
                
                guard runObject.status == "requires_action" else {
                    throw APIError.requestFailed(description: "Run incomplete")
                }
                
                let response = runObject.requiredAction?.submitToolsOutputs.toolCalls.first?.function.arguments

                guard let data = response else { throw APIError.jsonDecodingFailure(description: "Could not get response from AI") }
                blendedTask = try .init(data)
                await UINotificationFeedbackGenerator().notificationOccurred(.success)
                isLoading = false
                
            } catch {
                print("Blending error: \(error)")
            }
            
        }
    
    func getAssistant() async throws -> AssistantObject? {
        return try await service.retrieveAssistant(id: assistantID)
    }

    func createThread() async throws -> ThreadObject {
        return try await service.createThread(parameters: .init())
    }

    func createMessage(threadID: String, prompt: String) async throws -> MessageObject {
        return try await service.createMessage(threadID: threadID, parameters: .init(role: .user, content: prompt))
    }

    func runThread(threadID: String) async throws -> RunObject {
        let parameters = RunParameter(assistantID: assistantID)
        return try await service.createRun(threadID: threadID, parameters: parameters)
    }
}
