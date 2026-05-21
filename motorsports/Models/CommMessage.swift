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
        case raceStart      = "raceStart"
        case raceStarted    = "raceStarted"
        case raceFinished   = "raceFinished"
        case general        = "general"
        case dailyBriefing  = "dailyBriefing"
        case twoHourAlert   = "twoHourAlert"
        case tenMinuteAlert = "tenMinuteAlert"
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
        } else if content.contains("☀️ Daily Briefing:") {
            // e.g. "☀️ Daily Briefing: FORMULA1 - The Monaco Grand Prix is scheduled for today at 13:00 at Monaco. (formula1)"
            let parts = content.components(separatedBy: " - The ")
            if parts.count >= 2 {
                let rest = parts[1]
                let schedParts = rest.components(separatedBy: " is scheduled for today at ")
                if schedParts.count >= 2 {
                    eventName = schedParts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    let atParts = schedParts[1].components(separatedBy: " at ")
                    if atParts.count >= 2 {
                        let rawCircuit = atParts[1]
                        if let dotIdx = rawCircuit.firstIndex(of: ".") {
                            circuit = String(rawCircuit[..<dotIdx]).trimmingCharacters(in: .whitespacesAndNewlines)
                        } else {
                            circuit = rawCircuit.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                    }
                }
            }
        } else if content.contains("🔔 Sam's Alert:") {
            // e.g. "🔔 Sam's Alert: FORMULA1 - The Monaco Grand Prix at Monaco starts in 2 hours. Set your notifications. (formula1)"
            let parts = content.components(separatedBy: " - The ")
            if parts.count >= 2 {
                let rest = parts[1]
                let atParts = rest.components(separatedBy: " at ")
                if atParts.count >= 2 {
                    eventName = atParts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    let inParts = atParts[1].components(separatedBy: " starts in ")
                    if inParts.count >= 2 {
                        circuit = inParts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
            }
        } else if content.contains("🚨 Sam's Alert:") {
            // e.g. "🚨 Sam's Alert: FORMULA1 - The Monaco Grand Prix at Monaco starts in 10 minutes. Cars heading to grid. (formula1)"
            let parts = content.components(separatedBy: " - The ")
            if parts.count >= 2 {
                let rest = parts[1]
                let atParts = rest.components(separatedBy: " at ")
                if atParts.count >= 2 {
                    eventName = atParts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    let inParts = atParts[1].components(separatedBy: " starts in ")
                    if inParts.count >= 2 {
                        circuit = inParts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
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

        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let startOfNow = calendar.startOfDay(for: Date())
            let startOfDate = calendar.startOfDay(for: date)
            let components = calendar.dateComponents([.day], from: startOfDate, to: startOfNow)
            if let day = components.day, day > 1 {
                return "\(day) days ago"
            }
            
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }
}

/// A user's reply to a message
struct CommReply: Identifiable, Codable, Equatable {
    let id: String
    let parentId: String
    let userId: String
    let content: String
    let timestamp: String

    var formattedTimestamp: String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let date = isoFormatter.date(from: timestamp)
            ?? ISO8601DateFormatter().date(from: timestamp)

        guard let date else { return timestamp }

        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let startOfNow = calendar.startOfDay(for: Date())
            let startOfDate = calendar.startOfDay(for: date)
            let components = calendar.dateComponents([.day], from: startOfDate, to: startOfNow)
            if let day = components.day, day > 1 {
                return "\(day) days ago"
            }
            
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }
}
