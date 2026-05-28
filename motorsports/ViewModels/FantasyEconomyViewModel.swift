//
//  FantasyEconomyViewModel.swift
//  motorsports
//
//  Created for NxtLAP.
//

import Foundation
import SwiftUI

class FantasyEconomyViewModel: ObservableObject {
    @Published var nxtBalance: Int = 10000
    @Published var karmaBalance: Int = 500
    @Published var myGarage: [UserDriverCard] = FantasyMockData.mockInventory
    @Published var availableCards: [DriverCardTemplate] = FantasyMockData.driverTemplates
    
    // Fetch live market cards from the new Fantasy Server
    @MainActor
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
            
            // Filter out missing cutout cases for a premium experience or provide fallbacks
            self.availableCards = cards
        } catch {
            print("Failed to fetch fantasy cards from server: \(error)")
        }
    }
    
    // Purchase a card from the market
    func purchaseCard(template: DriverCardTemplate) {
        guard nxtBalance >= template.basePriceNxt else {
            // In a real app, handle insufficient funds
            print("Insufficient Nxt")
            return
        }
        
        // Deduct balance
        nxtBalance -= template.basePriceNxt
        
        // Add to garage
        let newCard = UserDriverCard(
            id: UUID(),
            template: template,
            tier: .common, // Starts at common
            totalYieldNxt: 0,
            acquiredAt: Date()
        )
        
        // Add with animation
        withAnimation {
            myGarage.insert(newCard, at: 0)
        }
    }
    
    // Simulate real-time yield drop (e.g. via Websocket in the future)
    func simulateLiveYieldDrop(driverId: String, amount: Int) {
        if let index = myGarage.firstIndex(where: { $0.template.id == driverId }) {
            let finalAmount = Int(Double(amount) * myGarage[index].tier.multiplier)
            
            withAnimation {
                myGarage[index].totalYieldNxt += finalAmount
                nxtBalance += finalAmount
            }
            print("🎉 Yield Drop: +\(finalAmount) Nxt for \(myGarage[index].template.driverName)")
        }
    }
}
