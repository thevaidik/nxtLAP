//
//  HomeView.swift
//  motorsports
//
//  Created by Vaidik Dubey on 11/07/25.
//

import SwiftUI

struct WeekendGroup: Identifiable {
    let id = UUID()
    let weekendName: String
    let location: String
    let sessions: [Race]
    let series: String
}

struct HomeView: View {
    @EnvironmentObject var dataService: RacingDataService
    @Binding var selectedTab: MainTabView.Tab
    @Binding var selectedUpcomingTab: UpcomingRacesView.UpcomingTab
    
    var nextRace: Race? {
        dataService.upcomingRacesForStarredSeries.first
    }
    
    var upcomingWeekendGroups: [WeekendGroup] {
        let allUpcoming = dataService.upcomingRacesForStarredSeries
        guard !allUpcoming.isEmpty else { return [] }
        
        var groups: [String: [Race]] = [:]
        for race in allUpcoming {
            let key = "\(race.series)_\(race.location)"
            groups[key, default: []].append(race)
        }
        
        let mapped = groups.compactMap { key, sessions -> WeekendGroup? in
            guard let first = sessions.sorted(by: { $0.date < $1.date }).first else { return nil }
            let components = first.name.components(separatedBy: " - ")
            let displayName = components.first ?? first.name
            return WeekendGroup(weekendName: displayName, location: first.location, sessions: sessions.sorted { $0.date < $1.date }, series: first.series)
        }
        
        let sortedGroups = mapped.sorted { 
            let d1 = $0.sessions.first?.date ?? Date.distantFuture
            let d2 = $1.sessions.first?.date ?? Date.distantFuture
            return d1 < d2
        }
        
        return Array(sortedGroups.prefix(5))
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
                            
                            // Bell with small gear
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.racingRed)
                                    .shadow(color: .racingRed.opacity(0.3), radius: 5, x: 0, y: 2)
                                
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.orange)
                                    .offset(x: 4, y: -4)
                            }
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
                        
                        Text("Pick your Favorites")
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
                        
                        Text(timeUntilRaceDetails(next.date))
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
            if !upcomingWeekendGroups.isEmpty {
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
                    
                    LazyVStack(spacing: 20) {
                        ForEach(upcomingWeekendGroups) { group in
                            UpcomingWeekendCard(group: group)
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
    
    private func timeUntilRaceDetails(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour, .minute], from: now, to: date)
        
        if let days = components.day, let hours = components.hour, let mins = components.minute {
            if days > 0 {
                return "in \(days)d : \(hours)h : \(mins)m"
            } else if hours > 0 {
                return "in \(hours)h : \(mins)m"
            } else if mins > 0 {
                return "in \(mins)m"
            } else {
                return "Starting Soon"
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
        VStack(alignment: .leading, spacing: 12) {
            Text(race.series)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.systemGray5).opacity(0.8))
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            
            // Race Name
            Text(race.name)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .lineLimit(1)
            
            // Location & Date
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    Image(systemName: "location.north.fill")
                        .font(.caption)
                        .foregroundColor(.racingRed)
                        .rotationEffect(.degrees(45))
                    
                    Text(race.location)
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Image(systemName: "circle.fill")
                                .resizable()
                                .foregroundColor(.red) // Placeholder for flag
                        )
                        .overlay(Circle().stroke(Color.white, lineWidth: 1))
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.racingRed)
                    
                    Text(formattedDate(race.date))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack(alignment: .trailing) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 35/255, green: 35/255, blue: 35/255),
                                Color(red: 20/255, green: 20/255, blue: 20/255)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Dim outline graphic like circuit
                Image(systemName: "triangle")
                    .font(.system(size: 140))
                    .foregroundColor(.white.opacity(0.03))
                    .offset(x: 30, y: 10)
                    .rotationEffect(.degrees(10))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.racingRed.opacity(0.4), .orange.opacity(0.1)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .cornerRadius(16)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d 'at' HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Upcoming Weekend Card
struct UpcomingWeekendCard: View {
    let group: WeekendGroup
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Image/Circuit
            HStack {
                Image(systemName: "point.topleft.down.curvedto.point.bottomright.up") // Placeholder for circuit outline
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Text(group.series)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5).opacity(0.8))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            Text(group.weekendName)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            
            // Sessions
            VStack(spacing: 8) {
                ForEach(group.sessions) { session in
                    SessionRow(race: session, groupSeries: group.series)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 25/255, green: 25/255, blue: 25/255))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(white: 0.2), lineWidth: 1)
        )
    }
}

// MARK: - Session Row
struct SessionRow: View {
    let race: Race
    let groupSeries: String
    
    var sessionType: String {
        let name = race.name.uppercased()
        if name.contains("SPRINT") { return "Sprint" }
        if name.contains("PRACTICE 1") || name.contains("FP1") { return "FP1" }
        if name.contains("PRACTICE 2") || name.contains("FP2") { return "FP2" }
        if name.contains("PRACTICE 3") || name.contains("FP3") { return "FP3" }
        if name.contains("QUALIFYING") || name.contains("QUALI") { return "Quali" }
        return "Race"
    }
    
    var sessionColor: Color {
        let name = race.name.uppercased()
        if name.contains("SPRINT") { return .orange }
        if name.contains("PRACTICE 1") || name.contains("FP1") { return .racingRed }
        if name.contains("PRACTICE 2") || name.contains("FP2") { return .purple }
        if name.contains("PRACTICE 3") || name.contains("FP3") { return .blue }
        if name.contains("QUALIFYING") || name.contains("QUALI") { return .green }
        
        let colors: [Color] = [.racingRed, .blue, .green, .orange, .purple, .pink, .cyan, .mint, .indigo, .teal]
        let index = abs(race.name.hashValue) % colors.count
        return colors[index]
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Colored Pill
            Text(sessionType)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 44, height: 22)
                .background(sessionColor)
                .clipShape(Capsule())
            
            // Date String
            Text(sessionDateString(race.date))
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Spacer()
            
            // Countdown text
            Text(countdownText(for: race.date))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(sessionColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule().fill(sessionColor.opacity(0.15))
                )
        }
    }
    
    private func sessionDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d"
        return formatter.string(from: date)
    }
    
    private func countdownText(for date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour], from: now, to: date)
        
        guard let days = components.day, let hours = components.hour else { return "" }
        if days == 0 {
            return hours == 0 ? "starts soon" : "in \(hours)h"
        } else {
            return "in \(days)d"
        }
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

// MARK: - Color Helper
func seriesColor(for seriesName: String) -> Color {
    let colors: [Color] = [.red, .blue, .green, .orange, .purple, .cyan, .pink, .indigo, .mint, .yellow]
    let index = abs(seriesName.hashValue) % colors.count
    return colors[index]
}

#Preview {
    @Previewable @State var selectedTab: MainTabView.Tab = .home
    @Previewable @State var selectedUpcomingTab: UpcomingRacesView.UpcomingTab = .all
    HomeView(selectedTab: $selectedTab, selectedUpcomingTab: $selectedUpcomingTab)
        .environmentObject(RacingDataService())
}
