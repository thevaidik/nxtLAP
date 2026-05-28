//
//  CardMarketView.swift
//  motorsports
//
//  Created for NxtLAP.
//

import SwiftUI

struct CardMarketView: View {
    @StateObject var economyVM = FantasyEconomyViewModel()
    
    // Columns for grid
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header / Wallet
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Card Market")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Invest in drivers to earn Nxt")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            
                            // Wallet Balance
                            HStack(spacing: 4) {
                                Image(systemName: "n.circle.fill")
                                    .foregroundColor(.cyan)
                                Text("\(economyVM.nxtBalance)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
                        // Market Grid Grouped by Series
                        VStack(spacing: 30) {
                            ForEach(groupedCards, id: \.0) { seriesName, templates in
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("\(seriesName) Drivers")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 16) {
                                            ForEach(templates) { template in
                                                MarketCardView(template: template) {
                                                    economyVM.purchaseCard(template: template)
                                                }
                                                .frame(width: 160) // Fixed width for horizontal scrolling
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .task {
            await economyVM.fetchMarketCards()
        }
    }
    
    // Group cards by series and sort them so F1 appears first
    var groupedCards: [(String, [DriverCardTemplate])] {
        let dict = Dictionary(grouping: economyVM.availableCards, by: { $0.series })
        let sortedSeries = dict.keys.sorted { (s1, s2) in
            if s1 == "F1" { return true }
            if s2 == "F1" { return false }
            return s1 < s2
        }
        return sortedSeries.map { ($0, dict[$0]!) }
    }
}

struct MarketCardView: View {
    let template: DriverCardTemplate
    let onBuy: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Card Image Area
            ZStack {
                LinearGradient(
                    colors: [Color.white.opacity(0.02), Color.white.opacity(0.08)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                if let urlString = template.cutoutUrl ?? template.imageUrl, let url = URL(string: urlString) {
                    CachedAsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                    .padding(8)
                } else {
                    Image(systemName: "person.crop.rectangle.fill")
                        .resizable()
                        .scaledToFit()
                        .padding(20)
                        .foregroundColor(.gray)
                }
                
                // Series Badge
                VStack {
                    HStack {
                        Text(template.series)
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.racingRed)
                            .cornerRadius(4)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    Spacer()
                }
                .padding(8)
            }
            .frame(height: 140)
            
            // Card Info
            VStack(alignment: .leading, spacing: 6) {
                Text(template.driverName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(template.team)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                Button(action: onBuy) {
                    HStack(spacing: 4) {
                        Image(systemName: "n.circle.fill")
                            .font(.system(size: 13, weight: .bold))
                        Text("\(template.basePriceNxt)")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [.green, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                }
                .padding(.top, 4)
            }
            .padding(12)
        }
        .background(
            ZStack {
                Color(.systemGray6).opacity(0.15)
                
                // Subtle green corner glow in bottom-right (from md file spec)
                GeometryReader { geo in
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 100, height: 100)
                        .blur(radius: 40)
                        .position(x: geo.size.width - 20, y: geo.size.height - 20)
                }
            }
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    CardMarketView()
}
