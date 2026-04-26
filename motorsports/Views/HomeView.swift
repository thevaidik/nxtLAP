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
    @EnvironmentObject var livestreamViewModel: LivestreamViewModel
    @Binding var selectedTab: MainTabView.Tab
    @StateObject private var newsViewModel = NewsViewModel()
    
    private enum HomeWeekSegment: String, CaseIterable {
        case thisWeek = "This week"
        case nextWeek = "Next week"
    }
    
    @State private var weekSegment: HomeWeekSegment = .thisWeek
    
    private func isInThisWeek(_ date: Date) -> Bool {
        Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    private func isInNextWeek(_ date: Date) -> Bool {
        let cal = Calendar.current
        guard let thisWeekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())),
              let nextWeekStart = cal.date(byAdding: .weekOfYear, value: 1, to: thisWeekStart) else { return false }
        return cal.isDate(date, equalTo: nextWeekStart, toGranularity: .weekOfYear)
    }
    
    /// Grouped weekends, sorted by first session; title uses the **last** session (e.g. Grand Prix race), not practice.
    private var upcomingWeekendGroups: [WeekendGroup] {
        let allUpcoming = dataService.upcomingRacesForStarredSeries
        guard !allUpcoming.isEmpty else { return [] }
        
        var groups: [String: [Race]] = [:]
        for race in allUpcoming {
            let venueKey: String
            if let circuit = race.circuit, !circuit.isEmpty {
                venueKey = circuit
            } else {
                let words = race.name.components(separatedBy: " ")
                venueKey = words.prefix(2).joined(separator: " ")
            }
            let key = "\(race.series)_\(venueKey)"
            groups[key, default: []].append(race)
        }
        
        let mapped = groups.compactMap { _, sessions -> WeekendGroup? in
            let sortedSessions = sessions.sorted { $0.date < $1.date }
            guard let lastForTitle = sortedSessions.last,
                  let firstForMeta = sortedSessions.first else { return nil }
            let components = lastForTitle.name.components(separatedBy: " - ")
            let displayName = components.first ?? lastForTitle.name
            return WeekendGroup(
                weekendName: displayName,
                location: firstForMeta.location,
                sessions: sortedSessions,
                series: firstForMeta.series
            )
        }
        
        return mapped.sorted {
            let d1 = $0.sessions.first?.date ?? Date.distantFuture
            let d2 = $1.sessions.first?.date ?? Date.distantFuture
            return d1 < d2
        }
    }
    
    private var thisWeekGroups: [WeekendGroup] {
        upcomingWeekendGroups.filter { g in
            guard let start = g.sessions.map(\.date).min() else { return false }
            return isInThisWeek(start)
        }
    }
    
    private var nextWeekGroups: [WeekendGroup] {
        upcomingWeekendGroups.filter { g in
            guard let start = g.sessions.map(\.date).min() else { return false }
            return isInNextWeek(start)
        }
    }
    
    private var activeWeekGroups: [WeekendGroup] {
        switch weekSegment {
        case .thisWeek: return thisWeekGroups
        case .nextWeek: return nextWeekGroups
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header Section with Stories
                    VStack(spacing: 0) {
                        HStack {
                            Text("NxtLAP")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(dataService.isDevMode ? .green : .white)
                                .onTapGesture(count: 6) {
                                    dataService.toggleDevMode()
                                }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // News Stories - Instagram style
                        NewsStoriesView(newsViewModel: newsViewModel)
                            .padding(.top, 16)
                            .padding(.bottom, 8)
                        
                        // Watch Now Carousel - suggests from Watch tab
                        WatchNowCarouselView()
                            .padding(.top, 8)
                            .padding(.bottom, 16)
                    }
                    
                    // Main Content
                    if dataService.isLoadingData && dataService.upcomingRaces.isEmpty {
                        RacingLoadingView()
                            .padding(.top, 40)
                    } else if dataService.starredSeriesList.isEmpty {
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
        .task {
            if newsViewModel.articles.isEmpty {
                await newsViewModel.fetchNews()
            }
            // Fetch livestreams to update "LIVE" badges in carousel
            if livestreamViewModel.streams.isEmpty {
                await livestreamViewModel.fetchLivestreams()
            }
        }
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
                    selectedTab = .settings
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
        VStack(spacing: 28) {
            if upcomingWeekendGroups.isEmpty {
                Text("No upcoming sessions for your favorite series right now.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
            }
            
            if thisWeekGroups.isEmpty && nextWeekGroups.isEmpty && !upcomingWeekendGroups.isEmpty {
                Text("No races in this week or next week — check back soon.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            if !upcomingWeekendGroups.isEmpty && (!thisWeekGroups.isEmpty || !nextWeekGroups.isEmpty) {
                Picker("Week", selection: $weekSegment) {
                    ForEach(HomeWeekSegment.allCases, id: \.self) { segment in
                        Text(segment.rawValue).tag(segment)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.bottom, 12)
            }
            
            if !activeWeekGroups.isEmpty {
                LazyVStack(spacing: 14) {
                    ForEach(Array(activeWeekGroups.enumerated()), id: \.element.id) { index, group in
                        UpcomingWeekendCard(
                            group: group,
                            prominence: index == 0 ? .primary : .compact
                        )
                    }
                }
                .padding(.horizontal, 20)
            } else if !thisWeekGroups.isEmpty || !nextWeekGroups.isEmpty {
                Text(weekSegment == .thisWeek ? "No races this week." : "No races next week.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
            }
            
            HStack {
                Spacer()
                Button(action: { selectedTab = .watch }) {
                    HStack(spacing: 6) {
                        Image(systemName: "play.rectangle.fill")
                        Text("Watch live")
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .foregroundColor(.racingRed)
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
                .frame(height: 40)
        }
        .padding(.top, 8)
    }
}

// MARK: - Upcoming Weekend Card
enum WeekendCardProminence {
    case primary
    case compact
}

struct UpcomingWeekendCard: View {
    let group: WeekendGroup
    var prominence: WeekendCardProminence = .primary
    
    private var venueLine: String {
        let loc = group.location
        if let c = group.sessions.first?.circuit, !c.isEmpty {
            return "\(loc) · \(c)"
        }
        return loc
    }
    
    private var isPrimary: Bool { prominence == .primary }
    
    var body: some View {
        let corner: CGFloat = isPrimary ? 20 : 16
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: isPrimary ? 10 : 6) {
                HStack {
                    Text(group.series)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.95))
                        .padding(.horizontal, isPrimary ? 10 : 8)
                        .padding(.vertical, isPrimary ? 5 : 4)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.08))
                                .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
                        )
                    Spacer()
                }
                
                Text(group.weekendName)
                    .font(isPrimary ? .title2 : .headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(isPrimary ? .caption : .caption2)
                        .foregroundColor(.racingRed.opacity(0.9))
                    Text(venueLine)
                        .font(isPrimary ? .subheadline : .caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(isPrimary ? 18 : 14)
            
            VStack(spacing: isPrimary ? 10 : 8) {
                ForEach(group.sessions) { session in
                    SessionRow(race: session, compact: !isPrimary)
                }
            }
            .padding(.horizontal, isPrimary ? 14 : 10)
            .padding(.bottom, isPrimary ? 16 : 12)
        }
        .background(
            RoundedRectangle(cornerRadius: corner)
                .fill(
                    LinearGradient(
                        colors: [Color(white: isPrimary ? 0.14 : 0.11), Color(white: 0.07)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: corner)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(isPrimary ? 0.14 : 0.1), .racingRed.opacity(isPrimary ? 0.28 : 0.18)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(isPrimary ? 0.35 : 0.22), radius: isPrimary ? 12 : 6, x: 0, y: isPrimary ? 6 : 3)
    }
}

// MARK: - Session Row
struct SessionRow: View {
    let race: Race
    var compact: Bool = false
    @EnvironmentObject var notificationManager: NotificationManager
    
    private var sessionColor: Color {
        // ... (keep logic)
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
        HStack(alignment: .top, spacing: compact ? 8 : 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(sessionColor)
                .frame(width: compact ? 2 : 3)
            
            VStack(alignment: .leading, spacing: compact ? 4 : 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(race.name)
                        .font(compact ? .caption : .subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer(minLength: 8)
                    
                    Text(countdownText(for: race))
                        .font(compact ? .caption2 : .caption)
                        .fontWeight(.semibold)
                        .foregroundColor(sessionColor)
                        .padding(.horizontal, compact ? 6 : 8)
                        .padding(.vertical, compact ? 3 : 4)
                        .background(Capsule().fill(sessionColor.opacity(0.18)))
                }
                
                Text(sessionWhenString(race))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, compact ? 8 : 10)
        .padding(.horizontal, compact ? 10 : 12)
        .background(
            RoundedRectangle(cornerRadius: compact ? 10 : 12)
                .fill(Color.white.opacity(0.04))
        )
    }
    
    private func sessionWhenString(_ race: Race) -> String {
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE, MMM d"
        var s = dayFormatter.string(from: race.date)
        if race.hasExactTime {
            let timeFormatter = DateFormatter()
            timeFormatter.dateStyle = .none
            timeFormatter.timeStyle = .short
            s += " · " + timeFormatter.string(from: race.date)
        }
        return s
    }
    
    private func countdownText(for race: Race) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour], from: now, to: race.date)
        
        guard let days = components.day, let hours = components.hour else { return "" }
        if days == 0 {
            if race.hasExactTime {
                return hours == 0 ? "Soon" : "in \(hours)h"
            } else {
                return "Today"
            }
        } else {
            return "in \(days)d"
        }
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
    HomeView(selectedTab: $selectedTab)
        .environmentObject(RacingDataService())
        .environmentObject(LivestreamViewModel())
}
