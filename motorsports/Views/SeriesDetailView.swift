//
//  SeriesDetailView.swift
//  motorsports
//
//  Created by Vaidik Dubey on 20/08/25.
//

import SwiftUI

struct SeriesDetailView: View {
    let series: RacingSeries
    @EnvironmentObject var dataService: RacingDataService
    
    var seriesRaces: [Race] {
        dataService.getRacesForSeries(series.shortName)
    }
    
    private var sortedSeriesRaces: [Race] {
        seriesRaces.sorted { $0.date < $1.date }
    }
    
    private var upcomingMonthRaces: [Race] {
        let now = Date()
        guard let oneMonthFromNow = Calendar.current.date(byAdding: .month, value: 1, to: now) else {
            return []
        }
        
        return sortedSeriesRaces.filter { race in
            race.date >= now && race.date <= oneMonthFromNow
        }
    }
    
    private var otherSessionRaces: [Race] {
        let upcomingIDs = Set(upcomingMonthRaces.map(\.id))
        return sortedSeriesRaces.filter { !upcomingIDs.contains($0.id) }
    }
    
    private var nextRaceName: String {
        let now = Date()
        return sortedSeriesRaces.first(where: { $0.date >= now })?.name ?? "No upcoming race"
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Series Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Series")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            ZStack {
                                Rectangle()
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [.racingRed, .orange]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 6, height: 45)
                                    .cornerRadius(16)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text(series.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text(series.category.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 10) {
                                // Notifications Toggle
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        dataService.toggleNotificationsForSeries(series.shortName)
                                        HapticManager.shared.trigger(.medium)
                                    }
                                }) {
                                    Image(systemName: dataService.areNotificationsEnabled(for: series.shortName) ? "bell.fill" : "bell")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(dataService.areNotificationsEnabled(for: series.shortName) ? .nxtlapRacingRed : .gray)
                                        .padding(7)
                                        .background(Color(.systemGray5))
                                        .clipShape(Circle())
                                }

                                // Star Toggle
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        dataService.toggleStarredSeries(series.shortName)
                                        HapticManager.shared.trigger(.medium)
                                    }
                                }) {
                                    Image(systemName: dataService.isSeriesStarred(series.shortName) ? "star.fill" : "star")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(dataService.isSeriesStarred(series.shortName) ? .yellow : .gray)
                                        .padding(7)
                                        .background(Color(.systemGray5))
                                        .clipShape(Circle())
                                }
                            }
                        }
                        
                        HStack(spacing: 8) {
                            InfoPill(title: "Next race", value: nextRaceName, icon: "flag.checkered")
                            InfoPill(title: "Sessions", value: "\(sortedSeriesRaces.count)", icon: "calendar")
                        }
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )
                )
                
                // Upcoming Sessions (next 1 month)
                if upcomingMonthRaces.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Upcoming Sessions")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 14)
                        
                        VStack(spacing: 8) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 24))
                                .foregroundColor(.gray)
                            Text("No sessions in the next month")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    }
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                            )
                    )
                } else {
                    let chunks = upcomingMonthRaces.chunked(into: 12)
                    ForEach(Array(chunks.enumerated()), id: \.offset) { index, chunk in
                        VStack(alignment: .leading, spacing: 8) {
                            if index == 0 {
                                Text("Upcoming Sessions")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 14)
                            }
                            
                            TabView {
                                ForEach(chunk) { race in
                                    SeriesRaceCard(race: race, series: series)
                                        .padding(.horizontal, 14)
                                        .padding(.bottom, 44) // Space for dots
                                }
                            }
                            .tabViewStyle(.page(indexDisplayMode: .always))
                            .frame(height: 310)
                        }
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(.systemGray6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                )
                        )
                    }
                }
                
                // Official Website (Optional)
                if let websiteUrl = series.officialWebsite, !websiteUrl.isEmpty, let url = URL(string: websiteUrl) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Official Website")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Link(destination: url) {
                            HStack {
                                Image(systemName: "globe")
                                    .font(.subheadline)
                                    .foregroundColor(.racingRed)
                                Text(websiteUrl)
                                    .font(.callout)
                                    .foregroundColor(.racingRed)
                                    .lineLimit(1)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundColor(.racingRed)
                            }
                            .padding(10)
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                            )
                    )
                }
                
                // About Section (always expanded)
                VStack(alignment: .leading, spacing: 6) {
                    Text("About \(series.name)")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(series.aboutText)
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )
                )
                
                // Other Sessions (all remaining)
                if otherSessionRaces.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Other Sessions")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 14)
                        
                        VStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .font(.system(size: 24))
                                .foregroundColor(.gray)
                            Text("No other sessions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    }
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                            )
                    )
                } else {
                    let chunks = otherSessionRaces.chunked(into: 12)
                    ForEach(Array(chunks.enumerated()), id: \.offset) { index, chunk in
                        VStack(alignment: .leading, spacing: 8) {
                            if index == 0 {
                                Text("Other Sessions")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 14)
                            }
                            
                            TabView {
                                ForEach(chunk) { race in
                                    SeriesRaceCard(race: race, series: series)
                                        .padding(.horizontal, 14)
                                        .padding(.bottom, 44) // Space for dots
                                }
                            }
                            .tabViewStyle(.page(indexDisplayMode: .always))
                            .frame(height: 310)
                        }
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(.systemGray6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                )
                        )
                    }
                }
            }
            .padding(12)
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
        .navigationTitle(series.shortName)
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }
}

struct SeriesRaceCard: View {
    let race: Race
    let series: RacingSeries
    @EnvironmentObject var notificationManager: NotificationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thumbnail with Play Button Overlay
            ZStack {
                // Placeholder background with series color/gradient
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.nxtlapRacingRed.opacity(0.8), Color.orange.opacity(0.6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .aspectRatio(16/9, contentMode: .fit)
                
                // Series Icon or Name as placeholder
                VStack(spacing: 4) {
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.4))
                    Text(series.shortName)
                        .font(.caption2)
                        .fontWeight(.black)
                        .foregroundColor(.white.opacity(0.4))
                }
                
                // Play Button UI (from WatchView)
                ZStack {
                    Circle()
                        .fill(.black.opacity(0.4))
                        .frame(width: 50, height: 50)
                        .blur(radius: 1)
                    
                    Image(systemName: "play.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .offset(x: 2)
                }
                .background(Circle().stroke(Color.white.opacity(0.3), lineWidth: 2))
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Content Section
            VStack(alignment: .leading, spacing: 6) {
                Text(race.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption2)
                    Text(race.location)
                        .font(.caption)
                }
                .foregroundColor(.gray)
                .lineLimit(1)
                
                Text(formattedDate(race))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.nxtlapRacingRed)
            }
            .padding(10)
        }
        .background(Color(white: 0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func formattedDate(_ race: Race) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        var s = formatter.string(from: race.date)
        if race.hasExactTime {
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            s += " • " + timeFormatter.string(from: race.date)
        }
        return s
    }
}

struct SeriesRaceRow: View {
    let race: Race
    @EnvironmentObject var notificationManager: NotificationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(race.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                
                Spacer()
                
                Text(formattedDate(race))
                    .font(.caption2)
                    .foregroundColor(.racingRed)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.trailing)
            }
            
            HStack {
                Image(systemName: "location")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(race.location)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(timeUntilRace(race.date).uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.racingRed.opacity(0.9))
            }
            
            if let circuit = race.circuit {
                Text(circuit)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(10)
        .background(Color(.systemGray5).opacity(0.75))
        .cornerRadius(8)
    }
    
    private func formattedDate(_ race: Race) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = race.hasExactTime ? .short : .none
        return formatter.string(from: race.date)
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

struct InfoPill: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(.racingRed)
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(.systemGray5))
        .cornerRadius(8)
    }
}

#Preview {
    NavigationView {
        SeriesDetailView(
            series: RacingSeries(
                name: "Formula 1",
                shortName: "F1",
                category: .formula,
                description: "The pinnacle of motorsport",
                iconName: "f1.circle",
                officialWebsite: "https://www.formula1.com",
                aboutText: "Formula One is the highest class of international racing..."
            )
        )
        .environmentObject(RacingDataService())
    }
}
