import Foundation
import SwiftUI
import Combine

class AuthenticationViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var userId: String? = nil
    
    // In the future, we will link AWS Amplify here.
    
    func signInWithApple() {
        self.isLoading = true
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.userId = "USER#apple_dummy_123"
            self.isAuthenticated = true
            self.isLoading = false
            HapticManager.shared.buttonPress()
        }
    }
    
    func signInWithGoogle() {
        self.isLoading = true
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.userId = "USER#google_dummy_123"
            self.isAuthenticated = true
            self.isLoading = false
            HapticManager.shared.buttonPress()
        }
    }
    
    func signOut() {
        self.isAuthenticated = false
        self.userId = nil
    }
}
