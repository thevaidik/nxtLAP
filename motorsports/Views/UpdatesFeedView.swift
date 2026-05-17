// motorsports/Views/UpdatesFeedView.swift

import SwiftUI

struct UpdatesFeedView: View {
    @StateObject private var viewModel = CommViewModel()
    @EnvironmentObject var dataService: RacingDataService
    
    @State private var activeSidebarSelection = "general" // Default channel is "general"

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            HStack(spacing: 0) {
                // ── Left Sidebar Navigation ──────────────────────────────────
                ServerSidebarView(activeSelection: $activeSidebarSelection)

                // ── Main Chat Feed Panel ─────────────────────────────────────
                VStack(spacing: 0) {
                    // Custom Header (matches inspiration screenshot!)
                    channelHeaderView

                    Divider()
                        .background(Color.white.opacity(0.1))

                    // Feed Scroll Area
                    ZStack {
                        Color.black.ignoresSafeArea()

                        if viewModel.isLoading && viewModel.messages.isEmpty {
                            loadingView
                        } else if let error = viewModel.errorMessage, viewModel.messages.isEmpty {
                            errorView(error)
                        } else if filteredMessages.isEmpty {
                            emptyView
                        } else {
                            feedView
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true) // We use our own high-fidelity custom header
        .task {
            await viewModel.fetchMessages()
        }
    }

    // ── Sub-views ────────────────────────────────────────────────────────────

    private var channelHeaderView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("#")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.gray)
                    
                    Text(channelTitle)
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.white)
                    
                    // Blue Verified Badge (exactly as shown in inspiration!)
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.blue)
                    
                    // Premium Beta Badge
                    Text("BETA")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.racingRed)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.racingRed.opacity(0.12))
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.racingRed.opacity(0.3), lineWidth: 0.5)
                        )
                }
            }
            
            Spacer()
            
            // Ellipsis Menu Button (exactly as shown in inspiration!)
            Button {
                HapticManager.shared.selection()
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.white.opacity(0.05))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(red: 0.08, green: 0.08, blue: 0.09))
    }

    private var feedView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    if activeSidebarSelection == "new" {
                        // ── "NEW" Local Feed: Raw, clean borderless telemetry updates directly on dark chat panel ──
                        ForEach(filteredMessages) { message in
                            MessageBubbleView(
                                message: message,
                                viewModel: viewModel,
                                isFirst: false,
                                isLast: false,
                                hasThread: false
                            )
                        }
                        
                        // Invisible anchor at the bottom of the feed for scrolling
                        Color.clear
                            .frame(height: 1)
                            .id("new_feed_bottom")
                    } else {
                        // ── Standard General Feed: Grouped by Matchups ──
                        ForEach(groupedMessages) { group in
                            VStack(alignment: .leading, spacing: 0) {
                                matchupHeader(title: group.headerTitle, series: group.series)

                                ZStack(alignment: .leading) {
                                    if group.messages.count > 1 {
                                        Rectangle()
                                            .fill(Color.white.opacity(0.15))
                                            .frame(width: 2)
                                            .padding(.leading, 34)
                                            .padding(.top, 24)
                                            .padding(.bottom, 24)
                                    }

                                    VStack(alignment: .leading, spacing: 0) {
                                        ForEach(Array(group.messages.enumerated()), id: \.element.id) { index, message in
                                            MessageBubbleView(
                                                message: message,
                                                viewModel: viewModel,
                                                isFirst: index == 0,
                                                isLast: index == group.messages.count - 1,
                                                hasThread: group.messages.count > 1
                                            )
                                        }
                                    }
                                }
                            }
                            .background(Color.white.opacity(0.015))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.04), lineWidth: 1)
                            )
                            .padding(.horizontal, 12)
                            .id(group.messages.last?.id)
                        }
                    }
                }
                .padding(.vertical, 12)
            }
            .refreshable {
                if activeSidebarSelection == "new" {
                    await dataService.refreshData()
                } else {
                    await viewModel.fetchMessages()
                }
            }
            .onAppear {
                if activeSidebarSelection == "new" {
                    proxy.scrollTo("new_feed_bottom", anchor: .bottom)
                } else if let lastMessageId = filteredMessages.last?.id {
                    proxy.scrollTo(lastMessageId, anchor: .bottom)
                }
            }
        }
    }

    private func matchupHeader(title: String, series: String) -> some View {
        HStack(spacing: 8) {
            // Series Icon Badge
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(seriesColor(series).opacity(0.15))
                    .frame(width: 24, height: 24)
                
                Image(systemName: seriesIcon(series))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(seriesColor(series))
            }
            
            Text(title)
                .font(.system(size: 12, weight: .black))
                .foregroundColor(.white)
                .tracking(0.5)
            
            Spacer()
            
            // Real-time status dot
            HStack(spacing: 4) {
                Circle()
                    .fill(activeSidebarSelection == "new" ? Color.green : Color.racingRed)
                    .frame(width: 5, height: 5)
                
                Text(activeSidebarSelection == "new" ? "LOCAL" : "BOT")
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(activeSidebarSelection == "new" ? .green : .racingRed)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background((activeSidebarSelection == "new" ? Color.green : Color.racingRed).opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.03))
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .racingRed))
                .scaleEffect(1.3)
            Text("Loading updates...")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.racingRed)
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)
            Button {
                Task { await viewModel.fetchMessages() }
            } label: {
                Text("Retry")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.racingRed)
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "bell.slash.fill")
                .font(.largeTitle)
                .foregroundColor(.gray)
            Text("No updates yet.\nCheck back soon for live racing events!")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // ── Helper Models & Data Processing ──────────────────────────────────────

    struct MessageGroup: Identifiable {
        let id = UUID()
        let headerTitle: String
        let series: String
        let messages: [CommMessage]
    }

    private var channelTitle: String {
        switch activeSidebarSelection {
        case "general": return "General"
        case "new": return "Updates New"
        default: return "General"
        }
    }

    private var channelSubtitle: String {
        switch activeSidebarSelection {
        case "general": return "Automated Telemetry Bot Feed"
        case "new": return "App Telemetry Alerts Bot"
        default: return "Real-time updates"
        }
    }

    private var filteredMessages: [CommMessage] {
        let baseMessages: [CommMessage]
        if activeSidebarSelection == "new" {
            baseMessages = clientMessages
        } else {
            baseMessages = viewModel.messages
        }
        
        return baseMessages.map { msg in
            if let local = viewModel.localReactions[msg.id] {
                return CommMessage(
                    id: msg.id,
                    botName: msg.botName,
                    content: msg.content,
                    timestamp: msg.timestamp,
                    messageType: msg.messageType,
                    raceId: msg.raceId,
                    reactions: local,
                    replyCount: msg.replyCount
                )
            }
            return msg
        }
    }

    private var groupedMessages: [MessageGroup] {
        var groups: [MessageGroup] = []
        var currentRaceId: String? = nil
        var currentMessages: [CommMessage] = []
        var currentHeader = ""
        var currentSeries = "general"
        
        for message in filteredMessages {
            let msgRaceId = message.raceId ?? "general"
            let msgDetails = message.parsedDetails
            
            if msgRaceId == currentRaceId && msgRaceId != "general" {
                currentMessages.append(message)
            } else {
                if !currentMessages.isEmpty {
                    groups.append(MessageGroup(headerTitle: currentHeader, series: currentSeries, messages: currentMessages))
                }
                currentRaceId = msgRaceId
                currentMessages = [message]
                currentHeader = msgDetails.headerTitle
                currentSeries = msgDetails.series
            }
        }
        if !currentMessages.isEmpty {
            groups.append(MessageGroup(headerTitle: currentHeader, series: currentSeries, messages: currentMessages))
        }
        return groups
    }

    /// Client-side synthesized bot updates about real upcoming races today and in the next 1 hour!
    private var clientMessages: [CommMessage] {
        var msgs: [CommMessage] = []
        let now = Date()
        let calendar = Calendar.current
        
        // 1. Bot 1: Daily Briefing Bot (@nxt_daily) - All races scheduled for today
        // Posted at 7:00 AM today so it is always already there when the user opens the app!
        let todayRaces = dataService.upcomingRaces.filter { race in
            calendar.isDateInToday(race.date)
        }
        
        for race in todayRaces {
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            let timeStr = timeFormatter.string(from: race.date)
            
            let content = "☀️ Daily Briefing: \(race.series.uppercased()) - The \(race.name) is scheduled for today at \(timeStr) at \(race.circuit ?? race.location)."
            
            // Set timestamp to 7:00 AM of today so it's simulated as already posted
            let morningTime = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: now) ?? now
            
            let msgId = "client_bot_daily_\(race.id)"
            let msg = CommMessage(
                id: msgId,
                botName: "@nxt_daily",
                content: content,
                timestamp: ISO8601DateFormatter().string(from: morningTime),
                messageType: .general,
                raceId: race.id,
                reactions: generateRandomReactions(forSeed: msgId),
                replyCount: 0
            )
            msgs.append(msg)
        }
        
        // 2. Bot 2 & 3: @nxt_sam Alert Bot (2-hour alert and 10-minute alert)
        for race in todayRaces {
            let timeUntilStart = race.date.timeIntervalSince(now)
            
            // 2-Hour Alert (triggers if the race starts within 2 hours)
            if timeUntilStart > 0 && timeUntilStart <= 7200 {
                let content = "🔔 Sam's Alert: \(race.series.uppercased()) - The \(race.name) at \(race.circuit ?? race.location) starts in 2 hours. Set your notifications."
                
                // Simulated to have been posted a few minutes ago or now
                let postTime = now.addingTimeInterval(-600)
                
                let msgId = "client_bot_2h_\(race.id)"
                let msg = CommMessage(
                    id: msgId,
                    botName: "@nxt_sam",
                    content: content,
                    timestamp: ISO8601DateFormatter().string(from: postTime),
                    messageType: .raceStart,
                    raceId: race.id,
                    reactions: generateRandomReactions(forSeed: msgId),
                    replyCount: 0
                )
                msgs.append(msg)
            }
            
            // 10-Minute Alert (triggers if the race starts within 10 minutes)
            if timeUntilStart > 0 && timeUntilStart <= 600 {
                let timeDiffMins = Int(timeUntilStart / 60)
                let content = "🚨 Sam's Alert: \(race.series.uppercased()) - The \(race.name) at \(race.circuit ?? race.location) starts in \(timeDiffMins) minutes. Cars heading to grid."
                
                let msgId = "client_bot_10m_\(race.id)"
                let msg = CommMessage(
                    id: msgId,
                    botName: "@nxt_sam",
                    content: content,
                    timestamp: ISO8601DateFormatter().string(from: now),
                    messageType: .raceStart,
                    raceId: race.id,
                    reactions: generateRandomReactions(forSeed: msgId),
                    replyCount: 0
                )
                msgs.append(msg)
            }
        }
        
        // 3. Fallback Preview Feed: If no races are scheduled for today, showcase professional future previews
        if msgs.isEmpty {
            let nextRaces = Array(dataService.upcomingRaces.prefix(3))
            for (idx, race) in nextRaces.enumerated() {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                let dateStr = dateFormatter.string(from: race.date)
                
                let timeFormatter = DateFormatter()
                timeFormatter.timeStyle = .short
                let timeStr = timeFormatter.string(from: race.date)
                
                let content = "📅 Schedule Preview: \(race.series.uppercased()) - The \(race.name) is scheduled for \(dateStr) at \(timeStr) at \(race.circuit ?? race.location)."
                
                let yesterday = now.addingTimeInterval(-86400 * Double(idx + 1))
                
                let msgId = "client_bot_preview_\(race.id)"
                let msg = CommMessage(
                    id: msgId,
                    botName: "@nxt_daily", // Daily bot handles scheduled previews
                    content: content,
                    timestamp: ISO8601DateFormatter().string(from: yesterday),
                    messageType: .general,
                    raceId: race.id,
                    reactions: generateRandomReactions(forSeed: msgId),
                    replyCount: 0
                )
                msgs.append(msg)
            }
        }
        
        return msgs.sorted { $0.timestamp < $1.timestamp }
    }
    
    private func generateRandomReactions(forSeed seed: String) -> [String: ReactionData] {
        let allowed = ["🏁", "🏆", "🔥", "❤️", "👍", "😮"]
        var result: [String: ReactionData] = [:]
        
        // 1. Compute a chaotic seed using strict 32-bit djb2 string hashing
        var seedVal: UInt32 = 5381
        for char in seed.utf8 {
            seedVal = ((seedVal << 5) &+ seedVal) &+ UInt32(char)
        }
        
        // 2. Strict 32-bit Linear Congruential Generator (LCG)
        func nextRand() -> UInt32 {
            seedVal = (seedVal &* 1664525 &+ 1013904223)
            return seedVal
        }
        
        // 3. Warm up the LCG state to fully scatter the starting hash value
        _ = nextRand()
        
        // 4. Decide number of reactions: organically between 1 and 5 unique emojis
        let numberOfReactions = Int(nextRand() % 5) + 1
        
        // 5. Chaotically shuffle the allowed emojis using a seeded Fisher-Yates shuffle
        var shuffledAllowed = allowed
        for i in (1..<shuffledAllowed.count).reversed() {
            let j = Int(nextRand() % UInt32(i + 1))
            shuffledAllowed.swapAt(i, j)
        }
        
        // 6. Select the emojis and assign a truly random count between 1 and 15
        for i in 0..<numberOfReactions {
            let emoji = shuffledAllowed[i]
            let count = Int(nextRand() % 15) + 1 // Count strictly between 1 and 15!
            result[emoji] = ReactionData(count: count, userIds: [])
        }
        
        return result
    }

    private func seriesIcon(_ series: String) -> String {
        switch series {
        case "formula1": return "car.side.fill"
        case "motogp": return "motorcycle.fill"
        case "nascar": return "checkerboard.shield"
        default: return "antenna.radiowaves.left.and.right"
        }
    }

    private func seriesColor(_ series: String) -> Color {
        switch series {
        case "formula1": return .red
        case "motogp": return .orange
        case "nascar": return .yellow
        default: return .racingRed
        }
    }
}

// ── Left Sidebar Navigation Component ────────────────────────────────────────

struct ServerSidebarView: View {
    @Binding var activeSelection: String

    var body: some View {
        VStack(spacing: 16) {
            // 1. Small static App Logo Emblem (Using the official NxtLAP logo image!)
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .cornerRadius(6)
                .padding(.top, 16)
            
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
                .padding(.horizontal, 12)
            
            // 2. NxtLAP Channel Logo (Opens Default "General" Bot Channel!)
            // Highlighted active state gets a beautiful RED SQUARE border around its logo, but the inside does not change fill color!
            Button {
                HapticManager.shared.selection()
                withAnimation(.spring) { activeSelection = "general" }
            } label: {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text("N")
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(activeSelection == "general" ? .white : .gray)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(activeSelection == "general" ? Color.racingRed : Color.clear, lineWidth: 2)
                            .shadow(color: activeSelection == "general" ? Color.racingRed.opacity(0.5) : Color.clear, radius: 4)
                    )
            }
            .buttonStyle(.plain)

            // 3. "Updates New" Channel Button
            // Highlighted active state gets a beautiful RED SQUARE border around its logo, but the inside does not change fill color!
            Button {
                HapticManager.shared.selection()
                withAnimation(.spring) { activeSelection = "new" }
            } label: {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text("NEW")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(activeSelection == "new" ? .white : .gray)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(activeSelection == "new" ? Color.racingRed : Color.clear, lineWidth: 2)
                            .shadow(color: activeSelection == "new" ? Color.racingRed.opacity(0.5) : Color.clear, radius: 4)
                    )
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Add server button
            Button {
                HapticManager.shared.trigger(.light)
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.15), style: StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [3]))
                        .frame(width: 38, height: 38)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            .buttonStyle(.plain)
            .padding(.bottom, 6)
            
            // Settings button
            Button {
                HapticManager.shared.trigger(.light)
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.gray.opacity(0.6))
            }
            .buttonStyle(.plain)
            .padding(.bottom, 24)
        }
        .frame(width: 60)
        .background(Color(red: 0.05, green: 0.05, blue: 0.06))
    }
}
