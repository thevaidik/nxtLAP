//
//  PayoutHistoryView.swift
//  motorsports
//
//  Created for NxtLAP.
//

import SwiftUI

struct PayoutHistoryView: View {
    @EnvironmentObject var fantasyViewModel: FantasyViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                if fantasyViewModel.payoutHistory.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No Payout History Yet")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Your daily race yields will appear here.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(fantasyViewModel.payoutHistory) { payout in
                                PayoutHistoryCard(payout: payout)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Payout History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.title3)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct PayoutHistoryCard: View {
    let payout: PayoutHistory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(formatDate(payout.date))
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("+\(payout.totalYield.nxtFormatted) NXT")
                    .font(.title3)
                    .bold()
                    .foregroundColor(payout.totalYield > 0 ? Color(hex: "00FF66") : .gray)
            }
            
            Divider().background(Color.gray.opacity(0.3))
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DRAFT YIELD")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .bold()
                    Text("+\(payout.draftYield.nxtFormatted)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("GARAGE YIELD")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .bold()
                    Text("+\(payout.garageYield.nxtFormatted)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "1C1C1E"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateString) {
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
        return dateString
    }
}
