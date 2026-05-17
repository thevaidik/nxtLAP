// motorsports/ViewModels/CommViewModel.swift

import SwiftUI

@MainActor
class CommViewModel: ObservableObject {
    @Published var messages: [CommMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var localReactions: [String: [String: ReactionData]] = [:]

    private let service = CommService()

    /// Persistent device ID used as userId for reactions.
    /// Generated once on first launch and stored in UserDefaults.
    var deviceId: String {
        if let existing = UserDefaults.standard.string(forKey: "deviceId") {
            return existing
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: "deviceId")
        return newId
    }

    func fetchMessages() async {
        isLoading = true
        errorMessage = nil
        do {
            messages = try await service.fetchMessages()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func addReaction(to message: CommMessage, emoji: String) async {
        // Toggle locally first so it feels INSTANT!
        toggleLocalReaction(for: message, emoji: emoji, add: true)
        
        // If it is a client-side synthesized bot, do not send to server!
        if message.id.hasPrefix("client_bot_") {
            return
        }
        
        do {
            let updated = try await service.addReaction(to: message.id, emoji: emoji, userId: deviceId)
            updateMessage(updated)
        } catch {
            // Silently fail — reaction is non-critical
            print("❌ addReaction failed: \(error)")
        }
    }

    func removeReaction(from message: CommMessage, emoji: String) async {
        // Toggle locally first so it feels INSTANT!
        toggleLocalReaction(for: message, emoji: emoji, add: false)
        
        // If it is a client-side synthesized bot, do not send to server!
        if message.id.hasPrefix("client_bot_") {
            return
        }
        
        do {
            let updated = try await service.removeReaction(from: message.id, emoji: emoji, userId: deviceId)
            updateMessage(updated)
        } catch {
            print("❌ removeReaction failed: \(error)")
        }
    }

    private func toggleLocalReaction(for message: CommMessage, emoji: String, add: Bool) {
        var currentReactions = localReactions[message.id] ?? message.reactions
        
        let currentReaction = currentReactions[emoji]
        let currentCount = currentReaction?.count ?? 0
        let currentUserIds = currentReaction?.userIds ?? []
        
        if add {
            if !currentUserIds.contains(deviceId) {
                let newCount = min(15, currentCount + 1) // Clamped at 15 max reactions!
                currentReactions[emoji] = ReactionData(count: newCount, userIds: currentUserIds + [deviceId])
            }
        } else {
            // Remove reaction
            let newCount = max(0, currentCount - 1)
            let newUserIds = currentUserIds.filter { $0 != deviceId }
            if newCount == 0 {
                currentReactions.removeValue(forKey: emoji)
            } else {
                currentReactions[emoji] = ReactionData(count: newCount, userIds: newUserIds)
            }
        }
        
        localReactions[message.id] = currentReactions
        HapticManager.shared.trigger(.light)
    }

    private func updateMessage(_ updated: CommMessage) {
        if let idx = messages.firstIndex(where: { $0.id == updated.id }) {
            messages[idx] = updated
        }
        // Also keep localReactions dictionary synchronized with the server's master state
        localReactions[updated.id] = updated.reactions
    }
}
