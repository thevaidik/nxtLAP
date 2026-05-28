import SwiftUI

struct UserOnboardingView: View {
    @EnvironmentObject var userVM: UserViewModel
    @State private var desiredUsername: String = ""
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            // Background glow
            Circle()
                .fill(Color.cyan.opacity(0.15))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(y: -200)
                
            VStack(spacing: 30) {
                Spacer()
                
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.cyan)
                    
                    Text("Choose your Username")
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .foregroundColor(.white)
                    
                    Text("This is how other racers will see you on the leaderboards.")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                VStack(spacing: 8) {
                    HStack {
                        Text("@")
                            .foregroundColor(.gray)
                            .font(.title2)
                        TextField("username", text: $desiredUsername)
                            .font(.title2)
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(userVM.usernameError != nil ? Color.red : Color.white.opacity(0.2), lineWidth: 1)
                    )
                    
                    if let error = userVM.usernameError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 8)
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                Button(action: {
                    Task {
                        await userVM.claimUsername(desiredUsername)
                    }
                }) {
                    HStack {
                        if userVM.isCheckingUsername {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        } else {
                            Text("Claim Username")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(desiredUsername.count > 2 ? Color.cyan : Color.gray)
                    .foregroundColor(.black)
                    .cornerRadius(12)
                }
                .disabled(desiredUsername.count <= 2 || userVM.isCheckingUsername)
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
            }
        }
        .interactiveDismissDisabled(true) // Force them to pick a username
    }
}

#Preview {
    UserOnboardingView()
        .environmentObject(UserViewModel())
}
