//
//  RacingAPIService.swift
//  motorsports
//
//  Created by Vaidik Dubey on 20/08/25.
//

import Foundation

class RacingAPIService: ObservableObject {
    private let session = URLSession.shared
    static let baseURL = "https://www.thesportsdb.com/api/v1/json/3"
    static let ergastBaseURL = "https://api.jolpi.ca/ergast/f1"
    
    // MARK: - Hybrid API Integration (Ergast for F1, TheSportsDB for others)
    func fetchAllRacingData() async throws -> [Race] {
        // Fetch all racing series - F1 from Ergast API, others from TheSportsDB
        // Note: TheSportsDB has a 100-event limit which cuts off F1 data, so we use Ergast for complete F1 calendar
        let seriesData: [(name: String, id: String, shortName: String)] = [
            ("Formula 1", "4370", "F1"),                    // From Ergast API
            ("MotoGP", "4407", "MOTO GP"),                  // 16 upcoming events  
            ("NASCAR Cup Series", "4393", "NASCAR"),        // 10 upcoming events
            ("BTCC", "4372", "BTCC"),                       // 9 upcoming events
            ("V8 Supercars", "4489", "V8SC"),              // 9 upcoming events
            ("WRC", "4409", "WRC"),                         // 5 upcoming events
            ("Super GT series", "4412", "SGT"),            // 3 upcoming events
            ("IMSA SportsCar Championship", "4488", "IMSA"), // 2 upcoming events
            ("IndyCar Series", "4373", "INDYCAR"),          // 1 upcoming event
            ("British GT Championship", "4410", "BGT")      // 1 upcoming event
        ]
        
        print("🏁 Fetching all \(seriesData.count) racing series in parallel...")
        let startTime = Date()
        
        // PARALLEL EXECUTION: Launch all API calls simultaneously using TaskGroup
        let results = await withTaskGroup(of: (String, Result<[Race], Error>).self) { group in
            // Add a task for each series - all execute concurrently
            for series in seriesData {
                group.addTask {
                    do {
                        let races = try await self.fetchSeriesEvents(
                            seriesId: series.id,
                            seriesName: series.shortName,
                            displayName: series.name
                        )
                        print("✅ \(series.name): Loaded \(races.count) races")
                        return (series.name, .success(races))
                    } catch {
                        print("❌ \(series.name) API failed: \(error.localizedDescription)")
                        return (series.name, .failure(error))
                    }
                }
            }
            
            // Collect all results as they complete
            var collectedResults: [(String, Result<[Race], Error>)] = []
            for await result in group {
                collectedResults.append(result)
            }
            return collectedResults
        }
        
        // Process results: separate successes from failures
        var allRaces: [Race] = []
        var errors: [String] = []
        
        for (seriesName, result) in results {
            switch result {
            case .success(let races):
                allRaces.append(contentsOf: races)
            case .failure(let error):
                errors.append("\(seriesName): \(error.localizedDescription)")
            }
        }
        
        let duration = Date().timeIntervalSince(startTime)
        print("⏱️ Parallel fetch completed in \(String(format: "%.2f", duration)) seconds")
        
        if !errors.isEmpty {
            print("⚠️ Some APIs failed: \(errors.joined(separator: ", "))")
        }
        
        if allRaces.isEmpty {
            throw APIError.noDataAvailable("No racing data could be fetched from any API")
        }
        
        print("🏆 Total upcoming races fetched: \(allRaces.count)")
        
        return allRaces.sorted { $0.date < $1.date }
    }
    
    // MARK: - Generic Series Fetcher
    private func fetchSeriesEvents(seriesId: String, seriesName: String, displayName: String) async throws -> [Race] {
        // Use Jolpi Ergast API for F1 (more complete data, no 100-event limit)
        if seriesName == "F1" {
            return try await fetchF1FromErgast()
        }
        
        // TheSportsDB for other series
        let seasonUrl = URL(string: "\(RacingAPIService.baseURL)/eventsseason.php?id=\(seriesId)&s=2025")!
        print("🔗 \(displayName) API: \(seasonUrl)")
        
        let (data, response) = try await session.data(from: seasonUrl)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 \(displayName) Response: \(httpResponse.statusCode)")
            if httpResponse.statusCode != 200 {
                throw APIError.httpError(httpResponse.statusCode)
            }
        }
        
        let apiResponse = try JSONDecoder().decode(SportsDBResponse.self, from: data)
        
        guard let events = apiResponse.events else {
            print("❌ \(displayName) returned no events")
            throw APIError.noDataAvailable("\(displayName) API returned no events")
        }
        
        print("📋 \(displayName) Total events: \(events.count)")
        return try parseEvents(events, seriesName: seriesName, displayName: displayName, filterPast: true)
    }
    
    // MARK: - F1 Ergast API Fetcher
    private func fetchF1FromErgast() async throws -> [Race] {
        let currentYear = Calendar.current.component(.year, from: Date())
        let url = URL(string: "\(RacingAPIService.ergastBaseURL)/\(currentYear).json")!
        print("🔗 Formula 1 Ergast API: \(url)")
        
        let (data, response) = try await session.data(from: url)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 Formula 1 Response: \(httpResponse.statusCode)")
            if httpResponse.statusCode != 200 {
                throw APIError.httpError(httpResponse.statusCode)
            }
        }
        
        let ergastResponse = try JSONDecoder().decode(ErgastResponse.self, from: data)
        
        guard let races = ergastResponse.MRData.RaceTable.Races else {
            print("❌ Formula 1 Ergast API returned no races")
            throw APIError.noDataAvailable("Formula 1 API returned no races")
        }
        
        print("📋 Formula 1 Total race weekends: \(races.count)")
        
        let today = startOfToday()
        var allSessions: [Race] = []
        
        for race in races {
            let location = "\(race.Circuit.Location.locality), \(race.Circuit.Location.country)"
            let circuitName = race.Circuit.circuitName
            
            // Add Practice 1
            if let fp1 = race.FirstPractice, let dateString = fp1.date {
                if let date = parseEventDateTime(date: dateString, time: fp1.time), date >= today {
                    allSessions.append(Race(
                        name: "\(race.raceName) - Practice 1",
                        series: "F1",
                        date: date,
                        location: location,
                        circuit: circuitName
                    ))
                }
            }
            
            // Add Practice 2
            if let fp2 = race.SecondPractice, let dateString = fp2.date {
                if let date = parseEventDateTime(date: dateString, time: fp2.time), date >= today {
                    allSessions.append(Race(
                        name: "\(race.raceName) - Practice 2",
                        series: "F1",
                        date: date,
                        location: location,
                        circuit: circuitName
                    ))
                }
            }
            
            // Add Practice 3
            if let fp3 = race.ThirdPractice, let dateString = fp3.date {
                if let date = parseEventDateTime(date: dateString, time: fp3.time), date >= today {
                    allSessions.append(Race(
                        name: "\(race.raceName) - Practice 3",
                        series: "F1",
                        date: date,
                        location: location,
                        circuit: circuitName
                    ))
                }
            }
            
            // Add Qualifying
            if let quali = race.Qualifying, let dateString = quali.date {
                if let date = parseEventDateTime(date: dateString, time: quali.time), date >= today {
                    allSessions.append(Race(
                        name: "\(race.raceName) - Qualifying",
                        series: "F1",
                        date: date,
                        location: location,
                        circuit: circuitName
                    ))
                }
            }
            
            // Add Sprint (if exists)
            if let sprint = race.Sprint, let dateString = sprint.date {
                if let date = parseEventDateTime(date: dateString, time: sprint.time), date >= today {
                    allSessions.append(Race(
                        name: "\(race.raceName) - Sprint",
                        series: "F1",
                        date: date,
                        location: location,
                        circuit: circuitName
                    ))
                }
            }
            
            // Add Main Race
            if let dateString = race.date {
                if let date = parseEventDateTime(date: dateString, time: race.time), date >= today {
                    allSessions.append(Race(
                        name: race.raceName,
                        series: "F1",
                        date: date,
                        location: location,
                        circuit: circuitName
                    ))
                }
            }
        }
        
        print("✅ Formula 1 Total upcoming sessions (including practice/quali): \(allSessions.count)")
        return allSessions
    }
    
    // MARK: - Event Parser Helper
    private func parseEvents(_ events: [SportsDBEvent], seriesName: String, displayName: String, filterPast: Bool) throws -> [Race] {
        let today = startOfToday()
        
        let races = events.compactMap { event -> Race? in
            guard let eventName = event.strEvent,
                  let dateString = event.dateEvent else {
                print("⚠️ Skipping \(displayName) event with missing data: \(event.strEvent ?? "Unknown")")
                return nil
            }
            
            // Parse date with time if available
            guard let date = parseSportsDBDateTime(date: dateString, time: event.strTime) else {
                print("⚠️ Failed to parse date for \(eventName)")
                return nil
            }
            
            // Filter past events if requested
            if filterPast && date < today {
                return nil
            }
            
            let venue = event.strVenue ?? "Unknown Venue"
            let city = event.strCity ?? "Unknown City"
            let country = event.strCountry ?? "Unknown Country"
            let location = city != "Unknown City" && country != "Unknown Country" ? "\(city), \(country)" : venue
            
            return Race(
                name: eventName,
                series: seriesName,
                date: date,
                location: location,
                circuit: venue
            )
        }
        
        print("✅ \(displayName) Valid races parsed: \(races.count)")
        return races
    }
    
    // MARK: - Legacy Methods Removed - Now Using Generic fetchSeriesEvents Method
    
    // MARK: - Date Parsing Helpers
    
    // Parse date only (for APIs that don't provide time)
    private func parseEventDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        let date = formatter.date(from: dateString)
        if date == nil {
            print("⚠️ Failed to parse date: \(dateString)")
        }
        return date
    }
    
    // Parse date + time (for Ergast API which provides UTC times)
    private func parseEventDateTime(date dateString: String, time timeString: String?) -> Date? {
        guard let timeString = timeString else {
            // No time provided, fall back to date-only parsing
            return parseEventDate(dateString)
        }
        
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(identifier: "UTC")
        
        // Ergast provides time like "14:00:00Z"
        let dateTimeString = "\(dateString)T\(timeString)"
        
        if let date = formatter.date(from: dateTimeString) {
            return date
        }
        
        // Fallback to date-only if time parsing fails
        print("⚠️ Failed to parse time '\(timeString)', using date only")
        return parseEventDate(dateString)
    }
    
    // Parse date + time for SportsDB (format: "14:00:00" in UTC)
    private func parseSportsDBDateTime(date dateString: String, time timeString: String?) -> Date? {
        guard let timeString = timeString, !timeString.isEmpty else {
            // No time provided, fall back to date-only parsing
            return parseEventDate(dateString)
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        
        // SportsDB provides time like "14:00:00" in UTC
        let dateTimeString = "\(dateString) \(timeString)"
        
        if let date = formatter.date(from: dateTimeString) {
            return date
        }
        
        // Fallback to date-only if time parsing fails
        print("⚠️ Failed to parse SportsDB time '\(timeString)', using date only")
        return parseEventDate(dateString)
    }
    
    // Helper to get start of today for fair comparison
    private func startOfToday() -> Date {
        let calendar = Calendar.current
        return calendar.startOfDay(for: Date())
    }
    
    // MARK: - No Mock Data - Real API Only
}

// MARK: - API Error Types
enum APIError: Error, LocalizedError {
    case httpError(Int)
    case noDataAvailable(String)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .httpError(let code):
            return "HTTP Error: \(code)"
        case .noDataAvailable(let message):
            return "No Data: \(message)"
        case .decodingError(let error):
            return "Decoding Error: \(error.localizedDescription)"
        }
    }
}

// MARK: - TheSportsDB API Models
struct SportsDBResponse: Codable {
    let events: [SportsDBEvent]?
}

struct SportsDBEvent: Codable {
    let idEvent: String?
    let strEvent: String?
    let strSport: String?
    let strLeague: String?
    let strSeason: String?
    let dateEvent: String?
    let strTime: String?
    let strVenue: String?
    let strCountry: String?
    let strCity: String?
    let strPoster: String?
    let strThumb: String?
    let strDescription: String?
    let strStatus: String?
}

// MARK: - Ergast API Models (for F1)
struct ErgastResponse: Codable {
    let MRData: ErgastMRData
}

struct ErgastMRData: Codable {
    let RaceTable: ErgastRaceTable
}

struct ErgastRaceTable: Codable {
    let Races: [ErgastRace]?
}

struct ErgastRace: Codable {
    let raceName: String
    let date: String?
    let time: String?
    let Circuit: ErgastCircuit
    let FirstPractice: ErgastSession?
    let SecondPractice: ErgastSession?
    let ThirdPractice: ErgastSession?
    let Qualifying: ErgastSession?
    let Sprint: ErgastSession?
}

struct ErgastSession: Codable {
    let date: String?
    let time: String?
}

struct ErgastCircuit: Codable {
    let circuitName: String
    let Location: ErgastLocation
}

struct ErgastLocation: Codable {
    let locality: String
    let country: String
}
