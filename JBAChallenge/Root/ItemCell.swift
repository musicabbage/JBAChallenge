//
//  ItemCell.swift
//  JBAChallenge
//
//  Created by cabbage on 2023/10/18.
//

import SwiftUI

struct ItemCell: View {

    @State private var isCellVisible: Bool = true
    @ObservedObject var item: PrecipitationItem
    var body: some View {
        HStack {
            if isCellVisible {
                Text("\(item.xref)")
                    .frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/)
                Text("\(item.yref)")
                    .frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/)
                Text(item.date ?? "")
                    .frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/)
                Text("\(item.value)")
                    .frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/)
            } else {
                EmptyView()
            }
        }
    }
}

#Preview {
    ItemCell(item: .mock)
}
