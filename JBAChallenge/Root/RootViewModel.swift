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
    var errorMessage: String? { get }
    var items: [PrecipitationItem] { get }
    var files: [FileItem] { get }
    
    func readFile(url: URL) async
    func fetchGrids(file: String)
}

class RootViewModel: RootViewModelProtocol {
    @Published var errorMessage: String?
    @Published var header: String = ""
    @Published var items: [PrecipitationItem] = []
    @Published var files: [FileItem] = []
    
    private let dataController = PersistenceController.shared
    private var notificationToken: NSObjectProtocol?
    
    init() {
        fetchFiles()
    }
    
    func readFile(url: URL) async {
        guard freopen(url.path(), "r", stdin) != nil else { return }
        
        reset()
        let fileName = url.lastPathComponent
        
        let transactionId = dataController.startTransaction()
        
        do {
            try dataController.deleteExistedGridRows(inFile: fileName, toTransaction: transactionId)
            
            var currentGrid: PrecipitationGridModel?
            var file: FileItem?
            
            while let line = readLine() {
                guard let file else {
                    if let yearString = scan(headerString: line)["Years"],
                       let years = try findYears(string: yearString) {
                        let fileItem = try dataController.generateFile(fileName: fileName,
                                                                       fromYear: Int16(years.from),
                                                                       toYear: Int16(years.to),
                                                                       toTransaction: transactionId)
                        file = fileItem
                    }
                    continue
                }
                
                if let refs = try findGrid(string: line) {
                    if let currentGrid {
                        try dataController.insertGridRows(currentGrid,
                                                          withFileItem: file,
                                                          toTransaction: transactionId)
                    }
                    currentGrid = .init(x: refs.x, y: refs.y)
                } else if currentGrid != nil {
                    currentGrid!.appendRow(findNumbers(string: line))
                }
            }
            try dataController.submitTransaction(id: transactionId)
            
            fetchFiles()
            fetchGrids(file: fileName)
        } catch {
            dataController.rollbackTransaction(id: transactionId)
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func fetchGrids(file: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            do {
                let context = self.dataController.container.viewContext
                
                let fetchRequest = PrecipitationItem.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "origin.name == %@", file)
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
                self.items = try context.fetch(fetchRequest)
                if let file = self.items.first?.origin {
                    self.header = "Years: \(file.fromYear)-\(file.toYear) (count: \(self.items.count))"
                }
            } catch {
                self.errorMessage = "Fetch data failed.\n\(error.localizedDescription)"
            }
        }
    }
}

private extension RootViewModel {
    func reset() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            header = ""
            items = []
            errorMessage = nil
        }
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
    
    func fetchFiles() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            do {
                let fetchRequest = FileItem.fetchRequest()
                self.files = try self.dataController.container.viewContext.fetch(fetchRequest)
            } catch {
                errorMessage = "Fetch files failed"
            }
        }
    }
}

class MockRootViewModel: RootViewModelProtocol {
    @Published var errorMessage: String?
    @Published var header: String = "Mock header"
    @Published var items: [PrecipitationItem] = [.mock, .mock, .mock]
    @Published var files: [FileItem] = [.mock, .mock, .mock, .mock]
    
    func readFile(url: URL) async { }
    func fetchGrids(file: String) { }
}

extension PrecipitationItem {
    static var mock: PrecipitationItem {
        let mockItem = PrecipitationItem()
        mockItem.xref = 1
        mockItem.yref = 2
        mockItem.date = ""
        mockItem.value = 300
        return mockItem
    }
}

extension FileItem {
    static var mock: FileItem {
        let mockItem = FileItem()
        mockItem.name = "mock.pre"
        return mockItem
    }
}

