//
//  RootViewModel.swift
//  JBAChallenge
//
//  Created by cabbage on 2023/10/12.
//

import Foundation
import CoreData

@MainActor
protocol RootViewModelProtocol: ObservableObject {
    var header: String { get }
    var errorMessage: String? { get }
    var items: [PrecipitationItem] { get }
    var files: [FileItem] { get }
    
    func readFile(url: URL) async
    func fetchGrids(file: String)
    func fetchNextPage()
}

class RootViewModel: RootViewModelProtocol {
    @Published var errorMessage: String?
    @Published var header: String = ""
    @Published var items: [PrecipitationItem] = []
    @Published var files: [FileItem] = []
    
    private let dataController = PersistenceController.shared
    private var currentFetch: NSFetchRequest<PrecipitationItem>?
    
    init() {
        fetchFiles()
    }
    
    func readFile(url: URL) async {
        guard freopen(url.path(), "r", stdin) != nil else { return }
        
        reset()
        let fileName = url.lastPathComponent
        
        let transactionId = dataController.startTransaction()
        
        do {
            
            var currentGrid: PrecipitationGridModel?
            var fromYear = 0
            var grids: [PrecipitationGridModel] = []
            
            while let line = readLine() {
                guard fromYear > 0 else {
                    if let yearString = scan(headerString: line)["Years"],
                       let years = try findYears(string: yearString) {
                        fromYear = years.from
                        dataController.saveFile(name: fileName,
                                                fromYear: Int16(years.from),
                                                toYear: Int16(years.to),
                                                toTransaction: transactionId)
                    }
                    continue
                }
                
                if let refs = try findGrid(string: line) {
                    if let currentGrid {
                        grids.append(currentGrid)
                    }
                    currentGrid = .init(x: refs.x, y: refs.y)
                } else if currentGrid != nil {
                    currentGrid!.appendRow(findNumbers(string: line))
                }
            }
            
            if let currentGrid {
                grids.append(currentGrid)
            }
            
            
            dataController.batchDeleteGridRows(inFile: fileName, toTransaction: transactionId)
            dataController.batchInsertGrids(grids, withFileName: fileName, fromYear: fromYear, toTransaction: transactionId)
            
            try await dataController.submitTransaction(id: transactionId)
            fetchFiles()
            fetchGrids(file: fileName)

        } catch {
            dataController.rollbackTransaction(id: transactionId)
            errorMessage = error.localizedDescription
        }
    }
    
    func fetchGrids(file: String) {
        reset()
        Task { [weak self] in
            guard let self else { return }
            let context = dataController.container.viewContext
            
            do {
                try await context.perform {
                    let fetchRequest = PrecipitationItem.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "fileName == %@", file)
                    fetchRequest.fetchLimit = 12
                    self.items = try context.fetch(fetchRequest)
                    if let file = self.items.first?.origin {
                        self.header = "Years: \(file.fromYear)-\(file.toYear) (count: \(self.items.count))"
                    }
                    self.currentFetch = fetchRequest
                }
            } catch {
                errorMessage = "Fetch data failed.\n\(error.localizedDescription)"
            }
        }
    }
    
    func fetchNextPage() {
        guard let fetchRequest = currentFetch else { return }
        let context = dataController.container.viewContext
        
        do {
            fetchRequest.fetchOffset = items.count
            let items = try context.fetch(fetchRequest)
            self.items.append(contentsOf: items)
        } catch {
            errorMessage = "Fetch data failed.\n\(error.localizedDescription)"
        }
    }
}

private extension RootViewModel {
    func reset() {
        header = ""
        items = []
        errorMessage = nil
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
    func fetchNextPage() { }
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

