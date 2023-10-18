//
//  PrecipitationModel.swift
//  JBAChallenge
//
//  Created by cabbage on 2023/10/16.
//

import Foundation

struct PrecipitationModel {
    struct Grid: CustomStringConvertible {
        let x: Int
        let y: Int
        
        var rows: [[Int]] { _rows }
        
        private var _rows: [[Int]]
        
        init(x: Int, y: Int, _rows: [[Int]] = []) {
            self.x = x
            self.y = y
            self._rows = _rows
        }
        
        mutating func appendRow(_ row: [Int]) {
            _rows.append(row)
        }
        
        var description: String {
            var string: String = "Grid-ref= \(x),\(y)"
            for row in rows {
                string.append(row.reduce(into: "\n", { $0.append("\($1) ") }))
            }
            return string
        }
    }
    
    let fromYear: Int
    let toYear: Int
    
    let grids: [Grid]
}

extension PrecipitationModel.Grid {
    static let mock: PrecipitationModel.Grid = .init(x: 1, y: 2, _rows:
                                                        [[3020, 2820, 3040, 2880, 1740, 1360, 980],
                                                         [3020, 2820, 3040, 2880, 1740, 1360, 980],
                                                         [3020, 2820, 3040, 2880, 1740, 1360, 980],
                                                         [3020, 2820, 3040, 2880, 1740, 1360, 980],
                                                         [3020, 2820, 3040, 2880, 1740, 1360, 980],
                                                         [3020, 2820, 3040, 2880, 1740, 1360, 980],
                                                         [3020, 2820, 3040, 2880, 1740, 1360, 980]])
}
