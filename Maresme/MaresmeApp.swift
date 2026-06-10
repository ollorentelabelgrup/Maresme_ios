//
//  MaresmeApp.swift
//  Maresme
//
//  Created by Oscar Llorente Serrano on 09/06/2026.
//

import SwiftUI

@main
struct MaresmeApp: App {
    @State private var session = SessionManager()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(session)
        }
    }
}
