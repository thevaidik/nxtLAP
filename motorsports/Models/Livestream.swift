//
//  Livestream.swift
//  motorsports
//
//  Created by Antigravity on 10/04/26.
//

import Foundation

struct Livestream: Identifiable, Codable {
    let id: String
    let title: String
    let channelId: String
    let channelTitle: String
    let thumbnailUrl: String
    let scheduledStartTime: String
    let actualStartTime: String?
    let status: LivestreamStatus
    let videoUrl: String
    
    enum CodingKeys: String, CodingKey {
        case id, title, channelId, channelTitle, thumbnailUrl, scheduledStartTime, actualStartTime, status, videoUrl
    }
}

enum LivestreamStatus: String, Codable {
    case live = "live"
    case upcoming = "upcoming"
    case completed = "completed"
    
    var displayName: String {
        switch self {
        case .live: return "LIVE"
        case .upcoming: return "UPCOMING"
        case .completed: return "COMPLETED"
        }
    }
}
