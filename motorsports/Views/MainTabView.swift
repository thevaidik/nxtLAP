//  Created by Vaidik Dubey on 11/07/25.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var racingDataService = RacingDataService()

    var body: some View {
        TabView {
            
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            UpcomingRacesView()
                .tabItem {
                    Label("Upcoming", systemImage: "calendar")
                    
                }
            
            MyRacesView()
                .tabItem {
                    Label("My Races", systemImage: "star.fill")
                }
            
            AllRacesView()
                .tabItem {
                    Label("All", systemImage: "flag.fill")
                }
            
        }
        .accentColor(.racingRed)
        .preferredColorScheme(.dark)
        .environmentObject(racingDataService)
    }
}

#Preview {
    MainTabView()
}
