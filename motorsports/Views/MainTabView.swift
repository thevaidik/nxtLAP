//  Created by Vaidik Dubey on 11/07/25.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var racingDataService: RacingDataService
    @State private var selectedTab: Tab = .home
    @State private var selectedUpcomingTab: UpcomingRacesView.UpcomingTab = .all

    enum Tab {
        case home, upcoming, news, standings, races
    }

    var body: some View {
        TabView(selection: $selectedTab) {

            HomeView(selectedTab: $selectedTab, selectedUpcomingTab: $selectedUpcomingTab)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(Tab.home)

            UpcomingRacesView(selectedUpcomingTab: $selectedUpcomingTab)
                .tabItem {
                    Label("Upcoming", systemImage: "calendar")
                }
                .tag(Tab.upcoming)

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
