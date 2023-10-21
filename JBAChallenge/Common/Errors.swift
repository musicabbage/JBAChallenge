//
//  Errors.swift
//  JBAChallenge
//
//  Created by cabbage on 2023/10/13.
//

import Foundation

enum Error: Swift.Error, LocalizedError {
    case parseYearsError
    case invalidGridRef
    case transactionNotExisted
    
    var errorDescription: String? {
        switch self {
        case .parseYearsError: "Parse years info failed"
        case .invalidGridRef: "Parse grid info failed"
        case .transactionNotExisted: "Transaction not existed"
        }
    }
}
