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
    let hasExactTime: Bool

    // Provide a convenient initializer for previews and samples
    init(id: UUID = UUID(), name: String, series: String, date: Date, location: String, circuit: String?, hasExactTime: Bool = true) {
        self.id = id
        self.name = name
        self.series = series
        self.date = date
        self.location = location
        self.circuit = circuit
        self.hasExactTime = hasExactTime
    }

    // Custom decoding to tolerate missing/variant fields from the app's JSON
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        series = try c.decode(String.self, forKey: .series)
        date = try c.decode(Date.self, forKey: .date)
        location = try c.decode(String.self, forKey: .location)
        circuit = try c.decodeIfPresent(String.self, forKey: .circuit)
        hasExactTime = (try? c.decodeIfPresent(Bool.self, forKey: .hasExactTime)) ?? true

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
        case id, name, series, date, location, circuit, hasExactTime
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
        let lowercasedStarred = Set(starred.map { $0.lowercased() })
        
        // Consider only main race sessions
        let mainRaces = races.filter { isMainRace($0.name) }
        let base = mainRaces.isEmpty ? races : mainRaces
        let filtered = base.filter { lowercasedStarred.contains($0.series.lowercased()) }
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
        Group {
            if let firstRace = entry.races.first {
                if family == .systemSmall {
                    smallWidgetView(race: firstRace)
                } else {
                    mediumLargeWidgetView(races: entry.races)
                }
            } else {
                emptyStateView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    // MARK: - Small Widget (1 Race)
    @ViewBuilder
    private func smallWidgetView(race: SharedRace) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Next Race")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [Color(red: 0.7, green: 1.0, blue: 0.2), Color(red: 0.2, green: 0.8, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                Spacer()
            }
            .padding(.bottom, 12)
            
            // Icon Badge & Series
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(seriesColor(race.series).opacity(0.2))
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: seriesIcon(race.series))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(seriesColor(race.series))
                }
                
                Text(race.series)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 8)
            
            Text(race.name)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .padding(.bottom, 2)
            
            Text(race.location)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.gray)
                .lineLimit(1)
            
            Spacer(minLength: 0)
            
            // Footer: Time and Date
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    if race.hasExactTime {
                        Text(formatTime(race))
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    Text(formatDate(race.date))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.gray)
                }
                Spacer()
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    // MARK: - Medium/Large Widget (List)
    @ViewBuilder
    private func mediumLargeWidgetView(races: [SharedRace]) -> some View {
        let isMedium = family == .systemMedium
        let maxCount = isMedium ? 3 : 6 // 3 for medium, 6 for large
        
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .top) {
                Text("This Week")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [Color(red: 0.7, green: 1.0, blue: 0.2), Color(red: 0.2, green: 0.8, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                Spacer()
                Text("NxtLAP")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(red: 0.85, green: 0.15, blue: 0.15))
                    .cornerRadius(4)
            }
            .padding(.bottom, 12)
            
            // Rows
            VStack(alignment: .leading, spacing: isMedium ? 10 : 12) {
                ForEach(races.prefix(maxCount)) { race in
                    raceRow(race)
                }
            }
            
            Spacer(minLength: 0)
            
            // Footer
            let remaining = races.count - maxCount
            if remaining > 0 {
                HStack(spacing: 6) {
                    Text("+\(remaining)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 4) {
                        ForEach(0..<min(remaining, 12), id: \.self) { i in
                            Circle()
                                .fill(seriesColor(races[maxCount + i].series))
                                .frame(width: 6, height: 6)
                        }
                    }
                }
                .padding(.top, isMedium ? 8 : 12)
            }
        }
        .padding(isMedium ? 14 : 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func raceRow(_ race: SharedRace) -> some View {
        HStack(alignment: .center, spacing: 10) {
            // Left Icon Badge (App style)
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(seriesColor(race.series).opacity(0.2))
                    .frame(width: 28, height: 28)
                
                Image(systemName: seriesIcon(race.series))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(seriesColor(race.series))
            }
            
            // Middle Body
            VStack(alignment: .leading, spacing: 2) {
                Text("\(race.series) - \(race.name)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(race.location)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer(minLength: 8)
            
            // Right Body
            VStack(alignment: .trailing, spacing: 2) {
                if race.hasExactTime {
                    Text(formatTime(race))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Text(formatDate(race.date))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
    }

    private func seriesIcon(_ series: String) -> String {
        switch series.lowercased() {
        case "formula1", "f1": return "car.side.fill"
        case "motogp": return "motorcycle.fill"
        case "nascar": return "checkerboard.shield"
        default: return "flag.checkered"
        }
    }

    private func seriesColor(_ series: String) -> Color {
        switch series.lowercased() {
        case "formula1", "f1": return .red
        case "motogp": return .orange
        case "nascar": return .yellow
        case "formulae": return .blue
        case "indycar": return .green
        default: return Color(red: 0.85, green: 0.15, blue: 0.15)
        }
    }

    private func formatTime(_ race: SharedRace) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: race.date)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MMM d"
        return formatter.string(from: date)
    }
    
    // MARK: - Empty State
    @ViewBuilder
    private func emptyStateView() -> some View {
        VStack(spacing: 8) {
            Image(systemName: "flag.checkered")
                .font(.system(size: 30))
                .foregroundColor(.gray.opacity(0.65))
            Text("No upcoming races")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
            Text("Add series from the app")
                .font(.system(size: 11))
                .foregroundColor(.gray.opacity(0.85))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct RaceWidget: Widget {
    let kind: String = "RaceWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                RaceWidgetEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        Color(red: 0.08, green: 0.11, blue: 0.16)
                    }
            } else {
                RaceWidgetEntryView(entry: entry)
                    .background(Color(red: 0.08, green: 0.11, blue: 0.16))
            }
        }
        .configurationDisplayName("Upcoming Races")
        .description("View your upcoming motorsports races at a glance")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
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
            SharedRace(id: UUID(), name: "Practice 4 (Fast Friday)", series: "IndyCar", date: Date().addingTimeInterval(3600*2), location: "Indianapolis Motor Speedway", circuit: "Indianapolis Motor Speedway"),
            SharedRace(id: UUID(), name: "Qualifying", series: "Silverstone 24H", date: Date().addingTimeInterval(3600*4.25), location: "Silverstone", circuit: "Silverstone"),
            SharedRace(id: UUID(), name: "Practice", series: "NASCAR Cup", date: Date().addingTimeInterval(3600*5), location: "Dover", circuit: "Dover"),
            SharedRace(id: UUID(), name: "Practice 2", series: "Formula E", date: Date().addingTimeInterval(3600*16), location: "Monaco", circuit: "Monaco"),
            SharedRace(id: UUID(), name: "Practice", series: "British Truck Racing", date: Date().addingTimeInterval(3600*17), location: "Thruxton", circuit: "Thruxton")
        ],
        isLoading: false,
        error: nil
    )
}

#Preview(as: .systemLarge) {
    RaceWidget()
} timeline: {
    RaceEntry(
        date: .now,
        races: [
            SharedRace(id: UUID(), name: "Practice 4 (Fast Friday)", series: "IndyCar", date: Date().addingTimeInterval(3600*2), location: "Indianapolis Motor Speedway", circuit: "Indianapolis Motor Speedway"),
            SharedRace(id: UUID(), name: "Qualifying", series: "Silverstone 24H", date: Date().addingTimeInterval(3600*4.25), location: "Silverstone", circuit: "Silverstone"),
            SharedRace(id: UUID(), name: "Practice", series: "NASCAR Cup", date: Date().addingTimeInterval(3600*5), location: "Dover", circuit: "Dover"),
            SharedRace(id: UUID(), name: "Night Practice", series: "Silverstone 24H", date: Date().addingTimeInterval(3600*6.15), location: "Silverstone", circuit: "Silverstone"),
            SharedRace(id: UUID(), name: "Practice 2", series: "Formula E", date: Date().addingTimeInterval(3600*16), location: "Monaco", circuit: "Monaco"),
            SharedRace(id: UUID(), name: "Practice", series: "British Truck Racing", date: Date().addingTimeInterval(3600*17), location: "Thruxton", circuit: "Thruxton"),
            SharedRace(id: UUID(), name: "Qualifying 1", series: "Formula E", date: Date().addingTimeInterval(3600*17.6), location: "Monaco", circuit: "Monaco"),
            SharedRace(id: UUID(), name: "Practice", series: "GT Cup UK", date: Date().addingTimeInterval(3600*17.9), location: "Snetterton", circuit: "Snetterton"),
            SharedRace(id: UUID(), name: "Qualifying", series: "F1", date: Date().addingTimeInterval(3600*18), location: "Monaco", circuit: "Monaco")
        ],
        isLoading: false,
        error: nil
    )
}

