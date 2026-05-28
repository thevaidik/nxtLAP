//
//  ContentView.swift
//  motorsports
//
//  Created by Vaidik Dubey on 11/07/25.
//

import SwiftUI
import Amplify

struct ContentView: View {
    @StateObject private var authVM = AuthenticationViewModel()
    @EnvironmentObject var userVM: UserViewModel
    
    var body: some View {
        MainTabView()
            .environmentObject(authVM)
            .transition(.opacity)
            .task {
                await authVM.checkSession()
            }
            .onChange(of: authVM.isAuthenticated) {
                if authVM.isAuthenticated {
                    Task {
                        await userVM.fetchProfile()
                    }
                }
            }
    }
}

#Preview {
    ContentView()
}
