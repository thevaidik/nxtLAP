import Foundation
import StoreKit

@MainActor
class StoreManager: ObservableObject {
    @Published var isPro: Bool = false
    @Published var purchasedProductIDs = Set<String>()
    
    private let productIDs = ["com.nxtlap.pro.monthly"]
    private var updatesTask: Task<Void, Never>? = nil
    
    init() {
        updatesTask = listenForTransactions()
    }
    
    deinit {
        updatesTask?.cancel()
    }
    
    /// Listens for StoreKit transactions (renewals, outside purchases, etc.)
    private func listenForTransactions() -> Task<Void, Never> {
        return Task.detached {
            // Iterate through any transactions that don't come from a direct call to `purchase()`.
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updateEntitlements()
                    await transaction.finish()
                } catch {
                    // Transaction failed verification
                    print("Transaction failed verification: \(error)")
                }
            }
        }
    }
    
    /// Checks the user's current entitlements (active subscriptions/purchases)
    func updateEntitlements() async {
        var activeIDs = Set<String>()
        var hasPro = false
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try await checkVerified(result)
                
                // If the transaction is a subscription, we check if it is active
                if transaction.productType == .autoRenewable || transaction.productType == .nonRenewable {
                    // StoreKit 2 automatically handles filtering out expired subscriptions in `currentEntitlements`
                    activeIDs.insert(transaction.productID)
                    if transaction.productID == "com.nxtlap.pro.monthly" {
                        hasPro = true
                    }
                }
            } catch {
                print("Failed to verify entitlement: \(error)")
            }
        }
        
        self.purchasedProductIDs = activeIDs
        self.isPro = hasPro
    }
    
    /// Verifies the JWS from StoreKit
    private func checkVerified<T>(_ result: VerificationResult<T>) async throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
}
