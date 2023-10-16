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

class MockRootViewModel: RootViewModelProtocol {
    func readFile(url: URL) {
        
    }
}
