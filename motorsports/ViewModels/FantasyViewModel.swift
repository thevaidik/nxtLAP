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
    @Published var draftLocked: Bool = false
    @Published var isSyncing: Bool = false
    @Published var showDailyBonusBanner: Bool = false
    @Published var showDailyBonusClaim: Bool = false
    @Published var dailyStreak: Int = 1
    @Published var currentDailyReward: Int = 50
    
    // Safety flag to prevent offline state from overwriting cloud state
    @Published var hasSuccessfullyFetchedCloudState: Bool = false
    
    // Market & Garage State
    @Published var availableCards: [DriverCardTemplate] = FantasyMockData.driverTemplates
    @Published var myGarage: [UserDriverCard] = []
    
    private let coinsKey = "nxtlap_fantasy_coins"
    private let picksKey = "nxtlap_fantasy_picks"
    private let garageKey = "nxtlap_fantasy_garage"
    private let lastDailyCheckInKey = "nxtlap_last_daily_checkin"
    private let streakKey = "nxtlap_daily_streak"
    private let profileAPI = "https://gkyghno7i3smn3ts4t7d534s6e0lhdme.lambda-url.us-east-1.on.aws/"
    
    init() {
        // Load Coins from UserDefaults as an offline cache
        let savedCoins = UserDefaults.standard.integer(forKey: coinsKey)
        if savedCoins > 0 {
            self.coins = savedCoins
        } else {
            self.coins = 2000 // Starting balance for new users
        }
        
        // Load Picks
        if let savedPicks = UserDefaults.standard.dictionary(forKey: picksKey) as? [String: String] {
            self.userPicks = savedPicks
        }
        
        // Load Garage
        if let data = UserDefaults.standard.data(forKey: garageKey),
           let savedGarage = try? JSONDecoder().decode([UserDriverCard].self, from: data) {
            self.myGarage = savedGarage
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
        saveCoins()
        syncStateToCloud()
    }
    
    private func saveCoins() {
        UserDefaults.standard.set(coins, forKey: coinsKey)
    }
    
    private func saveGarage() {
        if let data = try? JSONEncoder().encode(myGarage) {
            UserDefaults.standard.set(data, forKey: garageKey)
        }
    }
    
    // MARK: - Daily Check-In Bonus
    func checkDailyBonusEligibility() {
        let lastCheckIn = UserDefaults.standard.object(forKey: lastDailyCheckInKey) as? Date
        let cal = Calendar.current
        
        // Calculate Streak
        let storedStreak = UserDefaults.standard.integer(forKey: streakKey)
        if let last = lastCheckIn, cal.isDateInYesterday(last) {
            dailyStreak = storedStreak >= 7 ? 1 : storedStreak + 1
        } else if let last = lastCheckIn, cal.isDateInToday(last) {
            dailyStreak = storedStreak == 0 ? 1 : storedStreak
        } else {
            // Missed a day or first time
            dailyStreak = 1
        }
        
        // Calculate Reward
        if dailyStreak == 7 { currentDailyReward = 500 }
        else if dailyStreak == 3 { currentDailyReward = 150 }
        else { currentDailyReward = 50 }
        
        let isEligible = lastCheckIn == nil || !cal.isDateInToday(lastCheckIn!)
        if isEligible {
            withAnimation {
                showDailyBonusClaim = true
            }
        }
    }
    
    func claimDailyBonus() {
        awardCoins(amount: currentDailyReward)
        UserDefaults.standard.set(Date(), forKey: lastDailyCheckInKey)
        UserDefaults.standard.set(dailyStreak, forKey: streakKey)
    }
    
    // MARK: - Market & Garage Operations
    
    func fetchMarketCards(series: String? = nil) async {
        var urlString = "https://o0oi1p29j2.execute-api.us-east-1.amazonaws.com"
        if let s = series, !s.isEmpty {
            urlString += "/?series=\(s)"
        }
        
        guard let url = URL(string: urlString) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let cards = try decoder.decode([DriverCardTemplate].self, from: data)
            
            await MainActor.run {
                self.availableCards = cards
            }
        } catch {
            print("Failed to fetch fantasy cards from server: \(error)")
        }
    }
    
    func purchaseCard(template: DriverCardTemplate) {
        // Prevent duplicate purchases
        guard !myGarage.contains(where: { $0.template.id == template.id }) else {
            print("Already own this card")
            return
        }
        
        guard coins >= template.basePriceNxt else {
            print("Insufficient Nxt")
            return
        }
        
        // Deduct balance
        coins -= template.basePriceNxt
        saveCoins()
        
        // Add to garage
        let newCard = UserDriverCard(
            id: UUID(),
            template: template,
            tier: .common, // Starts at common
            totalYieldNxt: 0,
            acquiredAt: Date()
        )
        
        withAnimation {
            myGarage.insert(newCard, at: 0)
        }
        saveGarage()
        syncStateToCloud()
    }
    
    // Simulate real-time yield drop
    func simulateLiveYieldDrop(driverId: String, amount: Int) {
        if let index = myGarage.firstIndex(where: { $0.template.id == driverId }) {
            let finalAmount = Int(Double(amount) * myGarage[index].tier.multiplier)
            
            withAnimation {
                myGarage[index].totalYieldNxt += finalAmount
                coins += finalAmount
            }
            saveCoins()
            saveGarage()
            print("🎉 Yield Drop: +\(finalAmount) Nxt for \(myGarage[index].template.driverName)")
        }
    }
    
    // MARK: - Cloud Sync
    
    func clearState() {
        coins = 2000
        userPicks.removeAll()
        weeklyDraftPicks = [nil, nil, nil]
        myGarage.removeAll()
        draftLocked = false
        
        UserDefaults.standard.removeObject(forKey: coinsKey)
        UserDefaults.standard.removeObject(forKey: picksKey)
        UserDefaults.standard.removeObject(forKey: garageKey)
    }
    
    func fetchStateFromCloud() async {
        await fetchMarketCards()
        
        do {
            let session = try await Amplify.Auth.fetchAuthSession()
            guard let tokens = try (session as? AuthCognitoTokensProvider)?.getCognitoTokens().get() else { return }
            
            var request = URLRequest(url: URL(string: profileAPI)!)
            request.httpMethod = "GET"
            request.addValue("Bearer \(tokens.accessToken)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    await MainActor.run {
                        if let fetchedCoins = json["coins"] as? Int {
                            self.coins = fetchedCoins
                            self.saveCoins()
                        }
                        
                        if let draftStrings = json["draftPicks"] as? [String] {
                            for (i, driverName) in draftStrings.enumerated() {
                                if i < 3 {
                                    if driverName.isEmpty {
                                        self.weeklyDraftPicks[i] = nil
                                    } else {
                                        if let matchedDriver = self.availableCards.first(where: { $0.driverName == driverName }) {
                                            self.weeklyDraftPicks[i] = matchedDriver
                                        }
                                    }
                                }
                            }
                            // Lock draft if they have exactly 3 picks
                            let validPicksCount = self.weeklyDraftPicks.compactMap { $0 }.count
                            self.draftLocked = (validPicksCount == 3)
                        }
                        
                        if let garageIds = json["garage"] as? [String] {
                            self.myGarage.removeAll()
                            for gId in garageIds {
                                if let matchedTemplate = self.availableCards.first(where: { $0.id == gId }) {
                                    let newCard = UserDriverCard(
                                        id: UUID(),
                                        template: matchedTemplate,
                                        tier: .common,
                                        totalYieldNxt: 0,
                                        acquiredAt: Date()
                                    )
                                    self.myGarage.append(newCard)
                                }
                            }
                            self.saveGarage()
                        }
                        
                        // Mark as successfully fetched so syncStateToCloud is now safe to run
                        self.hasSuccessfullyFetchedCloudState = true
                    }
                    print("☁️ Fetched Fantasy State from Cloud")
                }
            } else {
                print("❌ Failed to fetch Fantasy State from Cloud")
            }
        } catch {
            print("❌ Network Error fetching state: \(error)")
        }
    }
    
    // Completely replaces local state persistence with cloud sync
    private func syncStateToCloud() {
        guard hasSuccessfullyFetchedCloudState else {
            print("⚠️ Skipped cloud sync to prevent overwriting cloud state with uninitialized local data.")
            return
        }
        
        Task {
            do {
                let session = try await Amplify.Auth.fetchAuthSession()
                guard let tokens = try (session as? AuthCognitoTokensProvider)?.getCognitoTokens().get() else { return }
                
                var request = URLRequest(url: URL(string: profileAPI)!)
                request.httpMethod = "POST"
                request.addValue("Bearer \(tokens.accessToken)", forHTTPHeaderField: "Authorization")
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let draftStrings = weeklyDraftPicks.map { $0?.driverName ?? "" }
                let garageIds = myGarage.map { $0.template.id }
                
                let body: [String: Any] = [
                    "coins": coins,
                    "draftPicks": draftStrings,
                    "garage": garageIds
                ]
                
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                let (_, response) = try await URLSession.shared.data(for: request)
                
                if let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200 {
                    print("☁️ Fantasy State Synced Successfully")
                } else {
                    print("❌ Failed to sync Fantasy State")
                }
            } catch {
                print("❌ Failed to sync state to cloud: \(error)")
                self.isSyncing = false
            }
        }
    }
    
    // MARK: - Dev Mode Actions
    func setDevBalance(_ amount: Int) {
        coins = amount
        saveCoins()
        syncStateToCloud()
        HapticManager.shared.trigger(.heavy)
    }
    
    func resetDailyBonus() {
        UserDefaults.standard.removeObject(forKey: lastDailyCheckInKey)
        UserDefaults.standard.removeObject(forKey: streakKey)
        dailyStreak = 1
        currentDailyReward = 50
        withAnimation {
            showDailyBonusClaim = true
        }
    }
    
    // Explicit action to lock in the draft via UI
    func lockInDraft() async {
        guard !draftLocked else { return }
        
        await MainActor.run {
            self.isSyncing = true
        }
        
        do {
            let session = try await Amplify.Auth.fetchAuthSession()
            guard let tokens = try (session as? AuthCognitoTokensProvider)?.getCognitoTokens().get() else {
                await MainActor.run { self.isSyncing = false }
                return
            }
            
            var request = URLRequest(url: URL(string: profileAPI)!)
            request.httpMethod = "POST"
            request.addValue("Bearer \(tokens.accessToken)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let draftStrings = weeklyDraftPicks.map { $0?.driverName ?? "" }
            let garageIds = myGarage.map { $0.template.id }
            
            let body: [String: Any] = [
                "coins": coins,
                "draftPicks": draftStrings,
                "garage": garageIds
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (_, response) = try await URLSession.shared.data(for: request)
            
            await MainActor.run {
                self.isSyncing = false
                if let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200 {
                    self.draftLocked = true
                    HapticManager.shared.trigger(.medium)
                    print("🔒 Draft successfully locked in on AWS!")
                } else {
                    HapticManager.shared.trigger(.heavy)
                    print("❌ Failed to lock draft on server.")
                }
            }
        } catch {
            await MainActor.run {
                self.isSyncing = false
                HapticManager.shared.trigger(.heavy)
            }
            print("❌ Network error locking draft: \(error)")
        }
    }
    
    // Explicit action to unlock draft by paying fee
    func unlockDraft(fee: Int) {
        guard draftLocked else { return }
        guard coins >= fee else {
            print("❌ Insufficient Nxt to unlock draft")
            return
        }
        
        coins -= fee
        saveCoins()
        // Wiping picks ensures draft stays unlocked across restarts
        weeklyDraftPicks = [nil, nil, nil]
        draftLocked = false
        HapticManager.shared.trigger(.medium)
        syncStateToCloud() // Save unlocked state and new balance to cloud immediately
    }
}
