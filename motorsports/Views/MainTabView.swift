//  Created by Vaidik Dubey on 11/07/25.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var racingDataService: RacingDataService
    @EnvironmentObject var authVM: AuthenticationViewModel
    @State private var selectedTab: Tab = .home

    enum Tab {
        case home, watch, standings, fantasy, updates
    }

    var body: some View {
        TabView(selection: $selectedTab) {

            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(Tab.home)

            WatchView()
                .tabItem {
                    Label("Watch", systemImage: "play.rectangle.fill")
                }
                .tag(Tab.watch)

            StandingsView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(Tab.standings)

            Group {
                if authVM.isAuthenticated {
                    FantasyDashboardView()
                } else {
                    AuthenticationView()
                }
            }
                .tabItem {
                    Label("Market", systemImage: "building.columns.fill")
                }
                .tag(Tab.fantasy)

            UpdatesFeedView()
                .tabItem {
                    Label("Feed", systemImage: "bubble.left")
                }
                .tag(Tab.updates)
        }
        .accentColor(.racingRed)
        .preferredColorScheme(.dark)
        .onChange(of: selectedTab) {
            HapticManager.shared.selection()
        }
    }
}

#Preview {
    MainTabView()
}
