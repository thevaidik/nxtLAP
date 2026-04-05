//  Created by Vaidik Dubey on 11/07/25.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var racingDataService: RacingDataService
    @State private var selectedTab: Tab = .home

    enum Tab {
        case home, watch, news, standings, races
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

            NewsView()
                .tabItem {
                    Label("News", systemImage: "newspaper.fill")
                }
                .tag(Tab.news)

            StandingsView()
                .tabItem {
                    Label("Standings", systemImage: "star.fill")
                }
                .tag(Tab.standings)

            AllRacesView()
                .tabItem {
                    Label("Races", systemImage: "flag.fill")
                }
                .tag(Tab.races)

        }
        .accentColor(.racingRed)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    MainTabView()
}
