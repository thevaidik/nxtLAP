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
    static let useTestServer = false
    
    static var baseURL: String {
        return useTestServer 
            ? "https://kvez79e5ib.execute-api.us-east-1.amazonaws.com" // Test server
            : "https://brto98doc9.execute-api.us-east-1.amazonaws.com" // Production server
    }
    
    // MARK: - New Racing Server API Integration
    
    /// Fetch all racing series metadata from the API
    func fetchSeries() async throws -> [RacingServerSeries] {
        let url = URL(string: "\(RacingAPIService.baseURL)/series")!
        print("🔗 Fetching all series from: \(url)")
        
        let (data, response) = try await session.data(from: url)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 Response: \(httpResponse.statusCode)")
            if httpResponse.statusCode != 200 {
                throw APIError.httpError(httpResponse.statusCode)
            }
        }
        
        do {
            let seriesList = try JSONDecoder().decode([RacingServerSeries].self, from: data)
            print("✅ Valid series parsed: \(seriesList.count)")
            return seriesList
        } catch {
            print("❌ Series decoding error: \(error)")
            throw APIError.decodingError(error)
        }
    }
    
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
    
    /// Fetch races for a specific series by slug
    func fetchSeriesRaces(seriesSlug: String) async throws -> [Race] {
        let url = URL(string: "\(RacingAPIService.baseURL)/races/\(seriesSlug)")!
        print("🔗 Fetching \(seriesSlug) races from: \(url)")
        
        let (data, response) = try await session.data(from: url)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 \(seriesSlug) Response: \(httpResponse.statusCode)")
            if httpResponse.statusCode != 200 {
                throw APIError.httpError(httpResponse.statusCode)
            }
        }
        
        let events = try JSONDecoder().decode([RacingServerEvent].self, from: data)
        print("📋 \(seriesSlug) events received: \(events.count)")
        
        let races = events.compactMap { $0.toRace() }
        print("✅ \(seriesSlug) valid races parsed: \(races.count)")
        
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
