import SwiftUI

struct SidebarProfileView: View {
    @Binding var isShowing: Bool
    @EnvironmentObject var userVM: UserViewModel
    @EnvironmentObject var fantasyVM: FantasyViewModel
    @EnvironmentObject var authVM: AuthenticationViewModel
    @EnvironmentObject var storeManager: StoreManager
    
    @State private var showPaywall = false
    
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
                    
                    HStack(spacing: 6) {
                        if storeManager.isPro {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.yellow)
                            Text("PRO MEMBER")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.yellow)
                        } else {
                            Text("NxtLAP Member")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
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
                    Text("\(fantasyVM.coins.nxtFormatted)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.green)
                }
                .padding(.vertical, 8)
            }
            
            Spacer()
            
            if !storeManager.isPro {
                Button(action: {
                    showPaywall = true
                }) {
                    HStack {
                        Image(systemName: "crown.fill")
                        Text("Get NxtLAP Pro")
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .cornerRadius(12)
                }
                .padding(.bottom, 12)
            }
            
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
        .sheet(isPresented: $showPaywall) {
            if #available(iOS 17.0, *) {
                PaywallView()
            }
        }
    }
}
