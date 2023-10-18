//
//  Persistence.swift
//  JBAChallenge
//
//  Created by cabbage on 2023/10/12.
//

import CoreData

class PersistenceController {
    
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<10 {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "JBAChallenge")
        
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }
        
        if inMemory {
            description.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Enable persistent store remote change notifications
        /// - Tag: persistentStoreRemoteChange
        description.setOption(true as NSNumber,
                              forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func saveGrid(_ grid: PrecipitationModel.Grid, withModel model: PrecipitationModel) async throws -> NSBatchInsertResult {
        let taskContext = newTaskContext()
        
        /// - Tag: performAndWait
        return try await taskContext.perform {
            
            // Execute the batch insert.
            /// - Tag: batchInsertRequest
            var items: [[String: Any]] = []
            for (yearOffset, row) in grid.rows.enumerated() {
                var rowItem: [String: Any] = [:]
                rowItem["xref"] = grid.x
                rowItem["yref"] = grid.y
                for (monthOffset, value) in row.enumerated() {
                    rowItem["date"] = "1/\(monthOffset + 1)/\(yearOffset + model.fromYear)"
                    rowItem["value"] = value
                    items.append(rowItem)
                }
            }
            
            let batchInsertRequest = NSBatchInsertRequest(entity: PrecipitationItem.entity(), objects: items)
            
            if let fetchResult = try? taskContext.execute(batchInsertRequest),
               let batchInsertResult = fetchResult as? NSBatchInsertResult,
               let success = batchInsertResult.result as? Bool, success {
                return batchInsertResult
            }
            print("Failed to execute batch insert request.")
            throw DBError.batchInsertError
        }
    }
}

private extension PersistenceController {
    /// Creates and configures a private queue context.
    func newTaskContext() -> NSManagedObjectContext {
        // Create a private queue context.
        /// - Tag: newBackgroundContext
        let taskContext = container.newBackgroundContext()
        taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        // Set unused undoManager to nil for macOS (it is nil by default on iOS)
        // to reduce resource requirements.
        taskContext.undoManager = nil
        return taskContext
    }
    
}
