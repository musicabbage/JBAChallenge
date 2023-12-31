//
//  JBAChallengeApp.swift
//  JBAChallenge
//
//  Created by cabbage on 2023/10/12.
//

import SwiftUI

@main
struct JBAChallengeApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            let rootViewModel: RootViewModel = .init()
            RootView(viewModel: rootViewModel)
        }
    }
}
