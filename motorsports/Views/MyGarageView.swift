//
//  MyGarageView.swift
//  motorsports
//
//  Created for NxtLAP.
//

import SwiftUI

struct MyGarageView: View {
    @EnvironmentObject var fantasyVM: FantasyViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("My Garage")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            .padding(.top)
                        
                        // Stats Overview
                        HStack(spacing: 16) {
                            StatBox(title: "Total Cards", value: "\(fantasyVM.myGarage.count)", icon: "square.stack.3d.up.fill", color: .purple)
                            
                            let totalYield = fantasyVM.myGarage.reduce(0) { $0 + $1.totalYieldNxt }
                            StatBox(title: "Lifetime Yield", value: "\(totalYield)", icon: "chart.line.uptrend.xyaxis", color: .green)
                        }
                        .padding(.horizontal)
                        
                        // Active Draft Picks
                        if fantasyVM.draftLocked {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Active Weekly Draft")
                                    .font(.title3.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal)
                                    .padding(.top, 10)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(fantasyVM.weeklyDraftPicks.compactMap({ $0 }), id: \.id) { pick in
                                            DraftMiniCard(driver: pick)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        Text("Your Driver Portfolio")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            .padding(.top, 10)
                        
                        // Inventory List
                        VStack(spacing: 12) {
                            ForEach(fantasyVM.myGarage) { card in
                                InventoryCardRow(card: card)
                            }
                            
                            if fantasyVM.myGarage.isEmpty {
                                Text("Your garage is empty. Head to the market!")
                                    .foregroundColor(.gray)
                                    .padding(.top, 40)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.gray)
            }
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.systemGray6).opacity(0.15))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct InventoryCardRow: View {
    let card: UserDriverCard
    
    var body: some View {
        HStack(spacing: 16) {
            // Tier Badge/Icon
            ZStack {
                Circle()
                    .fill(Color(hex: card.tier.colorHex).opacity(0.12))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "person.fill")
                    .foregroundColor(Color(hex: card.tier.colorHex))
                    .font(.system(size: 18, weight: .bold))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(card.template.driverName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                HStack(spacing: 6) {
                    Text(card.tier.rawValue)
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: card.tier.colorHex).opacity(0.2))
                        .foregroundColor(Color(hex: card.tier.colorHex))
                        .cornerRadius(4)
                    
                    Text(card.template.series)
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.08))
                        .foregroundColor(.gray)
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            // Yield Stats
            VStack(alignment: .trailing, spacing: 4) {
                Text("YIELD")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.gray)
                    .tracking(0.5)
                
                HStack(spacing: 3) {
                    Image(systemName: "n.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.cyan)
                    Text("+\(card.totalYieldNxt)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.green)
                }
            }
        }
        .padding(14)
        .background(
            ZStack {
                Color(.systemGray6).opacity(0.15)
                
                // Subtle tier color glow in bottom-right corner of row
                GeometryReader { geo in
                    Circle()
                        .fill(Color(hex: card.tier.colorHex).opacity(0.08))
                        .frame(width: 80, height: 80)
                        .blur(radius: 20)
                        .position(x: geo.size.width - 10, y: geo.size.height - 10)
                }
            }
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: card.tier.colorHex).opacity(0.2), lineWidth: 1)
        )
    }
}

struct DraftMiniCard: View {
    let driver: DriverCardTemplate
    
    var body: some View {
        VStack(spacing: 8) {
            if let urlString = driver.cutoutUrl ?? driver.imageUrl, let url = URL(string: urlString) {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 50, height: 50)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    )
            }
            
            Text(driver.driverName)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .frame(width: 90, height: 110)
        .background(Color(.systemGray6).opacity(0.3))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.cyan.opacity(0.4), lineWidth: 1)
        )
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    MyGarageView()
}
