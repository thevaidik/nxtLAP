//
//  MotorsportsWidget.swift
//  motorsports
//
//  Created by Kiro on 24/08/25.
//

import WidgetKit
import SwiftUI

// Race model for widget
struct Race: Identifiable, Codable {
    let id = UUID()
    let name: String
    let series: String
    let date: Date
    let location: String
    let circuit: String?
    let isStarred: Bool
    
    init(name: String, series: String, date: Date, location: String, circuit: String? = nil, isStarred: Bool = false) {
        self.name = name
        self.series = series
        self.date = date
        self.location = location
        self.circuit = circuit
        self.isStarred = isStarred
    }
}

struct MotorsportsWidget: Widget {
    let kind: String = "MotorsportsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RaceProvider()) { entry in
            UpcomingRacesWidgetView(entry: entry)
        }
        .configurationDisplayName("Upcoming Races")
        .description("View your upcoming motorsports races at a glance")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct RaceEntry: TimelineEntry {
    let date: Date
    let races: [Race]
    let isLoading: Bool
    let error: String?
}

struct RaceProvider: TimelineProvider {
    
    func placeholder(in context: Context) -> RaceEntry {
        RaceEntry(
            date: Date(),
            races: [
                Race(name: "Monaco Grand Prix", series: "F1", date: Date().addingTimeInterval(86400), location: "Monaco"),
                Race(name: "Indianapolis 500", series: "INDYCAR", date: Date().addingTimeInterval(172800), location: "Indianapolis")
            ],
            isLoading: false,
            error: nil
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (RaceEntry) -> ()) {
        let entry = RaceEntry(
            date: Date(),
            races: loadCachedRaces(),
            isLoading: false,
            error: nil
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<RaceEntry>) -> ()) {
        let currentDate = Date()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate) ?? currentDate
        
        let entry = RaceEntry(
            date: currentDate,
            races: loadCachedRaces(),
            isLoading: false,
            error: nil
        )
        
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func loadCachedRaces() -> [Race] {
        // In a real implementation, this would load from UserDefaults or App Groups
        // For now, return sample data
        return [
            Race(name: "Monaco Grand Prix", series: "F1", date: Date().addingTimeInterval(86400), location: "Monaco"),
            Race(name: "Indianapolis 500", series: "INDYCAR", date: Date().addingTimeInterval(172800), location: "Indianapolis"),
            Race(name: "British Grand Prix", series: "F1", date: Date().addingTimeInterval(259200), location: "Silverstone"),
            Race(name: "Daytona 500", series: "NASCAR", date: Date().addingTimeInterval(345600), location: "Daytona"),
            Race(name: "Le Mans 24h", series: "WEC", date: Date().addingTimeInterval(432000), location: "Le Mans")
        ]
    }
}

struct UpcomingRacesWidgetView: View {
    let entry: RaceEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    let entry: RaceEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "flag.checkered")
                    .foregroundColor(Color.racingRed)
                    .font(.caption)
                
                Text("Next Race")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            if let nextRace = entry.races.first {
                VStack(alignment: .leading, spacing: 4) {
                    Text(nextRace.name)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Text(nextRace.series)
                        .font(.caption2)
                        .foregroundColor(Color.racingRed)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.racingRed.opacity(0.2))
                        )
                    
                    Text(timeUntilRace(nextRace.date))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            } else {
                Text("No upcoming races")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(.systemGray6).opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

struct MediumWidgetView: View {
    let entry: RaceEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "flag.checkered")
                    .foregroundColor(Color.racingRed)
                    .font(.subheadline)
                
                Text("Upcoming Races")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(entry.races.count)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            VStack(spacing: 6) {
                ForEach(Array(entry.races.prefix(3)), id: \.id) { race in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(race.name)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            HStack(spacing: 4) {
                                Text(race.series)
                                    .font(.caption2)
                                    .foregroundColor(Color.racingRed)
                                
                                Text("•")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                
                                Text(timeUntilRace(race.date))
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 2)
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(.systemGray6).opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

struct LargeWidgetView: View {
    let entry: RaceEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "flag.checkered")
                    .foregroundColor(Color.racingRed)
                    .font(.title3)
                
                Text("Upcoming Races")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(entry.races.count) races")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(Array(entry.races.prefix(6)), id: \.id) { race in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(race.name)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                
                                HStack(spacing: 8) {
                                    Text(race.series)
                                        .font(.caption)
                                        .foregroundColor(Color.racingRed)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(
                                            Capsule()
                                                .fill(Color.racingRed.opacity(0.2))
                                        )
                                    
                                    Text(race.location)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Text(timeUntilRace(race.date))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6).opacity(0.1))
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(.systemGray6).opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

// Helper function
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

#Preview(as: .systemSmall) {
    MotorsportsWidget()
} timeline: {
    RaceEntry(
        date: Date(),
        races: [
            Race(name: "Monaco Grand Prix", series: "F1", date: Date().addingTimeInterval(86400), location: "Monaco"),
            Race(name: "Indianapolis 500", series: "INDYCAR", date: Date().addingTimeInterval(172800), location: "Indianapolis")
        ],
        isLoading: false,
        error: nil
    )
}

#Preview(as: .systemMedium) {
    MotorsportsWidget()
} timeline: {
    RaceEntry(
        date: Date(),
        races: [
            Race(name: "Monaco Grand Prix", series: "F1", date: Date().addingTimeInterval(86400), location: "Monaco"),
            Race(name: "Indianapolis 500", series: "INDYCAR", date: Date().addingTimeInterval(172800), location: "Indianapolis"),
            Race(name: "British Grand Prix", series: "F1", date: Date().addingTimeInterval(259200), location: "Silverstone")
        ],
        isLoading: false,
        error: nil
    )
}