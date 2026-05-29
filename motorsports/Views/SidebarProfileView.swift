import SwiftUI

struct SidebarProfileView: View {
    @Binding var isShowing: Bool
    @EnvironmentObject var userVM: UserViewModel
    @EnvironmentObject var fantasyVM: FantasyViewModel
    @EnvironmentObject var authVM: AuthenticationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(userVM.username ?? "Racer")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("NxtLAP Member")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: {
                    isShowing = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                }
            }
            .padding(.top, 24)
            
            Divider().background(Color.white.opacity(0.2))
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Wallet")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray)
                
                HStack {
                    Text("NXT Balance")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(fantasyVM.coins)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.green)
                }
                .padding(.vertical, 8)
            }
            
            Spacer()
            
            Button(action: {
                authVM.signOut()
            }) {
                HStack {
                    Spacer()
                    Text("Sign Out")
                        .font(.system(size: 16, weight: .bold))
                    Spacer()
                }
                .padding()
                .background(Color.red.opacity(0.15))
                .foregroundColor(.red)
                .cornerRadius(12)
            }
            .padding(.bottom, 30)
        }
        .padding(.horizontal, 24)
        .background(Color(.systemGray6))
    }
}
