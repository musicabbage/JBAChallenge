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
    
    func startTransaction() -> String {
        let context = newTaskContext()
        let transactionId = UUID().uuidString
        contexts[transactionId] = context
        return transactionId
    }
    
    func generateFile(fileName: String, fromYear: Int16, toYear: Int16, toTransaction transactionId: String) throws -> FileItem {
        guard let context = contexts[transactionId] else { throw Error.transactionNotExisted }
        let fileItem = FileItem(entity: FileItem.entity(), insertInto: context)
        fileItem.name = fileName
        fileItem.fromYear = fromYear
        fileItem.toYear = toYear
        return fileItem
    }
    
    func submitTransaction(id: String) throws {
        guard let context = contexts[id] else { throw Error.transactionNotExisted }
        print("=============================")
        print("insert: \(context.insertedObjects.count)")
        print("delete: \(context.deletedObjects.count)")
        print("=============================")
        try context.save()
        contexts[id] = nil
    }
    
    @discardableResult
    func rollbackTransaction(id: String) -> Bool {
        guard let context = contexts[id] else {
            return false
        }
        context.rollback()
        contexts[id] = nil
        return true
    }
    
    func deleteExistedGridRows(inFile fileName: String, toTransaction transactionId: String) throws {
        guard let context = contexts[transactionId] else { throw Error.transactionNotExisted }
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "PrecipitationItem")
        fetchRequest.predicate = NSPredicate(format: "origin.name == %@", fileName)
        guard let existedGridRows = try context.fetch(fetchRequest) as? [PrecipitationItem] else {
            return
        }
        for row in existedGridRows {
            context.delete(row)
        }
    }
    
    func insertGridRows(_ grid: PrecipitationGridModel, withFileItem fileItem: FileItem, toTransaction transactionId: String) throws {
        guard let context = contexts[transactionId] else { throw Error.transactionNotExisted }
        
        for (yearOffset, row) in grid.rows.enumerated() {
            for (monthOffset, value) in row.enumerated() {
                let insertItem = PrecipitationItem(entity: PrecipitationItem.entity(), insertInto: context)
                insertItem.xref = Int16(grid.x)
                insertItem.yref = Int16(grid.y)
                insertItem.date = "1/\(monthOffset + 1)/\(yearOffset + Int(fileItem.fromYear))"
                insertItem.value = Int32(value)
                insertItem.origin = fileItem
            }
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
