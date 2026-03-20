//
//  RacingAPIService.swift
//  motorsports
//
//  Created by Vaidik Dubey on 20/08/25.
//

import Foundation

class RacingAPIService: ObservableObject {
    private let session = URLSession.shared
    
    // Toggle this to true to use the test server
    static let useTestServer = true
    
    static var baseURL: String {
        return useTestServer 
            ? "https://kvez79e5ib.execute-api.us-east-1.amazonaws.com" // Test server
            : "https://brto98doc9.execute-api.us-east-1.amazonaws.com" // Production server
    }
    
    // MARK: - New Racing Server API Integration
    
    /// Fetch all racing events from the unified API
    func fetchAllRacingData() async throws -> [Race] {
        let url = URL(string: "\(RacingAPIService.baseURL)/races")!
        print("🔗 Fetching all races from: \(url)")
        
        let (data, response) = try await session.data(from: url)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 Response: \(httpResponse.statusCode)")
            if httpResponse.statusCode != 200 {
                throw APIError.httpError(httpResponse.statusCode)
            }
        }
        
        print("📦 Received data size: \(data.count) bytes")
        
        // Try to decode the response
        do {
            let events = try JSONDecoder().decode([RacingServerEvent].self, from: data)
            print("📋 Total events received: \(events.count)")
            
            // Convert to Race objects
            let races = events.compactMap { event -> Race? in
                let race = event.toRace()
                if race == nil {
                    print("⚠️ Failed to convert event: \(event.event_name)")
                }
                return race
            }
            
            print("✅ Valid races parsed: \(races.count)")
            
            if races.isEmpty {
                print("❌ WARNING: No races could be converted!")
            } else {
                print("🏁 First race: \(races[0].name) on \(races[0].date)")
                print("🏁 Last race: \(races[races.count-1].name) on \(races[races.count-1].date)")
            }
            
            return races.sorted { $0.date < $1.date }
        } catch {
            print("❌ Decoding error: \(error)")
            throw APIError.decodingError(error)
        }
    }
    
    /// Fetch upcoming races (next 15 events)
    func fetchUpcomingRaces() async throws -> [Race] {
        let url = URL(string: "\(RacingAPIService.baseURL)/races/upcoming")!
        print("🔗 Fetching upcoming races from: \(url)")
        
        let (data, response) = try await session.data(from: url)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 Response: \(httpResponse.statusCode)")
            if httpResponse.statusCode != 200 {
                throw APIError.httpError(httpResponse.statusCode)
            }
        }
        
        let events = try JSONDecoder().decode([RacingServerEvent].self, from: data)
        print("📋 Upcoming events received: \(events.count)")
        
        let races = events.compactMap { $0.toRace() }
        print("✅ Valid upcoming races parsed: \(races.count)")
        
        return races
    }
    
    /// Fetch races for a specific series
    func fetchSeriesRaces(series: String) async throws -> [Race] {
        // Map display names to API slugs
        let seriesSlug = mapDisplayNameToSlug(series)
        let url = URL(string: "\(RacingAPIService.baseURL)/races/\(seriesSlug)")!
        print("🔗 Fetching \(series) races from: \(url)")
        
        let (data, response) = try await session.data(from: url)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 \(series) Response: \(httpResponse.statusCode)")
            if httpResponse.statusCode != 200 {
                throw APIError.httpError(httpResponse.statusCode)
            }
        }
        
        let events = try JSONDecoder().decode([RacingServerEvent].self, from: data)
        print("📋 \(series) events received: \(events.count)")
        
        let races = events.compactMap { $0.toRace() }
        print("✅ \(series) valid races parsed: \(races.count)")
        
        return races.sorted { $0.date < $1.date }
    }
    
    /// Fetch F1 driver and constructor standings
    func fetchF1Standings() async throws -> F1StandingsResponse {
        let url = URL(string: "\(RacingAPIService.baseURL)/f1/standings")!
        print("🔗 Fetching F1 standings from: \(url)")
        
        let (data, response) = try await session.data(from: url)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 F1 Standings Response: \(httpResponse.statusCode)")
            if httpResponse.statusCode != 200 {
                throw APIError.httpError(httpResponse.statusCode)
            }
        }
        
        do {
            let standings = try JSONDecoder().decode(F1StandingsResponse.self, from: data)
            print("✅ F1 standings: \(standings.drivers.count) drivers, \(standings.constructors.count) constructors")
            return standings
        } catch {
            print("❌ F1 standings decoding error: \(error)")
            throw APIError.decodingError(error)
        }
    }
    
    /// Check API health
    func checkHealth() async throws -> Bool {
        let url = URL(string: "\(RacingAPIService.baseURL)/health")!
        let (data, response) = try await session.data(from: url)
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode != 200 {
                throw APIError.httpError(httpResponse.statusCode)
            }
        }
        
        let healthResponse = try JSONDecoder().decode(HealthResponse.self, from: data)
        return healthResponse.status == "ok"
    }
    
    // MARK: - Helper Methods
    
    private func mapDisplayNameToSlug(_ displayName: String) -> String {
        switch displayName {
        case "F1": return "formula1"
        case "MOTO GP": return "motogp"
        case "INDYCAR": return "indycar"
        case "WRC": return "wrc"
        case "IMSA": return "imsa"
        case "SGT": return "supergt"
        case "BGT": return "britishgt"
        case "BTCC": return "btcc"
        case "V8SC": return "v8supercars"
        case "NASCAR": return "nascar"
        default: return displayName.lowercased()
        }
    }
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

// MARK: - Health Response Model
struct HealthResponse: Codable {
    let status: String
}
