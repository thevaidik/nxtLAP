//  Created by Vaidik Dubey on 11/07/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var dataService: RacingDataService
    @Binding var selectedTab: MainTabView.Tab
    @Binding var selectedUpcomingTab: UpcomingRacesView.UpcomingTab
    
    var nextRace: Race? {
        dataService.upcomingRacesForStarredSeries.first
    }
    
    var upcomingStarredRaces: [Race] {
        Array(dataService.upcomingRacesForStarredSeries.prefix(5))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header Section
                    VStack(spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("NxtLAP")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Your Racing Dashboard")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "flag.checkered.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.racingRed)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 24)
                    }
                    
                    // Main Content
                    if dataService.starredSeriesList.isEmpty {
                        emptyStateView
                    } else {
                        racesContentView
                    }
                }
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color(.systemGray6).opacity(0.1),
                        Color.black
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 32) {
            Spacer()
                .frame(height: 60)
            
            // Animated Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .racingRed.opacity(0.2),
                                .racingRed.opacity(0.05)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.racingRed, .orange]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 12) {
                Text("No Favorites Yet")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Start by adding your favorite racing series to see upcoming races here")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .lineSpacing(4)
            }
            
            // Call to Action
            VStack(spacing: 16) {
                Button(action: {
                    selectedTab = .all
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text("Browse Racing Series")
                            .font(.body)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.racingRed, .racingRed.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                }
                .padding(.horizontal, 32)
                
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("Tap the star icon next to any series to add it")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Races Content
    private var racesContentView: some View {
        VStack(spacing: 24) {
            // Next Race Hero Card
            if let next = nextRace {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Next Race")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text(timeUntilRace(next.date))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.racingRed)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.racingRed.opacity(0.15))
                            )
                    }
                    .padding(.horizontal, 20)
                    
                    NextRaceCard(race: next)
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 8)
            }
            
            // Upcoming Races List
            if !upcomingStarredRaces.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Upcoming Races")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            selectedUpcomingTab = .my
                            selectedTab = .upcoming
                        }) {
                            HStack(spacing: 4) {
                                Text("View All")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                            }
                            .foregroundColor(.racingRed)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    LazyVStack(spacing: 12) {
                        ForEach(upcomingStarredRaces) { race in
                            CompactRaceRow(race: race)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            
            // Quick Stats
            StatsSection()
                .padding(.horizontal, 20)
                .padding(.top, 8)
            
            Spacer()
                .frame(height: 40)
        }
        .padding(.top, 8)
    }
    
    private func timeUntilRace(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        let components = calendar.dateComponents([.day, .hour], from: now, to: date)
        if let days = components.day, let hours = components.hour {
            if days == 0 {
                if hours == 0 {
                    return "Starting Soon"
                }
                return "in \(hours)h"
            } else if days == 1 {
                return "Tomorrow"
            } else {
                return "in \(days) days"
            }
        }
        return ""
    }
}

// MARK: - Next Race Card
struct NextRaceCard: View {
    let race: Race
    @EnvironmentObject var dataService: RacingDataService
    
    var raceSeries: RacingSeries? {
        dataService.allSeries.first { $0.shortName == race.series }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Series Badge
            HStack {
                Text(race.series)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.racingRed, .orange]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                
                Spacer()
            }
            
            // Race Name
            Text(race.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .lineLimit(2)
            
            // Location & Date
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "location.fill")
                        .font(.subheadline)
                        .foregroundColor(.racingRed)
                        .frame(width: 20)
                    
                    Text(race.location)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                HStack(spacing: 10) {
                    Image(systemName: "calendar")
                        .font(.subheadline)
                        .foregroundColor(.racingRed)
                        .frame(width: 20)
                    
                    Text(formattedDate(race.date))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.systemGray6).opacity(0.15),
                            Color(.systemGray6).opacity(0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.racingRed.opacity(0.3), .orange.opacity(0.2)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d 'at' h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Compact Race Row
struct CompactRaceRow: View {
    let race: Race
    @EnvironmentObject var dataService: RacingDataService
    
    var raceSeries: RacingSeries? {
        dataService.allSeries.first { $0.shortName == race.series }
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Color Indicator
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [.racingRed, .orange]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 4, height: 50)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(race.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(race.series)
                        .font(.caption)
                        .foregroundColor(.racingRed)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(race.location)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(shortDate(race.date))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(timeUntil(race.date))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6).opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
        )
    }
    
    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    private func timeUntil(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: now, to: date)
        if let days = components.day {
            if days == 0 { return "Today" }
            if days == 1 { return "Tomorrow" }
            return "\(days)d"
        }
        return ""
    }
}

// MARK: - Stats Section
struct StatsSection: View {
    @EnvironmentObject var dataService: RacingDataService
    
    var body: some View {
        HStack(spacing: 12) {
            StatCard(
                icon: "star.fill",
                value: "\(dataService.starredSeriesList.count)",
                label: "Series",
                color: .yellow
            )
            
            StatCard(
                icon: "calendar",
                value: "\(dataService.upcomingRacesForStarredSeries.count)",
                label: "Races",
                color: .racingRed
            )
            
            StatCard(
                icon: "flag.checkered.2.crossed",
                value: "\(dataService.allSeries.count)",
                label: "Total",
                color: .blue
            )
        }
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemGray6).opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    @Previewable @State var selectedTab: MainTabView.Tab = .home
    @Previewable @State var selectedUpcomingTab: UpcomingRacesView.UpcomingTab = .all
    HomeView(selectedTab: $selectedTab, selectedUpcomingTab: $selectedUpcomingTab)
        .environmentObject(RacingDataService())
}
