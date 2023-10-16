//
//  RootViewModel.swift
//  JBAChallenge
//
//  Created by cabbage on 2023/10/12.
//

import Foundation

protocol RootViewModelProtocol: ObservableObject {
    
    func readFile(url: URL)
}

class RootViewModel: RootViewModelProtocol {
    
    func readFile(url: URL) {
        
        guard freopen(url.path(), "r", stdin) != nil else { return }
        
        while let line = readLine() {
        }
    }
}

private extension RootViewModel {
    
    func scan(headerString: String) throws -> [String: String] {
        let scanner = Scanner(string: headerString)
        scanner.charactersToBeSkipped = ["="]
        var result: [String: String] = [:]
        var currentKey = ""
        
        while !scanner.isAtEnd {
            print(scanner.currentIndex)
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
}

class MockRootViewModel: RootViewModelProtocol {
    func readFile(url: URL) {
        
    }
}
