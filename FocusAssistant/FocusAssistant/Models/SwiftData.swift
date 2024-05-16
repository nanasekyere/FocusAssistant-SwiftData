//
//  SwiftData.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 13/04/2024.
//

import Foundation
import SwiftData
import UserNotifications

/// Actor responsible for managing background tasks related to data persistence.
@ModelActor
public actor BackgroundSerialPersistenceActor {

    /// Fetches data from the model context with optional predicate and sorting.
    ///
    /// - Parameters:
    ///   - predicate: Optional predicate to filter the fetched data.
    ///   - sortBy: Sorting descriptors to sort the fetched data.
    /// - Returns: An array of fetched objects.
    public func fetchData<T: PersistentModel>(
        predicate: Predicate<T>? = nil,
        sortBy: [SortDescriptor<T>] = []
    ) throws -> [T] {
        let fetchDescriptor = FetchDescriptor<T>(predicate: predicate, sortBy: sortBy)
        let list: [T] = try modelContext.fetch(fetchDescriptor)
        return list
    }

    /// Fetches the count of records matching the given predicate and sorting.
    ///
    /// - Parameters:
    ///   - predicate: Optional predicate to filter the fetched data.
    ///   - sortBy: Sorting descriptors to sort the fetched data.
    ///   - fetchDescriptor: Additional fetch descriptor.
    /// - Returns: The count of records.
    public func fetchCount<T: PersistentModel>(
        predicate: Predicate<T>? = nil,
        sortBy: [SortDescriptor<T>] = [],
        fetchDescriptor: FetchDescriptor<T>? = nil
    ) throws -> Int {
        let fetchDescriptor = fetchDescriptor ?? FetchDescriptor<T>(predicate: predicate, sortBy: sortBy)
        let count = try modelContext.fetchCount(fetchDescriptor)
        return count
    }

    /// Inserts data into the model context.
    ///
    /// - Parameter data: The data to be inserted.
    public func insert<T: PersistentModel>(data: T) {
        let context = data.modelContext ?? modelContext
        context.insert(data)
    }

    /// Saves changes to the model context.
    public func save() throws {
        try modelContext.save()
    }

    /// Removes data matching the given predicate.
    ///
    /// - Parameter predicate: Optional predicate to filter the data to be removed.
    public func remove<T: PersistentModel>(predicate: Predicate<T>? = nil) throws {
        try modelContext.delete(model: T.self, where: predicate)
    }

    /// Saves and inserts data if no matching records are found.
    ///
    /// - Parameters:
    ///   - data: The data to be saved and inserted.
    ///   - predicate: The predicate to check for existing records.
    public func saveAndInsertIfNeeded<T: PersistentModel>(
        data: T,
        predicate: Predicate<T>
    ) throws {
        let descriptor = FetchDescriptor<T>(predicate: predicate)
        let context = data.modelContext ?? modelContext
        let savedCount = try context.fetchCount(descriptor)

        if savedCount == 0 {
            modelContext.insert(data)
        }
        try modelContext.save()
    }

    /// Checks and marks expired tasks, and notifies the user.
    ///
    /// - Parameters:
    ///   - activeTaskIDs: Set of active task IDs.
    ///   - activeModel: The active task view model.
    public func checkExpiredTasks(activeTaskIDs: Set<UUID>, activeModel: ActiveTaskViewModel) throws {
        let currentTime = Date.now

        let tasks = try modelContext.fetch(FetchDescriptor<UserTask>(predicate: #Predicate<UserTask> { task in
            !task.isCompleted && !task.isExpired && !task.pomodoro
        }))

        for task in tasks {
            if task.startTime! < currentTime && !activeTaskIDs.contains(task.identity) && activeModel.activeTask?.identity != task.identity {
                task.isExpired = true
                notifyExpiry(for: task)
            }
        }
    }

    /// Checks if a new task clashes with existing tasks.
    ///
    /// - Parameter newTask: The new task to be checked.
    /// - Returns: The conflicting task if any, otherwise nil.
    func isTaskClashing(for newTask: UserTask) throws -> UserTask? {
        if newTask.pomodoro {
            return nil
        }

        let availableTasks: [UserTask] = try fetchData(predicate: #Predicate<UserTask> { task in
            !task.isCompleted && !task.isExpired && task.blendedTask == nil && !task.pomodoro
        })

        for task in availableTasks {
            let endTime = task.startTime!.addingTimeInterval(Double(task.duration))
            if newTask.startTime!.isDate(inRange: task.startTime!, endDate: endTime) {
                return task
            }
        }
        return nil
    }

    /// Starts high-priority tasks if they are not active.
    ///
    /// - Parameter activeTaskIDs: Set of active task IDs.
    /// - Returns: The high-priority task to be started, if any.
    func startHighPriorityTasks(_ activeTaskIDs: Set<UUID>) throws -> UserTask? {
        let availableTasks: [UserTask] = try fetchData(predicate: #Predicate<UserTask> { task in
            !task.isCompleted && !task.isExpired && task.blendedTask == nil && !task.pomodoro
        })

        for task in availableTasks {
            if task.priority == .high {
                let endTime = task.startTime!.addingTimeInterval(Double(task.duration))
                if Date().isDate(inRange: task.startTime!, endDate: endTime) {
                    if !activeTaskIDs.contains(task.identity) {
                        print("Task \(task.name) Should start now")
                        return task
                    }
                }
            }
        }
        return nil
    }

    /// Checks and returns high-priority tasks that should start now.
    ///
    /// - Parameter activeTaskIDs: Set of active task IDs.
    /// - Returns: The high-priority task to be started, if any.
    func checkHighPriorityTasks(_ activeTaskIDs: Set<UUID>) throws -> UserTask? {
        let tasks = try modelContext.fetch(FetchDescriptor(predicate: #Predicate<UserTask> { task in
            !task.isCompleted && !task.isExpired && !task.pomodoro
        }))

        for task in tasks {
            if task.priority == .high {
                if let startTime = task.startTime, Calendar.current.isDate(Date(), equalTo: startTime, toGranularity: .minute) {
                    if !activeTaskIDs.contains(task.identity) {
                        print("Task \(task.name) Should start now")
                        return task
                    }
                }
            }
        }
        return nil
    }

    /// Safely decodes a BlendedTask from a JSON string.
    ///
    /// - Parameter JSONString: The JSON string representing the BlendedTask.
    /// - Returns: The decoded BlendedTask.
    func safeDecodeBlendedTask(from JSONString: String) throws -> BlendedTask {
        let dummyTask = try DummyTask.init(JSONString)
        let blendedTask = BlendedTask(from: dummyTask)
        modelContext.insert(blendedTask)
        blendedTask.correspondingTask = blendedTask.toTask()
        var subtasks = [Subtask]()

        for (index, subtask) in dummyTask.subtasks.enumerated() {
            var details = [Detail]()

            let newSubtask = Subtask(from: subtask, index: index)
            modelContext.insert(newSubtask)
            newSubtask.blendedTask = blendedTask

            for (index, detail) in subtask.details.enumerated() {
                let newDetail = Detail(from: detail, index: index)
                modelContext.insert(newDetail)
                newDetail.subtask = newSubtask
                details.append(newDetail)
            }
            newSubtask.details = details
            subtasks.append(newSubtask)
        }

        blendedTask.subtasks = subtasks

        return blendedTask
    }
}

/// Manages the data for previewing purposes.
@MainActor
class DataController {
    /// Provides a preview container for data.
    static let previewContainer: ModelContainer = {
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: UserTask.self, BlendedTask.self, configurations: config)

            for task in sampleTasks {
                container.mainContext.insert(task)
            }

            container.mainContext.insert(try decodeBlendedTask(from: serviceInfo.mockTask, modelContext: container.mainContext))
            container.mainContext.insert(try decodeBlendedTask(from: serviceInfo.mockTask2, modelContext: container.mainContext))

            return container
        } catch {
            fatalError("Failed to create model container for previewing: \(error.localizedDescription)")
        }
    }()
}

/// Decodes a BlendedTask from a JSON string and inserts it into the model context.
///
/// - Parameters:
///   - JSONString: The JSON string representing the BlendedTask.
///   - modelContext: The model context to insert the decoded BlendedTask into.
/// - Returns: The decoded BlendedTask.
func decodeBlendedTask(from JSONString: String, modelContext: ModelContext) throws -> BlendedTask {
    let dummyTask = try DummyTask.init(JSONString)
    let blendedTask = BlendedTask(from: dummyTask)
    modelContext.insert(blendedTask)
    blendedTask.correspondingTask = blendedTask.toTask()

    var subtasks = [Subtask]()

    for (index, subtask) in dummyTask.subtasks.enumerated() {
        var details = [Detail]()

        let newSubtask = Subtask(from: subtask, index: index)
        modelContext.insert(newSubtask)
        newSubtask.blendedTask = blendedTask

        for (index, detail) in subtask.details.enumerated() {
            let newDetail = Detail(from: detail, index: index)
            modelContext.insert(newDetail)
            newDetail.subtask = newSubtask
            details.append(newDetail)
        }
        newSubtask.details = details
        subtasks.append(newSubtask)
    }

    blendedTask.subtasks = subtasks

    return blendedTask
}

/// Creates a task from a DummyTask and inserts it into the model context.
///
/// - Parameters:
///   - dummyTask: The DummyTask to create the task from.
///   - modelContext: The model context to insert the created task into.
func createTask(from dummyTask: DummyTask, modelContext: ModelContext) throws {
    let blendedTask = BlendedTask(from: dummyTask)
    modelContext.insert(blendedTask)
    var subtasks = [Subtask]()

    for (index, subtask) in dummyTask.subtasks.enumerated() {
        var details = [Detail]()

        let newSubtask = Subtask(from: subtask, index: index)
        modelContext.insert(newSubtask)
        newSubtask.blendedTask = blendedTask

        for (index, detail) in subtask.details.enumerated() {
            let newDetail = Detail(from: detail, index: index)
            modelContext.insert(newDetail)
            newDetail.subtask = newSubtask
            details.append(newDetail)
        }
        newSubtask.details = details
        subtasks.append(newSubtask)
    }

    blendedTask.subtasks = subtasks

    modelContext.insert(blendedTask.toTask())
    blendedTask.correspondingTask = blendedTask.toTask()
}

/// Notifies the user about a task expiry.
///
/// - Parameter task: The task that has expired.
func notifyExpiry(for task: UserTask) {
    let content = UNMutableNotificationContent()
    content.title = "Task Expired"
    content.body = "You missed the start time for \(task.name)"
    content.sound = UNNotificationSound.default
    content.interruptionLevel = .active
    let request = UNNotificationRequest(identifier: task.identity.uuidString, content: content, trigger: nil)
    UNUserNotificationCenter.current().add(request)
}
