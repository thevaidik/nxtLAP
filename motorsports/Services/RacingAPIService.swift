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
    
    // MARK: - TheSportsDB API Integration - Real Data Only (2025 Season)
    func fetchAllRacingData() async throws -> [Race] {
        // Fetch all racing series with 2025 data (only series with upcoming events)
        let seriesData: [(name: String, id: String, shortName: String)] = [
            ("Formula 1", "4370", "F1"),                    // 27 upcoming events
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
        
        // Filter for upcoming races only (from today onwards)
        let today = Date()
        let upcomingRaces = allRaces.filter { $0.date >= today }
        
        print("🏆 Total races fetched: \(allRaces.count)")
        print("📅 Upcoming races: \(upcomingRaces.count)")
        
        return upcomingRaces.sorted { $0.date < $1.date }
    }
    
    // MARK: - Generic Series Fetcher
    private func fetchSeriesEvents(seriesId: String, seriesName: String, displayName: String) async throws -> [Race] {
        let url = URL(string: "\(RacingAPIService.baseURL)/eventsseason.php?id=\(seriesId)&s=2025")!
        print("🔗 \(displayName) API URL: \(url)")
        
        let (data, response) = try await session.data(from: url)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 \(displayName) API Response: \(httpResponse.statusCode)")
            if httpResponse.statusCode != 200 {
                throw APIError.httpError(httpResponse.statusCode)
            }
        }
        
        print("📦 \(displayName) API Data size: \(data.count) bytes")
        
        do {
            let apiResponse = try JSONDecoder().decode(SportsDBResponse.self, from: data)
            
            guard let events = apiResponse.events else {
                print("❌ \(displayName) API returned no events")
                throw APIError.noDataAvailable("\(displayName) API returned no events")
            }
            
            print("📋 \(displayName) Raw events count: \(events.count)")
            
            let races = events.compactMap { event -> Race? in
                guard let eventName = event.strEvent,
                      let dateString = event.dateEvent,
                      let date = parseEventDate(dateString) else {
                    print("⚠️ Skipping \(displayName) event with missing data: \(event.strEvent ?? "Unknown")")
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
            
        } catch let decodingError {
            print("❌ \(displayName) JSON decoding failed: \(decodingError)")
            throw APIError.decodingError(decodingError)
        }
    }
    
    // MARK: - Legacy Methods Removed - Now Using Generic fetchSeriesEvents Method
    
    // MARK: - Date Parsing Helper
    private func parseEventDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let date = formatter.date(from: dateString)
        if date == nil {
            print("⚠️ Failed to parse date: \(dateString)")
        }
        return date
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
