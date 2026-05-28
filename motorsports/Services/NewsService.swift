//
//  NewsService.swift
//  motorsports
//
//  Created by Vaidik Dubey on 20/03/26.
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
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let articles = try decoder.decode([NewsArticle].self, from: data)
        return articles
    }
}
