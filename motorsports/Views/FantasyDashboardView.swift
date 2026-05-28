//
//  FantasyDashboardView.swift
//  motorsports
//
//  Created for NxtLAP.
//

import SwiftUI

struct FantasyDashboardView: View {
    enum FantasyTab: String, CaseIterable {
        case market = "Card Market"
        case garage = "My Garage"
    }
    
    @State private var selectedTab: FantasyTab = .market
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented picker
                CustomSegmentedControl(selection: $selectedTab, options: FantasyTab.allCases)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                
                // Content
                TabView(selection: $selectedTab) {
                    CardMarketView()
                        .tag(FantasyTab.market)
                    
                    MyGarageView()
                        .tag(FantasyTab.garage)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Fantasy")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.black.ignoresSafeArea())
        }
    }
}

#Preview {
    FantasyDashboardView()
}
