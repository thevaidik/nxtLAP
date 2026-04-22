//
//  LivestreamService.swift
//  motorsports
//
//  Created by Vaidik Dubey on 10/04/26.
//

import Foundation

class LivestreamService {
    private let session = URLSession.shared
    private let urlString = "https://650wjqhzhc.execute-api.us-east-1.amazonaws.com/livestreams"
    
    func fetchLivestreams() async throws -> [Livestream] {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await session.data(from: url)
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode != 200 {
                throw APIError.httpError(httpResponse.statusCode)
            }
        }
        
        do {
            let decoder = JSONDecoder()
            let streams = try decoder.decode([Livestream].self, from: data)
            return streams
        } catch {
            print("❌ Decoding error in LivestreamService: \(error)")
            throw APIError.decodingError(error)
        }
    }
}
