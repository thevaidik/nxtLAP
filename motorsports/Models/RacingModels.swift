//
//  RacingModels.swift
//  motorsports
//
//  Created by Vaidik Dubey on 20/08/25.
//

import Foundation

struct RacingSeries: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let shortName: String
    let category: RacingCategory
    let description: String
    let iconName: String
    let officialWebsite: String?
    let aboutText: String
}

enum RacingCategory: String, CaseIterable {
    case formula = "Formula Racing"
    case endurance = "Endurance Racing"
    case touring = "Touring Cars"
    case rally = "Rally"
    case oval = "Oval Racing"
    case motorcycle = "Motorcycle Racing"
    
    var color: String {
        switch self {
        case .formula: return "blue"
        case .endurance: return "green"
        case .touring: return "orange"
        case .rally: return "purple"
        case .oval: return "red"
        case .motorcycle: return "yellow"
        }
    }
    
    // Helper to map server categories
    static func from(serverCategory: String) -> RacingCategory {
        switch serverCategory.lowercased() {
        case "open wheel": return .formula
        case "sports car": return .endurance
        case "touring car": return .touring
        case "rally": return .rally
        case "stock car": return .oval
        case "two-wheel": return .motorcycle
        default: return .touring // Fallback
        }
    }
}

struct Race: Identifiable, Codable {
    let id: String
    let name: String
    let series: String
    let date: Date
    let location: String
    let circuit: String?
    let isStarred: Bool
    let hasExactTime: Bool
    
    var isLive: Bool {
        guard hasExactTime else { return false }
        let now = Date()
        let sixHours: TimeInterval = 6 * 60 * 60
        return now >= date && now <= date.addingTimeInterval(sixHours)
    }
    
    init(id: String? = nil, name: String, series: String, date: Date, location: String, circuit: String? = nil, isStarred: Bool = false, hasExactTime: Bool = true) {
        // Use provided id, or fallback to name+date if not available
        self.id = id ?? "\(series)_\(name)_\(date.timeIntervalSince1970)"
        self.name = name
        self.series = series
        self.date = date
        self.location = location
        self.circuit = circuit
        self.isStarred = isStarred
        self.hasExactTime = hasExactTime
    }
}

struct RaceEvent: Identifiable {
    let id = UUID()
    let race: Race
    let startTime: Date
    let endTime: Date?
    let sessionType: SessionType
}

enum SessionType: String, CaseIterable {
    case practice = "Practice"
    case qualifying = "Qualifying"
    case race = "Race"
    case sprint = "Sprint"
}

// MARK: - Racing Server API Models
struct RacingServerEvent: Codable {
    static var dynamicSlugToShortName: [String: String] = [:]
    
    let id: String
    let series: String
    let event_name: String
    let circuit: String
    let date: String
    let country: String
    let season: String
    let round: Int?
    let description: String?  // Optional because some events don't have descriptions
    let ttl: Int
    
    // Convert to Race model
    func toRace() -> Race? {
        // Parse ISO8601 date
        let formatter = ISO8601DateFormatter()
        guard let eventDate = formatter.date(from: date) else {
            print("⚠️ Failed to parse date: \(date) for event: \(event_name)")
            return nil
        }
        
        // Map series slug to display name dynamically
        let seriesDisplayName = RacingServerEvent.dynamicSlugToShortName[series] ?? series.uppercased()
        
        let exactTime = !date.hasSuffix("T00:00:00Z")
        
        return Race(
            id: id,
            name: event_name,
            series: seriesDisplayName,
            date: eventDate,
            location: country,
            circuit: circuit.isEmpty ? nil : circuit,
            isStarred: false,
            hasExactTime: exactTime
        )
    }
}

struct RacingServerSeries: Codable {
    let id: String
    let name: String
    let short_name: String
    let category: String
    let description: String
    let is_fantasy_eligible: Bool?
}

// MARK: - F1 Standings Models
struct F1DriverStanding: Identifiable, Codable {
    let id = UUID()
    let position: Int
    let driverNumber: Int
    let points: Double

    enum CodingKeys: String, CodingKey {
        case position, points
        case driverNumber = "driver_number"
    }
}

struct F1ConstructorStanding: Identifiable, Codable {
    let id = UUID()
    let position: Int
    let teamName: String
    let points: Double

    enum CodingKeys: String, CodingKey {
        case position, points
        case teamName = "team_name"
    }
}

struct F1StandingsResponse: Codable {
    let drivers: [F1DriverStanding]
    let constructors: [F1ConstructorStanding]
}
