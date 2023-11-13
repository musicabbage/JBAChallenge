//
//  Persistence.swift
//  JBAChallenge
//
//  Created by cabbage on 2023/10/12.
//

import CoreData

class PersistenceController {
    
    static let shared = PersistenceController()

    let container: NSPersistentContainer
    private var contexts: [String: NSManagedObjectContext] = [:]
    private var batchRequests: [String: [NSPersistentStoreRequest]] = [:]
    
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "JBAChallenge")
        
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }
        
        if inMemory {
            description.url = URL(fileURLWithPath: "/dev/null")
        }
        print(description.url)
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
    
    func startTransaction() -> String {
        let context = newBackgroundTaskContext()
        let transactionId = UUID().uuidString
        contexts[transactionId] = context
        return transactionId
    }
    
    func submitTransaction(id: String) async throws {
        guard let requests = batchRequests[id], !requests.isEmpty else { throw Error.transactionNotExisted }
        
        let context = newBackgroundTaskContext()
        try await context.perform { [weak self] in
            for request in requests {
                let result = try context.execute(request)
                print("result: \(result)")
            }
        }
        print("transaction end =========")
        batchRequests[id] = nil
    }
    
    func rollbackTransaction(id: String) {
        batchRequests[id] = nil
    }
    
    func saveFile(name fileName: String, fromYear: Int16, toYear: Int16, toTransaction transactionId: String) {
        let fileItem: [String : Any] = ["name": fileName,
                                        "fromYear": fromYear,
                                        "toYear": toYear]
        let batchInsertRequest = NSBatchInsertRequest(entity: FileItem.entity(), objects: [fileItem])
        batchInsertRequest.resultType = .count
        if var requests = batchRequests[transactionId] {
            requests.append(batchInsertRequest)
            batchRequests[transactionId] = requests
        } else {
            batchRequests[transactionId] = [batchInsertRequest]
        }
    }
    
    func batchDeleteGridRows(inFile fileName: String, toTransaction transactionId: String) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "PrecipitationItem")
        fetchRequest.predicate = NSPredicate(format: "fileName == %@", fileName)
        fetchRequest.includesPropertyValues = false
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        
        if var requests = batchRequests[transactionId] {
            requests.append(batchDeleteRequest)
            batchRequests[transactionId] = requests
        } else {
            batchRequests[transactionId] = [batchDeleteRequest]
        }
    }
    
    func batchInsertGrids(_ grids: [PrecipitationGridModel], withFileName fileName: String, fromYear: Int, toTransaction transactionId: String) {
        var items: [[String: Any]] = []
        for grid in grids {
            for (yearOffset, row) in grid.rows.enumerated() {
                var rowItem: [String: Any] = [:]
                rowItem["xref"] = grid.x
                rowItem["yref"] = grid.y
                rowItem["fileName"] = fileName
                for (monthOffset, value) in row.enumerated() {
                    rowItem["date"] = "1/\(monthOffset + 1)/\(yearOffset + fromYear)"
                    rowItem["value"] = value
                    items.append(rowItem)
                }
            }
        }
        
        let batchInsertRequest = NSBatchInsertRequest(entity: PrecipitationItem.entity(), objects: items)
        batchInsertRequest.resultType = .count
        if var requests = batchRequests[transactionId] {
            requests.append(batchInsertRequest)
            batchRequests[transactionId] = requests
        } else {
            batchRequests[transactionId] = [batchInsertRequest]
        }
    }
}

private extension PersistenceController {
    /// Creates and configures a private queue context.
    func newBackgroundTaskContext() -> NSManagedObjectContext {
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
