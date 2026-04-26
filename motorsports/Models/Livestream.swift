//
//  Livestream.swift
//  motorsports
//
//  Created by Vaidik Dubey on 10/04/26.
//

import Foundation
import SwiftUI

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
    
    var startDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: scheduledStartTime) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: scheduledStartTime)
    }
    
    var relativeTime: String {
        guard let date = startDate else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    /// Time-based status derived purely from device clock.
    /// YouTube's `status` field lags behind; we know the schedule.
    /// - Upcoming:  startDate > now
    /// - Live:      now >= startDate && now <= startDate + 4 hours
    /// - Completed: now > startDate + 4 hours  (or server says completed)
    var effectiveStatus: LivestreamStatus {
        if status == .completed { return .completed }
        guard let start = startDate else { return status }
        return Date() < start ? .upcoming : .live
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
    
    var buttonTitle: String {
        switch self {
        case .live: return "Watch Now"
        case .upcoming: return "Watch"
        case .completed: return "Watch"
        }
    }
    
    var statusColor: Color {
        switch self {
        case .live: return .red
        case .upcoming: return .blue
        case .completed: return .gray
        }
    }
}
