//
// TaskMapperViewModel.swift
// FocusAssistant
//
// Created by Nana Sekyere on 16/05/2024.
//

import Foundation
import Observation
import SwiftOpenAI
import UIKit

@Observable class TaskMapperViewModel {
    // OpenAI service instance for API communication
    private let service: OpenAIService

    // Identifier for the OpenAI assistant
    private var assistantID = "asst_yk2qrREByrJhV64tKnW8JXMQ"

    // State variables
    var isShowingTask = false
    var prompt = ""
    var completedMap: TaskMap?
    var isLoading: Bool?
    var error = APIError.timeOutError

    init(service: OpenAIService) {
        self.service = service
    }

    // Asynchronous function to map a task using OpenAI API
    func mapTask() async throws {
        isLoading = true

        // Check if prompt is empty
        guard prompt != "" else {
            error = APIError.dataCouldNotBeReadMissingData(description: "No Prompt")
            throw error
        }

        // Retrieve OpenAI assistant
        guard (try await getAssistant()) != nil else {
            error = APIError.requestFailed(description: "Could not retrieve assistant")
            throw error
        }

        // Create a new thread for task mapping
        let thread = try await createThread()
        // Create a message in the thread with user's prompt
        _ = try await createMessage(threadID: thread.id, prompt: prompt)

        // Initialize variable to store the run object representing the current run
        var runObject = try await runThread(threadID: thread.id)

        // Capture current timestamp to handle timeout
        let timestamp = Date.now
        // Poll run object until it reaches a terminal state or times out
        while ["queued", "in_progress", "cancelling"].contains(runObject.status) {
            // Check if time elapsed since blending process started exceeds timeout threshold
            if timestamp.timeIntervalSinceNow > 60 {
                // If timeout threshold exceeded, throw timeout error
                throw APIError.timeOutError
            }
            // Wait for short interval before polling again to avoid overwhelming system
            try await Task.sleep(nanoseconds:1 * 1_000_000_000)
            // Retrieve updated run object from OpenAI service
            runObject = try await service.retrieveRun(threadID: thread.id, runID: runObject.id)
        }

        // Check if run object completed successfully and requires further action
        guard runObject.status == "requires_action" else {
            // If run object is in unexpected state, throw error indicating incomplete execution
            error = APIError.requestFailed(description: "Run incomplete")
            throw error
        }

        // Extract response data from run object, representing blended task
        let response = runObject.requiredAction?.submitToolsOutputs.toolCalls.first?.function.arguments

        // Ensure response data is available
        guard let data = response else { throw APIError.jsonDecodingFailure(description: "Could not get response from AI") }

        // Attempt to decode response into TaskMap object
        guard let taskMap = try? TaskMap(data) else {
            error = APIError.responseUnsuccessful(description: "Failed to decode response")
            throw error
        }

        completedMap = taskMap

        // Provide haptic feedback to indicate successful completion
        await UINotificationFeedbackGenerator().notificationOccurred(.success)
        // Indicate blending task has completed
        isLoading = false

    }

    // MARK: - OpenAI Service Functions

    /// Retrieves the assistant object from the OpenAI service.
    func getAssistant() async throws -> AssistantObject? {
        return try await service.retrieveAssistant(id: assistantID)
    }

    /// Creates a new thread for the blending task.
    func createThread() async throws -> ThreadObject {
        do {
            return try await service.createThread(parameters: .init())
        } catch {
            self.error = APIError.requestFailed(description: "Failed to create thread. Try again")
            throw self.error
        }
    }

    /// Creates a message in the specified thread containing the user prompt.
    func createMessage(threadID: String, prompt: String) async throws -> MessageObject {
        do {
            return try await service.createMessage(threadID: threadID, parameters: .init(role: .user, content: prompt))
        } catch {
            self.error = APIError.requestFailed(description: "Failed to create message. Try again")
            throw self.error
        }
    }

    /// Runs the specified thread and returns the resulting run object.
    func runThread(threadID: String) async throws -> RunObject {
        do {
            let parameters = RunParameter(assistantID: assistantID)
            return try await service.createRun(threadID: threadID, parameters: parameters)
        } catch {
            self.error = APIError.requestFailed(description: "Failed to run thread. Try again")
            throw self.error
        }
    }
}
