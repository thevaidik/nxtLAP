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
    @State private var showAvailabilitySheet = false
    @EnvironmentObject var authVM: AuthenticationViewModel
    
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
            .overlay(alignment: .bottom) {
                if !authVM.isAuthenticated {
                    AuthenticationView()
                        .frame(height: 380)
                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                        .shadow(color: .black.opacity(0.6), radius: 20, x: 0, y: -10)
                        .transition(.move(edge: .bottom))
                        .ignoresSafeArea(.all, edges: .bottom)
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: authVM.isAuthenticated)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAvailabilitySheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Text("Supported Series")
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                    }
                }
            }
            .sheet(isPresented: $showAvailabilitySheet) {
                FantasyAvailabilityView()
            }
        }
    }
}

#Preview {
    FantasyDashboardView()
}
