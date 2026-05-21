// motorsports/Views/MessageRepliesView.swift

import SwiftUI

struct MessageRepliesView: View {
    let message: CommMessage
    @ObservedObject var viewModel: CommViewModel
    
    @State private var replyText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Replies
            if viewModel.isFetchingReplies {
                ProgressView()
                    .padding(.vertical, 16)
            } else if let replies = viewModel.replies[message.id], !replies.isEmpty {
                VStack(spacing: 0) {
                    ForEach(replies) { reply in
                        replyRow(reply: reply)
                    }
                }
            }
            
            // Comment input area
            HStack(spacing: 12) {
                TextField("Add a comment...", text: $replyText)
                    .font(.system(size: 14))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(20)
                    .foregroundColor(.white)
                
                Button {
                    let content = replyText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !content.isEmpty else { return }
                    
                    Task {
                        await viewModel.postReply(to: message.id, content: content)
                    }
                    replyText = ""
                    hideKeyboard()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .racingRed)
                }
                .disabled(replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .padding(.leading, 48) // Indent the accordion so it lines up under the avatar
        .padding(.trailing, 16)
        .onAppear {
            if viewModel.replies[message.id] == nil {
                Task {
                    await viewModel.fetchReplies(for: message.id)
                }
            }
        }
    }
    
    private func replyRow(reply: CommReply) -> some View {
        let isMine = reply.userId == viewModel.deviceId
        
        return HStack(alignment: .top, spacing: 12) {
            // User Avatar
            Circle()
                .fill(isMine ? Color.racingRed : Color.gray.opacity(0.3))
                .frame(width: 24, height: 24)
                .overlay(
                    Image(systemName: isMine ? "person.fill" : "person")
                        .font(.system(size: 10))
                        .foregroundColor(isMine ? .white : .white.opacity(0.8))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(isMine ? "You" : "User\(reply.userId.prefix(4).uppercased())")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(isMine ? .racingRed : .white)
                    
                    Text(reply.formattedTimestamp)
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
                
                Text(reply.content)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.9))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
