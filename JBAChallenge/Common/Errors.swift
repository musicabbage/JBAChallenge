//
//  Errors.swift
//  JBAChallenge
//
//  Created by cabbage on 2023/10/13.
//

import Foundation

enum Error: Swift.Error {
    case parseYearsError
    case invalidGridRef
    case transactionNotExisted
}

enum DBError: Swift.Error {
    case batchInsertError
}
