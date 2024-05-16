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

    // MARK: - Task Blending

    /// Asynchronously blends a task based on the user's input prompt.
    /// This function orchestrates the entire process of blending a task using the OpenAI service.
    /// - Note: This function is marked with `@MainActor` to ensure that it runs on the main actor,
    ///   allowing it to safely interact with UI elements.
    func blendTask() async {
        // Indicate that the blending task is in progress, enabling UI changes.
        isLoading = true
        // Extract the user prompt from the view model.
        let prompt = userPrompt

        do {
            // Ensure that a valid model context is available for storing the blended task.
            guard let modelContext = context else { throw APIError.requestFailed(description: "Could not find model context") }
            // Retrieve the assistant object from the OpenAI service.
            guard let assistant = try await getAssistant() else { return }

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
                throw APIError.requestFailed(description: "Run incomplete")
            }

            // Extract the response data from the run object, representing the blended task.
            let response = runObject.requiredAction?.submitToolsOutputs.toolCalls.first?.function.arguments

            // Ensure that the response data is available.
            guard let data = response else { throw APIError.jsonDecodingFailure(description: "Could not get response from AI") }

            // Parse the response data into a dummy task object.
            let dummyTask = try DummyTask(data)
            // Convert the dummy task into a blended task object.
            let blendedTask = BlendedTask(from: dummyTask)

            // Insert the blended task into the model context for persistence.
            modelContext.insert(blendedTask)
            // Associate the blended task with its corresponding task.
            blendedTask.correspondingTask = blendedTask.toTask()

            // Initialize an array to store subtasks extracted from the dummy task.
            var subtasks = [Subtask]()

            // Iterate over each subtask in the dummy task.
            for (index, subtask) in dummyTask.subtasks.enumerated() {
                // Initialize an array to store details extracted from the subtask.
                var details = [Detail]()
                // Create a new subtask object based on the dummy subtask.
                let newSubtask = Subtask(from: subtask, index: index)
                // Insert the new subtask into the model context.
                modelContext.insert(newSubtask)
                // Associate the new subtask with the blended task.
                newSubtask.blendedTask = blendedTask

                // Iterate over each detail in the subtask.
                for (index, detail) in subtask.details.enumerated() {
                    // Create a new detail object based on the dummy detail.
                    let newDetail = Detail(from: detail, index: index)
                    // Insert the new detail into the model context.
                    modelContext.insert(newDetail)
                    // Associate the new detail with the current subtask.
                    newDetail.subtask = newSubtask
                    // Append the new detail to the details array.
                    details.append(newDetail)
                }
                // Set the details of the new subtask.
                newSubtask.details = details
                // Append the new subtask to the subtasks array.
                subtasks.append(newSubtask)
            }

            // Set the subtasks of the blended task.
            blendedTask.subtasks = subtasks

            // Update the view model's completed task property with the blended task.
            completedTask = blendedTask

            // Provide haptic feedback to indicate successful completion.
            await UINotificationFeedbackGenerator().notificationOccurred(.success)
            // Indicate that the blending task has completed.
            isLoading = false

        } catch {
            // Handle any errors that occur during the blending process.
            print("Blending error: \(error)")
        }

    }

    // MARK: - OpenAI Service Functions

    /// Retrieves the assistant object from the OpenAI service.
    func getAssistant() async throws -> AssistantObject? {
        return try await service.retrieveAssistant(id: assistantID)
    }

    /// Creates a new thread for the blending task.
    func createThread() async throws -> ThreadObject {
        return try await service.createThread(parameters: .init())
    }

    /// Creates a message in the specified thread containing the user prompt.
    func createMessage(threadID: String, prompt: String) async throws -> MessageObject {
        return try await service.createMessage(threadID: threadID, parameters: .init(role: .user, content: prompt))
    }

    /// Runs the specified thread and returns the resulting run object.
    func runThread(threadID: String) async throws -> RunObject {
        let parameters = RunParameter(assistantID: assistantID)
        return try await service.createRun(threadID: threadID, parameters: parameters)
    }
}
