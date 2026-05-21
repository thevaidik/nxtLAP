// motorsports/Services/CommService.swift

import Foundation

class CommService {
    // Replace with actual API Gateway URL after deployment
    private let baseURL = "https://nuned3r3w7.execute-api.us-east-1.amazonaws.com"
    private let session = URLSession.shared
    private let cacheKey = "cached_comm_messages"

    func fetchMessages(limit: Int = 50) async throws -> [CommMessage] {
        guard let url = URL(string: "\(baseURL)/updates/messages?limit=\(limit)") else {
            throw URLError(.badURL)
        }

        do {
            let (data, response) = try await session.data(from: url)

            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                throw APIError.httpError(http.statusCode)
            }

            let decoder = JSONDecoder()
            let messages = try decoder.decode([CommMessage].self, from: data)

            // Cache for offline use
            UserDefaults.standard.set(data, forKey: cacheKey)
            return messages

        } catch {
            // Offline fallback: return cached messages if available
            if let cached = UserDefaults.standard.data(forKey: cacheKey),
               let messages = try? JSONDecoder().decode([CommMessage].self, from: cached) {
                return messages
            }
            throw error
        }
    }

    func addReaction(to messageId: String, emoji: String, userId: String) async throws -> CommMessage {
        return try await sendReaction(messageId: messageId, emoji: emoji, action: "add", userId: userId)
    }

    func removeReaction(from messageId: String, emoji: String, userId: String) async throws -> CommMessage {
        return try await sendReaction(messageId: messageId, emoji: emoji, action: "remove", userId: userId)
    }

    private func sendReaction(
        messageId: String,
        emoji: String,
        action: String,
        userId: String
    ) async throws -> CommMessage {
        guard let url = URL(string: "\(baseURL)/updates/messages/\(messageId)/reactions") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode([
            "emoji": emoji,
            "action": action,
            "userId": userId
        ])

        let (data, response) = try await session.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw APIError.httpError(http.statusCode)
        }

        return try JSONDecoder().decode(CommMessage.self, from: data)
    }

    func fetchReplies(for messageId: String) async throws -> [CommReply] {
        guard let url = URL(string: "\(baseURL)/updates/messages/\(messageId)/replies") else {
            throw URLError(.badURL)
        }
        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw APIError.httpError(http.statusCode)
        }
        return try JSONDecoder().decode([CommReply].self, from: data)
    }

    func postReply(to messageId: String, content: String, userId: String) async throws -> CommReply {
        guard let url = URL(string: "\(baseURL)/updates/messages/\(messageId)/replies") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode([
            "userId": userId,
            "content": content
        ])

        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw APIError.httpError(http.statusCode)
        }
        return try JSONDecoder().decode(CommReply.self, from: data)
    }
}
