// motorsports/Views/MessageBubbleView.swift

import SwiftUI

struct MessageBubbleView: View {
    let message: CommMessage
    @ObservedObject var viewModel: CommViewModel
    let isFirst: Bool
    let isLast: Bool
    let hasThread: Bool

    @State private var showPicker = false
    @State private var showReplies = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 12) {
                // Bot avatar with racing gradient
                ZStack {
                    Circle()
                        .fill(avatarGradient)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                }
                .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 4) {
                    // Header row: bot name + timestamp (next to each other)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(message.botName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(message.formattedTimestamp)
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }

                    // Message content
                    Text(localizedContent)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.95))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    // Reaction & Action bar
                    HStack(spacing: 12) {
                        if !message.reactionCounts.isEmpty {
                            ReactionBarView(message: message, viewModel: viewModel)
                        }
                        
                        if message.botName != "@nxt_10min" {
                            Button {
                                HapticManager.shared.trigger(.light)
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showReplies.toggle()
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "bubble.right\(showReplies ? ".fill" : "")")
                                        .font(.system(size: 14, weight: .semibold))
                                    if let count = message.replyCount, count > 0 {
                                        Text("\(count)")
                                            .font(.system(size: 13, weight: .semibold))
                                    }
                                }
                                .foregroundColor(showReplies ? .racingRed : .secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(showReplies ? Color.racingRed.opacity(0.15) : Color.white.opacity(0.08))
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 4)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            // Curved thread line connecting to "view discussion" button
            if isLast && hasThread && message.botName != "@nxt_10min" {
                HStack(spacing: 8) {
                    Path { path in
                        path.move(to: CGPoint(x: 18, y: -4))
                        path.addQuadCurve(to: CGPoint(x: 36, y: 12), control: CGPoint(x: 18, y: 12))
                    }
                    .stroke(Color.white.opacity(0.15), lineWidth: 2)
                    .frame(width: 36, height: 14)
                    .padding(.leading, 16)
                    
                    Button {
                        HapticManager.shared.trigger(.light)
                    } label: {
                        Text("view discussion")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, -6)
            }
        }
        .contentShape(Rectangle())
        .onLongPressGesture {
            HapticManager.shared.trigger(.medium)
            showPicker = true
        }
        .sheet(isPresented: $showPicker) {
            EmojiPickerSheet(message: message, viewModel: viewModel, isPresented: $showPicker)
                .presentationDetents([.height(120)])
        }
        
        // Inline Replies Expansion
        if showReplies {
            MessageRepliesView(message: message, viewModel: viewModel)
                .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    // ── Helper Styling computed properties ───────────────────────────────────

    private var localizedContent: String {
        var text = message.content
        guard let regex = try? NSRegularExpression(pattern: "<t:([^>]+)>", options: []) else {
            return text
        }
        
        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        
        let formatterWithFractional = ISO8601DateFormatter()
        formatterWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .none
        displayFormatter.timeStyle = .short
        
        for match in matches.reversed() {
            let matchRange = match.range
            let dateRange = match.range(at: 1)
            let dateStr = nsString.substring(with: dateRange)
            
            if let date = formatter.date(from: dateStr) ?? formatterWithFractional.date(from: dateStr) {
                let localTime = displayFormatter.string(from: date)
                text = (text as NSString).replacingCharacters(in: matchRange, with: "at \(localTime)")
            } else {
                text = (text as NSString).replacingCharacters(in: matchRange, with: "at \(dateStr)")
            }
        }
        
        return text
    }

    private var avatarGradient: LinearGradient {
        if message.botName == "@nxt_10min" {
            return LinearGradient(colors: [Color.purple, Color.pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        
        if message.botName == "@nxt_live" {
            // A vibrant cyan/blue/green gradient for live updates
            return LinearGradient(colors: [Color.cyan, Color.blue], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        
        // All generic bots use the primary NxtLAP "race colors" gradient
        return LinearGradient(colors: [Color.racingRed, Color(red: 0.15, green: 0.15, blue: 0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
