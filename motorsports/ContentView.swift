//
//  ContentView.swift
//  motorsports
//
//  Created by Vaidik Dubey on 11/07/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authVM = AuthenticationViewModel()
    
    var body: some View {
        MainTabView()
            .environmentObject(authVM)
            .transition(.opacity)
    }
}

#Preview {
    ContentView()
}
