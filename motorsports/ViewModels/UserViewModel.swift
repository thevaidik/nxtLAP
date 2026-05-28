import SwiftUI
import Amplify
import AWSPluginsCore

@MainActor
class UserViewModel: ObservableObject {
    @Published var username: String? = nil
    @Published var isNewUser: Bool = false
    @Published var isCheckingUsername: Bool = false
    @Published var usernameError: String? = nil
    
    private let profileAPI = "https://gkyghno7i3smn3ts4t7d534s6e0lhdme.lambda-url.us-east-1.on.aws/"
    
    // Fetch profile from AWS Backend
    func fetchProfile() async {
        do {
            let session = try await Amplify.Auth.fetchAuthSession()
            guard let tokens = try (session as? AuthCognitoTokensProvider)?.getCognitoTokens().get() else {
                print("❌ Failed to retrieve tokens")
                return
            }
            
            // Pass the Access Token securely to our Lambda
            var request = URLRequest(url: URL(string: profileAPI)!)
            request.httpMethod = "GET"
            request.addValue("Bearer \(tokens.accessToken)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    self.username = json?["username"] as? String
                    self.isNewUser = (self.username == nil || self.username == "")
                    
                    // Update FantasyVM State immediately
                    if let coins = json?["coins"] as? Int {
                        UserDefaults.standard.set(coins, forKey: "nxtlap_fantasy_coins")
                    }
                    
                    print("✅ User Profile Loaded: \(self.username ?? "New User")")
                } else if httpResponse.statusCode == 404 {
                    // New user! Needs onboarding
                    self.isNewUser = true
                } else {
                    print("❌ Profile Fetch Error: HTTP \(httpResponse.statusCode)")
                }
            }
        } catch {
            print("❌ Network Error fetching profile: \(error)")
        }
    }
    
    // Attempt to claim a username
    func claimUsername(_ desiredUsername: String) async -> Bool {
        self.isCheckingUsername = true
        self.usernameError = nil
        
        do {
            let session = try await Amplify.Auth.fetchAuthSession()
            guard let tokens = try (session as? AuthCognitoTokensProvider)?.getCognitoTokens().get() else {
                self.isCheckingUsername = false
                return false
            }
            
            let cleanUsername = desiredUsername.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            
            var request = URLRequest(url: URL(string: profileAPI)!)
            request.httpMethod = "POST"
            request.addValue("Bearer \(tokens.accessToken)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = ["username": cleanUsername]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    self.username = cleanUsername
                    self.isNewUser = false
                    self.isCheckingUsername = false
                    return true
                } else if httpResponse.statusCode == 400 {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    self.usernameError = (json?["error"] as? String) ?? "Username is already taken"
                } else {
                    self.usernameError = "Server Error: \(httpResponse.statusCode)"
                }
            }
        } catch {
            self.usernameError = "Network Error: \(error.localizedDescription)"
        }
        
        self.isCheckingUsername = false
        return false
    }
}
