//
//  RootView.swift
//  JBAChallenge
//
//  Created by cabbage on 2023/10/12.
//

import SwiftUI

struct RootView: View {
    
    @State private var rowLogs: [Int] = Array(0..<10)
    
    var body: some View {
        NavigationView {
            VStack {
                List($rowLogs, id: \.self) { log in
                    Text("\(log.wrappedValue)")
                }
                Button("Import") {
                    showFileChoosePanel()
                }
                .padding()
            }
        }
    }
}

private extension RootView {
    func showFileChoosePanel() {
        
    }
}

#Preview {
    RootView()
}
