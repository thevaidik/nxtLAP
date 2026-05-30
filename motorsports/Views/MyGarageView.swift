//
//  MyGarageView.swift
//  motorsports
//
//  Created for NxtLAP.
//

import SwiftUI

struct MyGarageView: View {
    @EnvironmentObject var fantasyVM: FantasyViewModel
    @State private var showPayoutHistory = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("My Garage")
                                .font(.largeTitle.bold())
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button(action: {
                                showPayoutHistory = true
                            }) {
                                Image(systemName: "list.clipboard")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                                    .padding(8)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
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
                        let columns = [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ]
                        
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(fantasyVM.myGarage) { card in
                                GarageCardView(card: card)
                            }
                        }
                        .padding(.horizontal)
                        
                        if fantasyVM.myGarage.isEmpty {
                            Text("Your garage is empty. Head to the market!")
                                .foregroundColor(.gray)
                                .padding(.top, 40)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showPayoutHistory) {
            PayoutHistoryView()
                .environmentObject(fantasyVM)
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

struct GarageCardView: View {
    let card: UserDriverCard
    
    var body: some View {
        VStack(spacing: 0) {
            // Card Image Area
            ZStack {
                LinearGradient(
                    colors: [Color(hex: card.tier.colorHex).opacity(0.1), Color.white.opacity(0.02)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                if let urlString = card.template.cutoutUrl ?? card.template.imageUrl, let url = URL(string: urlString) {
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
                        .foregroundColor(Color(hex: card.tier.colorHex))
                }
                
                // Tier Badge
                VStack {
                    HStack {
                        Text(card.tier.rawValue.uppercased())
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color(hex: card.tier.colorHex))
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
                Text(card.template.driverName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(card.template.team)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                // Yield Display
                HStack(spacing: 4) {
                    Text("TOTAL YIELD:")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.gray)
                    Spacer()
                    Image(systemName: "n.circle.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text("+\(card.totalYieldNxt.nxtFormatted)")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.green)
                .padding(.vertical, 8)
                .padding(.horizontal, 8)
                .background(Color.green.opacity(0.15))
                .cornerRadius(8)
                .padding(.top, 4)
            }
            .padding(12)
        }
        .background(
            ZStack {
                Color(.systemGray6).opacity(0.15)
                
                GeometryReader { geo in
                    Circle()
                        .fill(Color(hex: card.tier.colorHex).opacity(0.15))
                        .frame(width: 80, height: 80)
                        .blur(radius: 30)
                        .position(x: geo.size.width - 20, y: geo.size.height - 20)
                }
            }
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(hex: card.tier.colorHex).opacity(0.3), lineWidth: 1)
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
