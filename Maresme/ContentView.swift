 //
//  ContentView.swift
//  Maresme
//
//  Created by Oscar Llorente Serrano on 09/06/2026.
//
//  NOTE: This file is kept for backward compatibility with Xcode previews.
//  The app entry point now renders AppRootView via MaresmeApp.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        AppRootView()
            .environment(SessionManager())
    }
}

#Preview {
    ContentView()
}
