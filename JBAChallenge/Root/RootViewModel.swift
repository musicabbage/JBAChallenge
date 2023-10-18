//
//  RootViewModel.swift
//  JBAChallenge
//
//  Created by cabbage on 2023/10/12.
//

import Foundation

protocol RootViewModelProtocol: ObservableObject {
    
    func readFile(url: URL) async
}

class RootViewModel: RootViewModelProtocol {
    
    func readFile(url: URL) async {
        
        guard freopen(url.path(), "r", stdin) != nil else { return }
        
        var dataModel: PrecipitationModel?
        var currentGrid: PrecipitationModel.Grid?
        while let line = readLine() {
            if let dataModel {
                if let refs = try? findGrid(string: line) {
                    currentGrid = .init(x: refs.x, y: refs.y)
                } else if currentGrid != nil {
                    currentGrid!.appendRow(findNumbers(string: line))
                }
            } else if let yearString = scan(headerString: line)["Years"],
                      let years = try? findYears(string: yearString) {
                dataModel = .init(fromYear: years.from, toYear: years.to, grids: [])
            }
        }
    }
}

private extension RootViewModel {
    
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
}

class MockRootViewModel: RootViewModelProtocol {
    func readFile(url: URL) async {
        
    }
}
