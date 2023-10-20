//
//  RootViewModel.swift
//  JBAChallenge
//
//  Created by cabbage on 2023/10/12.
//

import Foundation
import CoreData

protocol RootViewModelProtocol: ObservableObject {
    var header: String { get }
    var items: [PrecipitationItem] { get }
    
    func readFile(url: URL) async
}

class RootViewModel: RootViewModelProtocol {
    
    @Published var header: String = ""
    @Published var items: [PrecipitationItem] = []
    
    private let dataController = PersistenceController.shared
    
    private var notificationToken: NSObjectProtocol?
    
    deinit {
        removeDataUpdateObserver()
    }
    
    func readFile(url: URL) async {
        guard freopen(url.path(), "r", stdin) != nil else { return }
        let fileName = url.lastPathComponent
        
        notificationToken = NotificationCenter.default.addObserver(forName: .NSPersistentStoreRemoteChange, object: nil, queue: .main, using: { [weak self, fileName] _ in
            guard let self else { return }
            self.fetch()
        })
        
        
        var currentGrid: PrecipitationModel.Grid?
        let context = dataController.container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        var file: FileItem?
        
        while let line = readLine() {
            guard let file else {
                if let yearString = scan(headerString: line)["Years"],
                          let years = try? findYears(string: yearString) {
                    let fileItem = FileItem(entity: FileItem.entity(), insertInto: context)
                    fileItem.name = fileName
                    fileItem.fromYear = Int16(years.from)
                    fileItem.toYear = Int16(years.to)
                    file = fileItem
                }
                continue
            }
            
            if let refs = try? findGrid(string: line) {
                if let currentGrid {
                    do {
                        let result = try await dataController.saveGrid(currentGrid, withFileItem: file)
                        if let objectIDS = result.result as? [NSManagedObjectID] {
                            for objectId in objectIDS {
                                guard let subItem = try? context.existingObject(with: objectId) as? PrecipitationItem else { continue }
                                file.addToRelationship(subItem)
                            }
                            print("save result: \(objectIDS.count)")
                        }
                    } catch {
                        print("save grid error: \(error)")
                        break
                    }
                }
                currentGrid = .init(x: refs.x, y: refs.y)
            } else if currentGrid != nil {
                currentGrid!.appendRow(findNumbers(string: line))
            }
        }
        removeDataUpdateObserver()
        fetch()
        do {
            try context.save()
        } catch {
            print(error)
        }
    }
}

private extension RootViewModel {
    func reset() {
        header = ""
        items = []
    }
    
    func scan(headerString: String) -> [String: String] {
        let scanner = Scanner(string: headerString)
        scanner.charactersToBeSkipped = ["="]
        var result: [String: String] = [:]
        var currentKey = ""
        
        while !scanner.isAtEnd {
            guard currentKey.isEmpty else {
                if let value = scanner.scanUpToString("]") {
                    result[currentKey] = value
                    currentKey = ""
                }
                continue
            }

            guard scanner.scanUpToString("[") == nil else { continue }
            guard let key = scanner.scanUpToString("=") else { continue }
            
            currentKey = String(key.dropFirst())
        }
        return result
    }
    
    
    func findYears(string: String) throws -> (from: Int, to: Int)? {
        let scanner = Scanner(string: string)
        scanner.charactersToBeSkipped = CharacterSet(charactersIn: "=- ")

        var from: Int!
        var to: Int!
        while !scanner.isAtEnd {
            guard let year = scanner.scanInt() else { continue }
            if from == nil {
                from = year
            } else {
                to = year
            }
        }
        
        if from == nil || to == nil {
            throw Error.parseYearsError
        }
        
        return (from, to)
    }
    
    func findGrid(string: String) throws -> (x: Int, y: Int)? {
        let scanner = Scanner(string: string)
        scanner.charactersToBeSkipped = CharacterSet(charactersIn: "=, ")

        guard let key = scanner.scanUpToString("="),
              key == "Grid-ref" else {
            return nil
        }
        
        var x: Int!
        var y: Int!
        while !scanner.isAtEnd {
            guard let refValue = scanner.scanInt() else { continue }
            if x == nil {
                x = refValue
            } else {
                y = refValue
            }
        }
        
        if x == nil || y == nil {
            throw Error.invalidGridRef
        }
        
        return (x, y)
    }
    
    func findNumbers(string: String) -> [Int] {
        var result: [Int] = []
        
        let scanner = Scanner(string: string)
        
        guard let value = scanner.scanInt() else { return result }
        result.append(value)
        while !scanner.isAtEnd {
            if let value = scanner.scanInt() {
                result.append(value)
            }
        }
        return result
    }
    
    func removeDataUpdateObserver() {
        guard let notificationToken else { return }
        NotificationCenter.default.removeObserver(notificationToken)
    }
    
    func fetch() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            do {
                let fetchRequest = PrecipitationItem.fetchRequest()
                self.items = try self.dataController.container.viewContext.fetch(fetchRequest)
            } catch {
                print("Fetch failed")
            }
        }
    }
}

class MockRootViewModel: RootViewModelProtocol {
    
    @Published var header: String = "Mock header"
    @Published var items: [PrecipitationItem] = [.mock, .mock, .mock]
    
    func readFile(url: URL) async {
        
    }
}

extension PrecipitationItem {
    static var mock: PrecipitationItem {
        let mockItem = PrecipitationItem(context: NSManagedObjectContext(.mainQueue))
        mockItem.xref = 1
        mockItem.yref = 2
        mockItem.date = ""
        mockItem.value = 300
        return mockItem
    }
    
}

