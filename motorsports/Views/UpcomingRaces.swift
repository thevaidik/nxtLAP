//
//  UpcomingRaces.swift
//  motorsports
//
//  Created by Vaidik Dubey on 11/07/25.
//

import SwiftUI

struct UpcomingRacesView: View {
    @EnvironmentObject var dataService: RacingDataService
    @State private var selectedTab: UpcomingTab = .all
    
    enum UpcomingTab: String, CaseIterable {
        case all = "All Upcoming"
        case my = "My Upcoming"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Tab picker with sleek design
                HStack(spacing: 0) {
                    ForEach(UpcomingTab.allCases, id: \.self) { tab in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedTab = tab
                            }
                        }) {
                            Text(tab.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(selectedTab == tab ? .white : .gray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedTab == tab ? 
                                              LinearGradient(
                                                gradient: Gradient(colors: [.racingRed, .racingRed.opacity(0.8)]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                              ) : 
                                              LinearGradient(
                                                gradient: Gradient(colors: [Color.clear]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                              )
                                        )
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6).opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                
                Group {
                    switch selectedTab {
                    case .all:
                        AllUpcomingView()
                    case .my:
                        MyUpcomingView()
                    }
                }
            }
            .background(Color.black)
            .navigationTitle("Upcoming Races")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }
}

struct AllUpcomingView: View {
    @EnvironmentObject var dataService: RacingDataService
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(dataService.upcomingRaces) { race in
                    UpcomingRaceRow(race: race)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemGray6).opacity(0.05),
                    Color(.systemGray5).opacity(0.1),
                    Color(.systemGray6).opacity(0.05)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

struct MyUpcomingView: View {
    @EnvironmentObject var dataService: RacingDataService
    
    var body: some View {
        Group {
            if dataService.upcomingRacesForStarredSeries.isEmpty {
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [.racingRed.opacity(0.3), .racingRed.opacity(0.1)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.racingRed)
                    }
                    
                    VStack(spacing: 8) {
                        Text("No Upcoming Races")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Star racing series in the 'All' tab to see their upcoming races here")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.systemGray6).opacity(0.05),
                            Color(.systemGray5).opacity(0.1),
                            Color(.systemGray6).opacity(0.05)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(dataService.upcomingRacesForStarredSeries) { race in
                            UpcomingRaceRow(race: race)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .background(Color.black)
            }
        }
    }
}

struct UpcomingRaceRow: View {
    let race: Race
    @EnvironmentObject var dataService: RacingDataService
    
    var raceSeries: RacingSeries? {
        dataService.allSeries.first { $0.shortName == race.series }
    }
    
    var body: some View {
        Group {
            if let series = raceSeries {
                NavigationLink(destination: SeriesDetailView(series: series)) {
                    raceContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                raceContent
            }
        }
    }
    
    private var raceContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(race.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "location")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        
                        Text(race.location)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Text(race.series)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [.racingRed.opacity(0.3), .racingRed.opacity(0.1)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                        )
                        .foregroundColor(.racingRed)
                    
                    if raceSeries != nil {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundColor(.racingRed)
                    
                    Text(formattedDate(race.date))
                        .font(.caption)
                        .foregroundColor(.racingRed)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                Text(timeUntilRace(race.date))
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6).opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func timeUntilRace(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        let components = calendar.dateComponents([.day], from: now, to: date)
        if let dayCount = components.day {
            if dayCount == 0 {
                return "Today"
            } else if dayCount == 1 {
                return "Tomorrow"
            } else if dayCount > 0 {
                return "in \(dayCount) days"
            } else {
                return "Past"
            }
        }
        return ""
    }
}

#Preview {
    UpcomingRacesView()
        .environmentObject(RacingDataService())
}
