//
//  DailyBonusClaimView.swift
//  motorsports
//
//  Created for NxtLAP.
//

import SwiftUI

struct DailyBonusClaimView: View {
    @EnvironmentObject var fantasyVM: FantasyViewModel
    @State private var animateGlow: Bool = false
    @State private var animateIcon: Bool = false
    
    var body: some View {
        ZStack {
            // Dark blurred background
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .background(Material.ultraThinMaterial)
            
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 4) {
                    Text("Daily Check-in")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Day \(fantasyVM.dailyStreak) Streak 🔥")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(12)
                }
                
                // Glowing Icon
                ZStack {
                    Circle()
                        .fill(Color.cyan.opacity(0.2))
                        .frame(width: 140, height: 140)
                        .blur(radius: animateGlow ? 30 : 10)
                        .scaleEffect(animateGlow ? 1.2 : 1.0)
                    
                    Image(systemName: fantasyVM.dailyStreak == 7 ? "gift.fill" : "n.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(fantasyVM.dailyStreak == 7 ? .yellow : .cyan)
                        .shadow(color: fantasyVM.dailyStreak == 7 ? .yellow : .cyan, radius: 10)
                        .scaleEffect(animateIcon ? 1.1 : 1.0)
                }
                .padding(.vertical, 10)
                
                // Reward Text
                VStack(spacing: 8) {
                    Text("+\(fantasyVM.currentDailyReward) NXT")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundColor(fantasyVM.dailyStreak == 7 ? .yellow : .white)
                    
                    if fantasyVM.dailyStreak == 7 {
                        Text("Weekly perfect streak! Amazing racing!")
                            .font(.system(size: 16))
                            .foregroundColor(.yellow)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    } else if fantasyVM.dailyStreak == 2 {
                        Text("Keep it up! Hit 3 days for a 150 NXT bonus!")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    } else if fantasyVM.dailyStreak == 6 {
                        Text("One more day until your 500 NXT weekly reward!")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    } else {
                        Text("Thanks for racing with us today! Come back tomorrow for more.")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    // Mini Streak Visualizer
                    HStack(spacing: 8) {
                        ForEach(1...7, id: \.self) { day in
                            Circle()
                                .fill(day <= fantasyVM.dailyStreak ? Color.orange : Color.white.opacity(0.2))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.top, 12)
                }
                
                // Claim Button
                Button(action: {
                    HapticManager.shared.trigger(.heavy)
                    fantasyVM.claimDailyBonus()
                    
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        fantasyVM.showDailyBonusClaim = false
                    }
                }) {
                    Text("CLAIM REWARD")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [.cyan, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(25)
                        .shadow(color: .cyan.opacity(0.5), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color(white: 0.1).opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.5), radius: 30)
            )
            .padding(.horizontal, 20)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animateGlow = true
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animateIcon = true
            }
        }
    }
}
