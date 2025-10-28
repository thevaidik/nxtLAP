//  Created by Vaidik Dubey on 11/07/25.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var racingDataService = RacingDataService()
    @State private var selectedTab: Tab = .home
    @State private var selectedUpcomingTab: UpcomingRacesView.UpcomingTab = .all
    
    enum Tab {
        case home, upcoming, myRaces, all
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
            
            MyRacesView()
                .tabItem {
                    Label("My Races", systemImage: "star.fill")
                }
                .tag(Tab.myRaces)
            
            AllRacesView()
                .tabItem {
                    Label("All", systemImage: "flag.fill")
                }
                .tag(Tab.all)
            
        }
        .accentColor(.racingRed)
        .preferredColorScheme(.dark)
        .environmentObject(racingDataService)
    }
}

#Preview {
    MainTabView()
}
