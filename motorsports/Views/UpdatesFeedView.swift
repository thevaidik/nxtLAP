// motorsports/Views/UpdatesFeedView.swift

import SwiftUI

struct UpdatesFeedView: View {
    @StateObject private var viewModel = CommViewModel()
    @EnvironmentObject var dataService: RacingDataService
    
    @State private var activeSidebarSelection = "general" // Default channel is "general"

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
                .onTapGesture {
                    hideKeyboard()
                }

            HStack(spacing: 0) {
                // ── Left Sidebar Navigation ──────────────────────────────────
                ServerSidebarView(activeSelection: $activeSidebarSelection, channels: viewModel.channels)

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
            async let fetchC: () = viewModel.fetchChannels()
            async let fetchM: () = viewModel.fetchMessages()
            _ = await (fetchC, fetchM)
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
                HStack {
                    Spacer(minLength: 0)
                    LazyVStack(alignment: .leading, spacing: 16) {
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
                    }
                    .padding(.vertical, 12)
                    .frame(maxWidth: 800)
                    Spacer(minLength: 0)
                }
            }
            .onTapGesture {
                hideKeyboard()
            }
            .refreshable {
                if activeSidebarSelection == "new" {
                    await dataService.refreshData()
                } else {
                    await viewModel.fetchMessages()
                }
            }
            .onAppear {
                // Feed defaults to the top naturally, which now holds the newest messages.
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

    private var currentChannel: CommChannel? {
        viewModel.channels.first(where: { $0.id == activeSidebarSelection })
    }

    private var channelTitle: String {
        currentChannel?.title ?? "General"
    }

    private var channelSubtitle: String {
        currentChannel?.subtitle ?? "Real-time updates"
    }

    private var filteredMessages: [CommMessage] {
        let baseMessages: [CommMessage]
        
        if activeSidebarSelection == "new" {
            baseMessages = clientMessages.sorted { $0.timestamp > $1.timestamp }
        } else {
            var msgs = viewModel.messages
            
            if let f = currentChannel?.filterBotName {
                msgs = msgs.filter { $0.botName == f }
            }
            if let e = currentChannel?.excludeBotName {
                msgs = msgs.filter { $0.botName != e }
            }
            
            baseMessages = msgs.sorted { $0.timestamp > $1.timestamp }
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

    /// Client-side synthesized bot updates about real upcoming races today and in the next 1 hour!
    private var clientMessages: [CommMessage] {
        var msgs: [CommMessage] = []
        let now = Date()
        let calendar = Calendar.current
        
        // 1. Bot 1: @nxt_10min Alert Bot (10-minute alert)
        let todayRaces = dataService.upcomingRaces.filter { race in
            calendar.isDateInToday(race.date)
        }
        
        for race in todayRaces {
            let timeUntilStart = race.date.timeIntervalSince(now)
            
            // 10-Minute Alert (triggers if the race starts within 10 minutes)
            if timeUntilStart > 0 && timeUntilStart <= 600 {
                let timeDiffMins = Int(timeUntilStart / 60)
                let content = "🚨 Sam's Alert: \(race.series.uppercased()) - The \(race.name) at \(race.circuit ?? race.location) starts in \(timeDiffMins) minutes. Cars heading to grid."
                
                let msgId = "client_bot_10m_\(race.id)"
                let msg = CommMessage(
                    id: msgId,
                    botName: "@nxt_10min",
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
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// ── Left Sidebar Navigation Component ────────────────────────────────────────

struct ServerSidebarView: View {
    @Binding var activeSelection: String
    let channels: [CommChannel]

    var body: some View {
        VStack(spacing: 16) {
            // 1. Small static App Logo Emblem
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
            
            // Render Dynamic Server Channels
            ForEach(channels) { channel in
                Button {
                    HapticManager.shared.selection()
                    withAnimation(.spring) { activeSelection = channel.id }
                } label: {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text(channel.shortName)
                                .font(.system(size: channel.shortName.count > 2 ? 10 : 16, weight: .black))
                                .foregroundColor(activeSelection == channel.id ? .white : .gray)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(activeSelection == channel.id ? Color.racingRed : Color.clear, lineWidth: 2)
                                .shadow(color: activeSelection == channel.id ? Color.racingRed.opacity(0.5) : Color.clear, radius: 4)
                        )
                }
                .buttonStyle(.plain)
            }
            
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
