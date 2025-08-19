//
//  SeriesDetailView.swift
//  motorsports
//
//  Created by Kiro on 20/08/25.
//

import SwiftUI

struct SeriesDetailView: View {
    let series: RacingSeries
    @EnvironmentObject var dataService: RacingDataService
    @State private var isAboutExpanded = false
    
    var seriesRaces: [Race] {
        dataService.getRacesForSeries(series.shortName)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
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
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                dataService.toggleStarredSeries(series.shortName)
                            }
                        }) {
                            Image(systemName: dataService.isSeriesStarred(series.shortName) ? "star.fill" : "star")
                                .font(.system(size: 20))
                                .foregroundColor(dataService.isSeriesStarred(series.shortName) ? .yellow : .gray)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                // About Section
                VStack(alignment: .leading, spacing: 6) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isAboutExpanded.toggle()
                        }
                    }) {
                        HStack {
                            Text("About \(series.name)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: isAboutExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if isAboutExpanded {
                        Text(series.aboutText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                // Upcoming Races
                VStack(alignment: .leading, spacing: 8) {
                    Text("Upcoming Races")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                    
                    if seriesRaces.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 24))
                                .foregroundColor(.gray)
                            Text("No upcoming races")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    } else {
                        LazyVStack(spacing: 6) {
                            ForEach(seriesRaces) { race in
                                SeriesRaceRow(race: race)
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                }
                
                // Official Website
                VStack(alignment: .leading, spacing: 6) {
                    Text("Official Website")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Link(destination: URL(string: series.officialWebsite)!) {
                        HStack {
                            Image(systemName: "globe")
                                .font(.caption)
                                .foregroundColor(.racingRed)
                            Text(series.officialWebsite)
                                .font(.caption)
                                .foregroundColor(.racingRed)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption2)
                                .foregroundColor(.racingRed)
                        }
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
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

struct SeriesRaceRow: View {
    let race: Race
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(race.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Spacer()
                
                Text(formattedDate(race.date))
                    .font(.caption2)
                    .foregroundColor(.racingRed)
                    .fontWeight(.medium)
            }
            
            HStack {
                Image(systemName: "location")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(race.location)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(timeUntilRace(race.date))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if let circuit = race.circuit {
                Text(circuit)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(6)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
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
