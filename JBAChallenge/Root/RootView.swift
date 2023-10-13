//
//  RootView.swift
//  JBAChallenge
//
//  Created by cabbage on 2023/10/12.
//

import SwiftUI

struct RootView: View {
    
    @State private var rowLogs: [Int] = Array(0..<10)
    @State private var add: Bool = false
    @State private var fileUrl: URL?
    
    var body: some View {
        NavigationSplitView(sidebar: {
            NavigationView {
                VStack {
                    List($rowLogs, id: \.self) { log in
                        Text("\(log.wrappedValue)")
                    }
                    Button("Import") {
                        add = true
                    }
                    .padding()
                }
            }
        }, detail: {
            if let fileUrl {
                Text(fileUrl.absoluteString)
            } else {
                Text("import file")
            }
        })
        .sheet(isPresented: $add, content: {
            FilePickerView(fileUrl: $fileUrl)
        })
    }
}

private extension RootView {
}

#Preview {
    RootView()
}
