// motorsports/Views/ReactionBarView.swift

import SwiftUI

let allowedEmojis = ["🏁", "🏆", "🔥", "❤️", "👍", "😮"]

struct ReactionBarView: View {
    let message: CommMessage
    @ObservedObject var viewModel: CommViewModel
    @State private var showPicker: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            // Existing reactions as pill buttons
            ForEach(message.reactionCounts.sorted(by: { $0.key < $1.key }), id: \.key) { emoji, count in
                let hasReacted = message.reactions[emoji]?.userIds.contains(viewModel.deviceId) == true
                let textColor: Color = hasReacted ? .racingRed : .white
                let bgColor: Color = hasReacted ? Color.racingRed.opacity(0.12) : Color.white.opacity(0.08)
                let strokeColor: Color = hasReacted ? Color.racingRed.opacity(0.5) : Color.white.opacity(0.15)
                
                Button {
                    Task {
                        // Smart toggle: If user already reacted, remove it; else add it!
                        if hasReacted {
                            await viewModel.removeReaction(from: message, emoji: emoji)
                        } else {
                            await viewModel.addReaction(to: message, emoji: emoji)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(emoji)
                            .font(.system(size: 14))
                        Text("\(count)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(textColor)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(bgColor)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(strokeColor, lineWidth: 1)
                    )
                }
            }

            // "+" button to open emoji picker
            Button {
                showPicker.toggle()
                HapticManager.shared.selection()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 28, height: 24)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(12)
            }
        }
        .sheet(isPresented: $showPicker) {
            EmojiPickerSheet(message: message, viewModel: viewModel, isPresented: $showPicker)
                .presentationDetents([.height(120)])
        }
    }
}

struct EmojiPickerSheet: View {
    let message: CommMessage
    @ObservedObject var viewModel: CommViewModel
    @Binding var isPresented: Bool

    var body: some View {
        HStack(spacing: 16) {
            ForEach(allowedEmojis, id: \.self) { emoji in
                Button {
                    Task {
                        await viewModel.addReaction(to: message, emoji: emoji)
                        isPresented = false
                    }
                } label: {
                    Text(emoji)
                        .font(.system(size: 28))
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.systemBackground))
    }
}
