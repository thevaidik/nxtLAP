import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authVM: AuthenticationViewModel
    
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            // Neon Cyan ambient glow
            Circle()
                .fill(Color.cyan.opacity(0.15))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(y: -200)
            
            VStack(spacing: 30) {
                Spacer()
                
                // Logo & Title
                VStack(spacing: 12) {
                    Image(systemName: "flag.checkered.2.crossed")
                        .font(.system(size: 60))
                        .foregroundColor(.cyan)
                    
                    Text("NxtLAP Fantasy")
                        .font(.system(size: 32, weight: .bold, design: .default))
                        .foregroundColor(.white)
                    
                    Text("Sign in to build your garage, trade drivers, and earn Nxt.")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Auth Buttons
                VStack(spacing: 16) {
                    if authVM.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .cyan))
                            .padding()
                    } else {
                        // Sign in with Apple Button
                        Button(action: {
                            authVM.signInWithApple()
                        }) {
                            HStack {
                                Image(systemName: "applelogo")
                                    .font(.title2)
                                Text("Sign in with Apple")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(12)
                        }

                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
            }
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthenticationViewModel())
}
