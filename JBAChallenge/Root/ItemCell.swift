//
//  ItemCell.swift
//  JBAChallenge
//
//  Created by cabbage on 2023/10/18.
//

import SwiftUI

struct ItemCell: View {

    @State var columns: [String]
    @State var isHeader: Bool = false
    
    var body: some View {
        HStack {
            ForEach(0..<columns.count, id: \.self) { index in
                Text(columns[index])
                    .font(isHeader ? .headline : .body)
                    .frame(width: 100)
            }
        }
    }
}

#Preview {
    ItemCell(columns: ["Xref", "Yref", "Date", "Value"])
}
