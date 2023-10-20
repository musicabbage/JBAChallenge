//
//  LoadingView.swift
//  JBAChallenge
//
//  Created by cabbage on 2023/10/20.
//

import SwiftUI

struct LoadingModel: Equatable {
    var message: String = "loading"
}

struct LoadingView: View {
    let message: String
    
    var body: some View {
        ProgressView(message)
            .padding(12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerSize: .init(width: 8, height: 8)))
            .shadow(radius: 8)
    }
}

#Preview {
    LoadingView(message: "Loading")
}
