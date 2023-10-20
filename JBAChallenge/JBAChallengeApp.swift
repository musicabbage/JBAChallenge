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
    let rootViewModel: RootViewModel = .init()
    
    var body: some Scene {
        WindowGroup {
            RootView(viewModel: rootViewModel)
        }
    }
}
