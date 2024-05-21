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
import SwiftData

/// ViewModel responsible for blending tasks using the OpenAI service.
@Observable class BlenderViewModel {
    private let service: OpenAIService
    private var assistantID = "asst_9O1PqUY9zmUWzOtNpEMro4wt"

    // MARK: - Properties

    /// Indicates whether the blended task view is being presented.
    var isShowingTask = false

    /// The user prompt for blending the task.
    var userPrompt = ""

    /// The completed blended task.
    var completedTask: BlendedTask?

    /// Indicates whether a blending task is in progress.
    var isLoading: Bool?

    /// The model context for interacting with the database.
    var context: ModelContext?

    init(service: OpenAIService) {
        self.service = service
    }

    var error = APIError.timeOutError
    // MARK: - Task Blending

    /// Asynchronously blends a task based on the user's input prompt.
    /// This function orchestrates the entire process of blending a task using the OpenAI service.
    /// - Note: This function is marked with `@MainActor` to ensure that it runs on the main actor,
    ///   allowing it to safely interact with UI elements.
    func blendTask() async throws -> String {
        // Indicate that the blending task is in progress, enabling UI changes.
        isLoading = true
        // Extract the user prompt from the view model.
        let prompt = userPrompt
        
        // Ensure that a valid model context is available for storing the blended task.
        guard let modelContext = context else {
            error = APIError.requestFailed(description: "Could not find model context")
            throw error
        }

        // Retrieve the assistant object from the OpenAI service.
        guard (try await getAssistant()) != nil else {
            error = APIError.dataCouldNotBeReadMissingData(description: "Could Not Retrieve AI Assistant. Contact the developer")
            throw error
        }

        // Create a new thread for the blending task.
        let thread = try await createThread()
        // Create a message in the thread containing the user's prompt.
        _ = try await createMessage(threadID: thread.id, prompt: prompt)

        // Initialize a variable to store the run object representing the current run.
        var runObject = try await runThread(threadID: thread.id)

        // Capture the current timestamp to handle timeout.
        let timestamp = Date.now
        // Continue polling the run object until it reaches a terminal state or times out.
        while ["queued", "in_progress", "cancelling"].contains(runObject.status) {
            // Check if the time elapsed since the start of the blending process exceeds the timeout threshold.
            if timestamp.timeIntervalSinceNow > 60 {
                // If the timeout threshold is exceeded, throw a timeout error.
                throw APIError.timeOutError
            }
            // Wait for a short interval before polling again to avoid overwhelming the system.
            try await Task.sleep(nanoseconds:1 * 1_000_000_000)
            // Retrieve the updated run object from the OpenAI service.
            runObject = try await service.retrieveRun(threadID: thread.id, runID: runObject.id)
        }

        // Check if the run object has completed successfully and requires further action.
        guard runObject.status == "requires_action" else {
            // If the run object is in an unexpected state, throw an error indicating incomplete execution.
            error = APIError.requestFailed(description: "Run incomplete")
            throw error
        }

        // Extract the response data from the run object, representing the blended task.
        let response = runObject.requiredAction?.submitToolsOutputs.toolCalls.first?.function.arguments

        // Ensure that the response data is available.
        guard let data = response else { throw APIError.jsonDecodingFailure(description: "Could not get response from AI") }
        // Provide haptic feedback to indicate successful completion.
        await UINotificationFeedbackGenerator().notificationOccurred(.success)
        // Indicate that the blending task has completed.
        isLoading = false

        // Return the blended task JSON String.
        return data
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
