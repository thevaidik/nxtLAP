//
//  FantasyViewModel.swift
//  motorsports
//
//  Created for NxtLAP.
//

import SwiftUI

@MainActor
class FantasyViewModel: ObservableObject {
    @Published var coins: Int = 1000
    @Published var userPicks: [String: String] = [:] // Race ID -> Driver Name
    @Published var weeklyDraftPicks: [DriverCardTemplate?] = [nil, nil, nil]
    
    private let coinsKey = "nxtlap_fantasy_coins"
    private let picksKey = "nxtlap_fantasy_picks"
    
    init() {
        // Load Coins
        let savedCoins = UserDefaults.standard.integer(forKey: coinsKey)
        if savedCoins > 0 {
            self.coins = savedCoins
        } else {
            // First time user, initialize with 1000 and save
            UserDefaults.standard.set(1000, forKey: coinsKey)
            self.coins = 1000
        }
        
        // Load Picks
        if let savedPicks = UserDefaults.standard.dictionary(forKey: picksKey) as? [String: String] {
            self.userPicks = savedPicks
        }
    }
    
    func makePick(raceId: String, driver: String) {
        // Lock in the prediction
        userPicks[raceId] = driver
        UserDefaults.standard.set(userPicks, forKey: picksKey)
        HapticManager.shared.trigger(.medium)
    }
    
    func makeDraftPick(index: Int, driver: DriverCardTemplate) {
        guard index >= 0 && index < 3 else { return }
        weeklyDraftPicks[index] = driver
        HapticManager.shared.trigger(.medium)
    }
    
    func awardCoins(amount: Int) {
        coins += amount
        UserDefaults.standard.set(coins, forKey: coinsKey)
    }
}
