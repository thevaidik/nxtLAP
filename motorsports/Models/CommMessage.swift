// motorsports/Models/CommMessage.swift

import Foundation

/// Per-emoji reaction data from the server.
/// Server sends { count, userIds } but userIds is always empty (stripped server-side).
struct ReactionData: Codable, Equatable {
    let count: Int
    let userIds: [String] // Always empty — server strips before sending
}

/// Matches the Rust CommMessage struct (camelCase, reactions stripped of userIds by server).
struct CommMessage: Identifiable, Codable, Equatable {
    let id: String
    let botName: String          // "@nxt_max"
    let content: String
    let timestamp: String        // ISO 8601 string
    let messageType: MessageType
    let raceId: String?
    let reactions: [String: ReactionData] // emoji → {count, userIds:[]}
    let replyCount: Int?         // Reserved for future use

    enum MessageType: String, Codable {
        case raceStart    = "raceStart"
        case raceStarted  = "raceStarted"
        case raceFinished = "raceFinished"
        case general      = "general"
    }

    /// Convenience to get reaction counts as [String: Int] for display
    var reactionCounts: [String: Int] {
        reactions.reduce(into: [:]) { result, pair in
            result[pair.key] = pair.value.count
        }
    }

    /// Structured data parsed from automated chat messages to power grouped matchup feeds
    struct ParsedMessageDetails {
        let series: String
        let eventName: String
        let circuit: String
        let headerTitle: String
    }

    var parsedDetails: ParsedMessageDetails {
        var series = "general"
        var eventName = "NxtLAP Announcement"
        var circuit = "NxtLAP Headquarters"
        
        // Extract series inside parentheses, e.g. "(formula1)"
        if let openParen = content.lastIndex(of: "("),
           let closeParen = content.lastIndex(of: ")"),
           openParen < closeParen {
            let start = content.index(after: openParen)
            series = String(content[start..<closeParen]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        if content.contains("is about to start at ") {
            let parts = content.components(separatedBy: "is about to start at ")
            if parts.count >= 2 {
                var eventPart = parts[0]
                if eventPart.hasPrefix("🏁 The ") {
                    eventPart = String(eventPart.dropFirst(6))
                } else if eventPart.hasPrefix("🏁 ") {
                    eventPart = String(eventPart.dropFirst(2))
                }
                eventName = eventPart.trimmingCharacters(in: .whitespacesAndNewlines)
                
                let circuitPart = parts[1].components(separatedBy: "!")[0]
                circuit = circuitPart.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } else if content.contains("has started at ") {
            let parts = content.components(separatedBy: "has started at ")
            if parts.count >= 2 {
                var eventPart = parts[0]
                if eventPart.hasPrefix("🚦 The ") {
                    eventPart = String(eventPart.dropFirst(6))
                } else if eventPart.hasPrefix("🚦 ") {
                    eventPart = String(eventPart.dropFirst(2))
                }
                eventName = eventPart.trimmingCharacters(in: .whitespacesAndNewlines)
                
                let circuitPart = parts[1].components(separatedBy: "!")[0]
                circuit = circuitPart.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } else if content.contains("has finished! Great racing at ") {
            let parts = content.components(separatedBy: "has finished! Great racing at ")
            if parts.count >= 2 {
                var eventPart = parts[0]
                if eventPart.hasPrefix("🏆 The ") {
                    eventPart = String(eventPart.dropFirst(6))
                } else if eventPart.hasPrefix("🏆 ") {
                    eventPart = String(eventPart.dropFirst(2))
                }
                eventName = eventPart.trimmingCharacters(in: .whitespacesAndNewlines)
                
                let circuitPart = parts[1].components(separatedBy: ".")[0]
                circuit = circuitPart.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } else {
            eventName = "General Updates"
            circuit = "Global Feed"
        }
        
        let displaySeries = series.replacingOccurrences(of: "formula", with: "FORMULA ").uppercased()
        let shortEvent = eventName.replacingOccurrences(of: " Grand Prix", with: " GP")
            .replacingOccurrences(of: " Grand Prix of ", with: " GP")
            .uppercased()
        
        let headerTitle = "\(displaySeries) @ \(shortEvent)"
        return ParsedMessageDetails(series: series, eventName: eventName, circuit: circuit, headerTitle: headerTitle)
    }

    /// Relative or absolute timestamp string for display.
    var formattedTimestamp: String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // Try with fractional seconds first, then without
        let date = isoFormatter.date(from: timestamp)
            ?? ISO8601DateFormatter().date(from: timestamp)

        guard let date else { return timestamp }

        let diff = Date().timeIntervalSince(date)
        if diff < 60 {
            return "Now"
        } else if diff < 3600 {
            let mins = Int(diff / 60)
            return "\(mins)m"
        } else if diff < 86400 {
            let hours = Int(diff / 3600)
            return "\(hours)h"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
}
