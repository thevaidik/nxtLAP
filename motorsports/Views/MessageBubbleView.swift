// motorsports/Views/MessageBubbleView.swift

import SwiftUI

struct MessageBubbleView: View {
    let message: CommMessage
    @ObservedObject var viewModel: CommViewModel
    let isFirst: Bool
    let isLast: Bool
    let hasThread: Bool

    @State private var showPicker = false

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
                    
                    Image(systemName: avatarIcon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
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
                    Text(message.content)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.95))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    // Reaction bar
                    if !message.reactionCounts.isEmpty {
                        ReactionBarView(message: message, viewModel: viewModel)
                            .padding(.top, 4)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            // Curved thread line connecting to "view discussion" button (matches inspiration screenshot!)
            if isLast && hasThread && message.botName != "@nxt_sam" && message.botName != "@nxt_daily" {
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
    }

    // ── Helper Styling computed properties ───────────────────────────────────

    private var avatarGradient: LinearGradient {
        if message.botName == "@nxt_sam" {
            return LinearGradient(colors: [Color.purple, Color.pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else if message.botName == "@nxt_daily" {
            return LinearGradient(colors: [Color.yellow, Color.orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        
        switch message.parsedDetails.series {
        case "formula1":
            return LinearGradient(colors: [Color.red, Color(red: 0.1, green: 0.1, blue: 0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "motogp":
            return LinearGradient(colors: [Color.orange, Color.red], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "nascar":
            return LinearGradient(colors: [Color.blue, Color.yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "formulae":
            return LinearGradient(colors: [Color.purple, Color.cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [Color.racingRed, Color(red: 0.15, green: 0.15, blue: 0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var avatarIcon: String {
        if message.botName == "@nxt_sam" {
            return "clock.fill"
        } else if message.botName == "@nxt_daily" {
            return "sun.max.fill"
        }
        
        switch message.parsedDetails.series {
        case "formula1": return "car.side.fill"
        case "motogp": return "motorcycle.fill"
        case "nascar": return "checkerboard.shield"
        default: return "antenna.radiowaves.left.and.right"
        }
    }

    private var avatarColor: Color {
        if message.botName == "@nxt_sam" {
            return .pink
        } else if message.botName == "@nxt_daily" {
            return .orange
        }
        
        switch message.parsedDetails.series {
        case "formula1": return .red
        case "motogp": return .orange
        case "nascar": return .yellow
        default: return .racingRed
        }
    }
}
