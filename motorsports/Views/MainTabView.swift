import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        
        VStack(spacing: 0) {
            ZStack {
                Group {
                    switch selectedTab {
                    case 0:
                        HomeView()
                    case 1:
                        UpcomingRacesView()
                    case 2:
                        MyRacesView()
                    case 3:
                        AllRacesView()
                    default:
                        EmptyView()
                    }
                }
                .transition(.opacity)
            }
            .animation(.easeInOut(duration: 0.3), value: selectedTab)
            
            Divider()
            
            HStack {
                tabItem(icon: "house.fill", label: "Home", index: 0)
                tabItem(icon: "calendar", label: "Upcoming", index: 1)
                tabItem(icon: "star.fill", label: "My Races", index: 2)
                tabItem(icon: "flag.fill", label: "All", index: 3)
            }
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
        }
        .accentColor(.racingRed)
    }

    private func tabItem(icon: String, label: String, index: Int) -> some View {
        Button(action: {
            withAnimation {
                selectedTab = index
            }
        }
        )
        {
        VStack {
            Image(systemName: icon)
                .font(.system(size: 20))
            Text(label)
                .font(.caption)
        }
        .foregroundColor(selectedTab == index ? .racingRed : .gray)
        .frame(maxWidth: .infinity)
    }
    }
}

#Preview {
    MainTabView()
}
