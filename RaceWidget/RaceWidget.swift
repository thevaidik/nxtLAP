 //
//  RaceWidget.swift
//  RaceWidget
//
//  Created by Vaidik Dubey on 03/03/26.
//

import WidgetKit
import SwiftUI
import Foundation

// Local mirror of the app's Race model for decoding shared JSON
struct SharedRace: Identifiable, Codable {
    let id: UUID
    let name: String
    let series: String
    let date: Date
    let location: String
    let circuit: String?

    // Provide a convenient initializer for previews and samples
    init(id: UUID = UUID(), name: String, series: String, date: Date, location: String, circuit: String?) {
        self.id = id
        self.name = name
        self.series = series
        self.date = date
        self.location = location
        self.circuit = circuit
    }

    // Custom decoding to tolerate missing/variant fields from the app's JSON
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        series = try c.decode(String.self, forKey: .series)
        date = try c.decode(Date.self, forKey: .date)
        location = try c.decode(String.self, forKey: .location)
        circuit = try c.decodeIfPresent(String.self, forKey: .circuit)

        // Try UUID directly; if absent or not a UUID, attempt a string UUID; else generate one
        if let uuid = try? c.decode(UUID.self, forKey: .id) {
            id = uuid
        } else if let idString = try? c.decode(String.self, forKey: .id), let uuid = UUID(uuidString: idString) {
            id = uuid
        } else {
            id = UUID()
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, series, date, location, circuit
    }
}

struct RaceEntry: TimelineEntry {
    let date: Date
    let races: [SharedRace]
    let isLoading: Bool
    let error: String?
}

struct Provider: TimelineProvider {
    // TODO: Set this to your real App Group ID and enable it in BOTH the app target and this widget extension
    private let appGroupID = "group.vaidik.motorsports"
    private let widgetUpcomingKey = "widget_upcoming_races"
    private let widgetStarredKey = "widget_starred_series"

    func placeholder(in context: Context) -> RaceEntry {
        RaceEntry(date: Date(), races: sampleRaces(), isLoading: false, error: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (RaceEntry) -> ()) {
        let all = loadSharedRaces() ?? sampleRaces()
        let starred = loadStarredSeries()
        let topRaces = filteredRaces(from: all, starred: starred)
        let entry = RaceEntry(
            date: Date(),
            races: topRaces,
            isLoading: false,
            error: nil
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RaceEntry>) -> ()) {
        let currentDate = Date()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate) ?? currentDate

        let all = loadSharedRaces() ?? sampleRaces()
        let starred = loadStarredSeries()
        let topRaces = filteredRaces(from: all, starred: starred)
        let entry = RaceEntry(date: currentDate, races: topRaces, isLoading: false, error: nil)

        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    // MARK: - Shared Data Loading
    private func loadSharedRaces() -> [SharedRace]? {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            print("⚠️ RaceWidget: App Group defaults unavailable. Check App Group ID: \(appGroupID)")
            return nil
        }
        guard let data = defaults.data(forKey: widgetUpcomingKey) else {
            return nil
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            let races = try decoder.decode([SharedRace].self, from: data)
            let today = Calendar.current.startOfDay(for: Date())
            return races
                .filter { Calendar.current.startOfDay(for: $0.date) >= today }
                .sorted { $0.date < $1.date }
        } catch {
            print("❌ RaceWidget: Failed to decode shared races: \(error)")
            return nil
        }
    }

    private func loadStarredSeries() -> Set<String>? {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return nil }
        if let arr = defaults.array(forKey: widgetStarredKey) as? [String] {
            return Set(arr)
        }
        return nil
    }
    
    private func isMainRace(_ name: String) -> Bool {
        let upper = name.uppercased()
        // Sprint is a race, so we removing it from nonRaceTokens.
        // Practice, Qualifying, Warmup etc are not main events.
        let nonRaceTokens = ["PRACTICE", "FP1", "FP2", "FP3", "QUALIFYING", "QUALI", "WARMUP", "TESTING"]
        return !nonRaceTokens.contains(where: { upper.contains($0) })
    }

    private func filteredRaces(from races: [SharedRace], starred: Set<String>?) -> [SharedRace] {
        guard let starred = starred, !starred.isEmpty else {
            return [] // Show empty state if no series are starred
        }
        
        // Consider only main race sessions
        let mainRaces = races.filter { isMainRace($0.name) }
        let base = mainRaces.isEmpty ? races : mainRaces
        let filtered = base.filter { starred.contains($0.series) }
        return Array(filtered.prefix(5))
    }

    private func sampleRaces() -> [SharedRace] {
        return [
            SharedRace(id: UUID(), name: "Monaco Grand Prix", series: "F1", date: Date().addingTimeInterval(86400), location: "Monaco", circuit: nil),
            SharedRace(id: UUID(), name: "Indianapolis 500", series: "INDYCAR", date: Date().addingTimeInterval(172800), location: "Indianapolis", circuit: nil),
            SharedRace(id: UUID(), name: "British Grand Prix", series: "F1", date: Date().addingTimeInterval(259200), location: "Silverstone", circuit: nil)
        ]
    }
}

struct RaceWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: RaceEntry

    var body: some View {
        ZStack {
            if let firstRace = entry.races.first {
                Color.black.opacity(0.1) // Subtle background base
                
                if family == .systemSmall {
                    smallWidgetView(race: firstRace)
                } else {
                    mediumLargeWidgetView(races: entry.races)
                }
            } else {
                emptyStateView()
            }
        }
    }
    
    // MARK: - Small Widget (1 Race)
    @ViewBuilder
    private func smallWidgetView(race: SharedRace) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Series Badge
            Text(race.series)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red)
                .cornerRadius(6)
            
            Spacer(minLength: 0)
            
            // Race Details
            Text(race.name)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.red)
                Text(timeUntilRace(race.date))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.top, 2)
        }
        .padding()
    }
    
    // MARK: - Medium/Large Widget (List)
    @ViewBuilder
    private func mediumLargeWidgetView(races: [SharedRace]) -> some View {
        let maxCount = family == .systemMedium ? 3 : 5
        VStack(alignment: .leading, spacing: 8) {
            Text("NEXT RACES")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundColor(.red)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                ForEach(races.prefix(maxCount)) { race in
                    HStack(alignment: .center, spacing: 12) {
                        Text(race.series)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 50, alignment: .center)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(4)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(race.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        
                        Spacer(minLength: 4)
                        
                        Text(timeUntilRace(race.date))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding()
    }
    
    // MARK: - Empty State
    @ViewBuilder
    private func emptyStateView() -> some View {
        VStack(spacing: 8) {
            Image(systemName: "flag.checkered")
                .font(.system(size: 30))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No upcoming races")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}

struct RaceWidget: Widget {
    let kind: String = "RaceWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                RaceWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                RaceWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Upcoming Races")
        .description("View your upcoming motorsports races at a glance")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// Helper function
private func timeUntilRace(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d"
    return formatter.string(from: date)
}

#Preview(as: .systemSmall) {
    RaceWidget()
} timeline: {
    RaceEntry(
        date: .now,
        races: [
            SharedRace(id: UUID(), name: "Monaco Grand Prix", series: "F1", date: Date().addingTimeInterval(86400), location: "Monaco", circuit: nil)
        ],
        isLoading: false,
        error: nil
    )
}
#Preview(as: .systemMedium) {
    RaceWidget()
} timeline: {
    RaceEntry(
        date: .now,
        races: [
            SharedRace(id: UUID(), name: "Monaco Grand Prix", series: "F1", date: Date().addingTimeInterval(86400), location: "Monaco", circuit: nil),
            SharedRace(id: UUID(), name: "Indianapolis 500", series: "INDYCAR", date: Date().addingTimeInterval(172800), location: "Indianapolis", circuit: nil)
        ],
        isLoading: false,
        error: nil
    )
}

