//
//  LoadingViewModifier.swift
//  JBAChallenge
//
//  Created by cabbage on 2023/10/20.
//  Reference: https://betterprogramming.pub/swiftui-create-a-fancy-toast-component-in-10-minutes-e6bae6021984
//

import SwiftUI

struct LoadingViewModifier: ViewModifier {
    @Binding var loading: LoadingModel?
    
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(
                ZStack {
                    if let loading {
                        LoadingView(message: loading.message)
                    }
                }
            )
    }
}

extension View {
    func loadingView(_ loading: Binding<LoadingModel?>) -> some View {
        self.modifier(LoadingViewModifier(loading: loading))
    }
}
