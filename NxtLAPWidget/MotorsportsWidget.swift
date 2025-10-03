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
            if #available(iOS 17.0, *) {
                UpcomingRacesWidgetView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                UpcomingRacesWidgetView(entry: entry)
                    .padding()
                    .background()
            }
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
        VStack(alignment: .leading, spacing: 6) {
            Text("Next")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            if let nextRace = entry.races.first {
                VStack(alignment: .leading, spacing: 3) {
                    Text(nextRace.series)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(timeUntilRace(nextRace.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("No races")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
    }
}

struct MediumWidgetView: View {
    let entry: RaceEntry
    
    var uniqueSeries: [String] {
        Array(Set(entry.races.map { $0.series })).sorted()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Upcoming Series")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            VStack(spacing: 4) {
                ForEach(Array(uniqueSeries.prefix(3)), id: \.self) { series in
                    HStack {
                        Text(series)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if let nextRace = entry.races.first(where: { $0.series == series }) {
                            Text(timeUntilRace(nextRace.date))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct LargeWidgetView: View {
    let entry: RaceEntry
    
    var uniqueSeries: [String] {
        Array(Set(entry.races.map { $0.series })).sorted()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Upcoming Series")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            VStack(spacing: 6) {
                ForEach(Array(uniqueSeries.prefix(5)), id: \.self) { series in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(series)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            if let nextRace = entry.races.first(where: { $0.series == series }) {
                                Text(nextRace.name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                        
                        if let nextRace = entry.races.first(where: { $0.series == series }) {
                            VStack(alignment: .trailing, spacing: 1) {
                                Text(timeUntilRace(nextRace.date))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                Text(nextRace.location)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Spacer()
        }
        .padding()
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