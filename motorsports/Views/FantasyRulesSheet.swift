import SwiftUI

struct FantasyRulesSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Welcome
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome to NxtLAP Fantasy")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Draft drivers every week and earn NXT based on their real-world performance.")
                            .foregroundColor(.gray)
                    }
                    
                    // Rule 1
                    RuleBlockView(
                        icon: "flag.checkered",
                        title: "1. The Weekly Draft",
                        description: "Pick 3 drivers to form your weekly team. You can draft drivers from any supported series racing this week. Once a specific race starts, those drivers are locked and can no longer be drafted."
                    )
                    
                    // Rule 2
                    RuleBlockView(
                        icon: "trophy.fill",
                        title: "2. The 10,000 NXT Jackpot",
                        description: "To hit the 10,000 NXT Jackpot, your 3 drafted drivers must finish on the podium in the EXACT order you picked them:\n\n• Slot 1 must finish 1st\n• Slot 2 must finish 2nd\n• Slot 3 must finish 3rd"
                    )
                    
                    // Rule 3
                    RuleBlockView(
                        icon: "medal.fill",
                        title: "3. General Win Payouts",
                        description: "If you don't hit the Jackpot, you can still earn massive payouts based on your drivers' finishes:\n\n• All 3 drivers in the Top 10 (with at least 1 on the podium): +1,000 NXT\n• Drivers who land on the podium: +200 NXT per podium finish."
                    )
                    
                    // Rule 4
                    RuleBlockView(
                        icon: "creditcard.fill",
                        title: "4. Card Market & Garage",
                        description: "Use your NXT to buy Driver Cards from the Card Market. Cards in your Garage generate passive NXT yield automatically every time that driver races, based on the card's rarity tier!"
                    )
                }
                .padding(20)
            }
            .navigationTitle("Fantasy Rules")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct RuleBlockView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.cyan)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineSpacing(4)
            }
        }
        .padding(16)
        .background(Color(white: 0.1))
        .cornerRadius(12)
    }
}

#Preview {
    FantasyRulesSheet()
}
