//
//  FantasyViewModel.swift
//  motorsports
//
//  Created for NxtLAP.
//

import SwiftUI
import Amplify
import AWSPluginsCore

@MainActor
class FantasyViewModel: ObservableObject {
    @Published var coins: Int = 1000
    @Published var userPicks: [String: String] = [:] // Race ID -> Driver Name
    @Published var weeklyDraftPicks: [DriverCardTemplate?] = [nil, nil, nil]
    
    private let coinsKey = "nxtlap_fantasy_coins"
    private let picksKey = "nxtlap_fantasy_picks"
    private let profileAPI = "https://gkyghno7i3smn3ts4t7d534s6e0lhdme.lambda-url.us-east-1.on.aws/"
    
    init() {
        // Load Coins from UserDefaults as an offline cache
        let savedCoins = UserDefaults.standard.integer(forKey: coinsKey)
        if savedCoins > 0 {
            self.coins = savedCoins
        } else {
            self.coins = 1000
        }
        
        // Load Picks
        if let savedPicks = UserDefaults.standard.dictionary(forKey: picksKey) as? [String: String] {
            self.userPicks = savedPicks
        }
    }
    
    func makePick(raceId: String, driver: String) {
        userPicks[raceId] = driver
        UserDefaults.standard.set(userPicks, forKey: picksKey)
        HapticManager.shared.trigger(.medium)
        syncStateToCloud()
    }
    
    func makeDraftPick(index: Int, driver: DriverCardTemplate) {
        guard index >= 0 && index < 3 else { return }
        weeklyDraftPicks[index] = driver
        HapticManager.shared.trigger(.medium)
        syncStateToCloud()
    }
    
    func awardCoins(amount: Int) {
        coins += amount
        UserDefaults.standard.set(coins, forKey: coinsKey)
        syncStateToCloud()
    }
    
    // Completely replaces local state persistence with cloud sync
    private func syncStateToCloud() {
        Task {
            do {
                let session = try await Amplify.Auth.fetchAuthSession()
                guard let tokens = try (session as? AuthCognitoTokensProvider)?.getCognitoTokens().get() else { return }
                
                var request = URLRequest(url: URL(string: profileAPI)!)
                request.httpMethod = "POST"
                request.addValue("Bearer \(tokens.accessToken)", forHTTPHeaderField: "Authorization")
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let draftStrings = weeklyDraftPicks.map { $0?.driverName ?? "" }
                let body: [String: Any] = [
                    "coins": coins,
                    "draftPicks": draftStrings
                ]
                
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                let (_, response) = try await URLSession.shared.data(for: request)
                
                if let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200 {
                    print("☁️ Fantasy State Synced Successfully")
                } else {
                    print("❌ Failed to sync Fantasy State")
                }
            } catch {
                print("❌ Network Error syncing state: \(error)")
            }
        }
    }
}
