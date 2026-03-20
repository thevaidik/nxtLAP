//
//  NewsService.swift
//  motorsports
//
//  Created by Antigravity on 20/03/26.
//

import Foundation

class NewsService: ObservableObject {
    private let baseURL = "https://meol2c3y91.execute-api.us-east-1.amazonaws.com"
    private let session = URLSession.shared
    
    func fetchNews() async throws -> [NewsArticle] {
        guard let url = URL(string: "\(baseURL)/news") else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await session.data(from: url)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            print("❌ HTTP Error: \(httpResponse.statusCode)")
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        // Debug: Print raw response
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📡 Raw API Response: \(jsonString)")
        }
        
        // Check if data is empty
        if data.isEmpty {
            print("❌ Empty response data")
            throw APIError.noDataAvailable("No news data available")
        }
        
        do {
            let decoder = JSONDecoder()
            let articles = try decoder.decode([NewsArticle].self, from: data)
            print("✅ Successfully decoded \(articles.count) articles")
            return articles
        } catch let DecodingError.keyNotFound(key, context) {
            print("❌ Missing key '\(key.stringValue)' - \(context.debugDescription)")
            print("   Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            throw APIError.decodingError(DecodingError.keyNotFound(key, context))
        } catch let DecodingError.typeMismatch(type, context) {
            print("❌ Type mismatch for type '\(type)' - \(context.debugDescription)")
            print("   Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            throw APIError.decodingError(DecodingError.typeMismatch(type, context))
        } catch {
            print("❌ Decoding error in NewsService: \(error)")
            throw APIError.decodingError(error)
        }
    }
}
