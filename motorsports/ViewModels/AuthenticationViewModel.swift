import Foundation
import SwiftUI
import Combine
import Amplify

class AuthenticationViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var userId: String? = nil
    
    // Call this on launch to see if they are already logged in
    func checkSession() async {
        do {
            let session = try await Amplify.Auth.fetchAuthSession()
            if session.isSignedIn {
                let user = try await Amplify.Auth.getCurrentUser()
                await MainActor.run {
                    self.userId = user.userId
                    self.isAuthenticated = true
                }
            }
        } catch {
            print("❌ Fetch auth session failed with error - \(error)")
        }
    }
    
    func signInWithApple() {
        signInWithProvider(.apple)
    }
    

    private func signInWithProvider(_ provider: AuthProvider) {
        // Grab the active UIWindow from the application scene
        guard let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow }) else {
            print("❌ Failed to find active UIWindow")
            return
        }
        
        Task {
            await MainActor.run { self.isLoading = true }
            do {
                let result = try await Amplify.Auth.signInWithWebUI(for: provider, presentationAnchor: window)
                if result.isSignedIn {
                    let user = try await Amplify.Auth.getCurrentUser()
                    await MainActor.run {
                        self.userId = user.userId
                        self.isAuthenticated = true
                        self.isLoading = false
                        HapticManager.shared.buttonPress()
                    }
                } else {
                    await MainActor.run { self.isLoading = false }
                }
            } catch {
                print("❌ Sign in failed: \(error)")
                await MainActor.run { self.isLoading = false }
            }
        }
    }
    
    func signOut() {
        Task {
            let _ = await Amplify.Auth.signOut()
            await MainActor.run {
                self.isAuthenticated = false
                self.userId = nil
            }
        }
    }
}
