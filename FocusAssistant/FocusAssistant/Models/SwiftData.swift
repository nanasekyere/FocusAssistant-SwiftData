//
//  SwiftData.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 13/04/2024.
//

import Foundation
import SwiftData

@ModelActor
public actor BackgroundSerialPersistenceActor {
    public func fetchData<T: PersistentModel>(
        predicate: Predicate<T>? = nil,
        sortBy: [SortDescriptor<T>] = []
    ) throws -> [T] {
        let fetchDescriptor = FetchDescriptor<T>(predicate: predicate, sortBy: sortBy)
        let list: [T] = try modelContext.fetch(fetchDescriptor)
        return list
    }
    
    public func fetchCount<T: PersistentModel>(
        predicate: Predicate<T>? = nil,
        sortBy: [SortDescriptor<T>] = [],
        fetchDescriptor: FetchDescriptor<T>? = nil
    ) throws -> Int {
        let fetchDescriptor = fetchDescriptor ?? FetchDescriptor<T>(predicate: predicate, sortBy: sortBy)
        let count = try modelContext.fetchCount(fetchDescriptor)
        return count
    }
    
    public func insert<T: PersistentModel>(data: T) {
        let context = data.modelContext ?? modelContext
        context.insert(data)
    }
    
    public func save() throws {
        try modelContext.save()
    }
    
    public func remove<T: PersistentModel>(predicate: Predicate<T>? = nil) throws {
        try modelContext.delete(model: T.self, where: predicate)
    }
    
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

    public func checkExpiredTasks(activeTaskIDs: Set<PersistentIdentifier>) throws {
        let currentTime = Date.now

        var tasks = try modelContext.fetch(FetchDescriptor<UserTask>(predicate: #Predicate<UserTask> { task in
            !task.isCompleted && !task.isExpired && !task.pomodoro
        }))

        for task in tasks  {
            if task.startTime! < currentTime && !activeTaskIDs.contains(task.id) {
                task.isExpired = true
            }
        }

    }

    func checkHighPriorityTasks(activeTaskIDs: Set<PersistentIdentifier>) throws -> UserTask? {
        var tasks = try modelContext.fetch(FetchDescriptor(predicate: #Predicate<UserTask> { task in
            !task.isCompleted && !task.isExpired && !task.pomodoro
        }))

        for task in tasks {
            if task.priority == .high {
                if let startTime = task.startTime, Calendar.current.isDate(Date(), equalTo: startTime, toGranularity: .minute) {
                    if !activeTaskIDs.contains(task.id) {
                        print("Task \(task.name) Should start now")
                        return task
                    }
                }
            }
        }
        return nil
    }

}

@MainActor
class DataController {
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

func decodeBlendedTask(from JSONString: String, modelContext: ModelContext) throws -> BlendedTask {
    let dummyTask = try DummyTask.init(JSONString)
    let blendedTask = BlendedTask(from: dummyTask)
    modelContext.insert(blendedTask)
    var subtasks = [Subtask]()
    
    
    for subtask in dummyTask.subtasks {
        var details = [Detail]()
        
        let newSubtask = Subtask(from: subtask)
        modelContext.insert(newSubtask)
        //Assign the relationship after inserting into context
        newSubtask.blendedTask = blendedTask
        
        for detail in subtask.details {
            let newDetail = Detail(from: detail)
            modelContext.insert(newDetail)
            //Assign the relationship after inserting into context
            newDetail.subtask = newSubtask
            details.append(newDetail)
        }
        newSubtask.details = details
        subtasks.append(newSubtask)
    }
    
    blendedTask.subtasks = subtasks
    
    return blendedTask
}

func createTask(from dummyTask: DummyTask, modelContext: ModelContext) throws {
    let blendedTask = BlendedTask(from: dummyTask)
    modelContext.insert(blendedTask)
    var subtasks = [Subtask]()


    for subtask in dummyTask.subtasks.reversed() {
        var details = [Detail]()

        let newSubtask = Subtask(from: subtask)
        modelContext.insert(newSubtask)
        //Assign the relationship after inserting into context
        newSubtask.blendedTask = blendedTask

        for detail in subtask.details.reversed() {
            let newDetail = Detail(from: detail)
            modelContext.insert(newDetail)
            //Assign the relationship after inserting into context
            newDetail.subtask = newSubtask
            details.append(newDetail)
        }
        newSubtask.details = details
        subtasks.append(newSubtask)
    }

    blendedTask.subtasks = subtasks
}
