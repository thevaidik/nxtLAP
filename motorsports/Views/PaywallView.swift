import SwiftUI
import StoreKit

@available(iOS 17.0, *)
struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        SubscriptionStoreView(groupID: "755CD2B5") {
            // Header content
            VStack(spacing: 20) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.linearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                
                Text("NxtLAP Pro")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                
                Text("Support development and unlock exclusive Pro features.")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(icon: "checkmark.seal.fill", text: "Pro Badge on Profile")
                    FeatureRow(icon: "star.fill", text: "Support Independent Development")
                    FeatureRow(icon: "chart.bar.fill", text: "More features coming soon")
                }
                .padding(.top, 20)
                
                Spacer()
            }
            .padding(.top, 40)
        }
        .subscriptionStoreButtonLabel(.multiline)
        .subscriptionStorePickerItemBackground(.thinMaterial)
        .storeButton(.visible, for: .restorePurchases)
        .storeButton(.visible, for: .policies)
        .background(Color.black.ignoresSafeArea())
        .onInAppPurchaseCompletion { product, result in
            if case .success(let purchaseResult) = result {
                if case .success(let verificationResult) = purchaseResult {
                    switch verificationResult {
                    case .verified(let transaction):
                        print("Purchased successfully: \(transaction.productID)")
                        dismiss()
                    case .unverified(_, let error):
                        print("Transaction unverified: \(error)")
                    }
                }
            }
        }
    }
}

@available(iOS 17.0, *)
struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.yellow)
                .font(.title2)
            Text(text)
                .foregroundColor(.white)
                .font(.body)
        }
    }
}
