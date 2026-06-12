//
//  HomeView.swift
//  motorsports
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var dataService: RacingDataService
    @EnvironmentObject var livestreamViewModel: LivestreamViewModel
    @Binding var selectedTab: MainTabView.Tab
    @EnvironmentObject var newsViewModel: NewsViewModel
    @EnvironmentObject var authVM: AuthenticationViewModel
    @EnvironmentObject var userVM: UserViewModel
    
    @State private var isSidebarShowing: Bool = false
    @State private var isShowingAuthSheet: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                HStack {
                    Spacer(minLength: 0)
                    VStack(spacing: 0) {
                        // Header Section with Stories
                        VStack(spacing: 0) {
                            HStack {
                                Text("NxtLAP")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(dataService.isDevMode ? .green : .white)
                                    .onTapGesture(count: 6) {
                                        dataService.toggleDevMode()
                                    }
                                
                                Spacer()
                                
                                if authVM.isAuthenticated {
                                    Button(action: {
                                        isSidebarShowing = true
                                    }) {
                                        Text("@\(userVM.username ?? "Racer")")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.white.opacity(0.1))
                                            .cornerRadius(16)
                                    }
                                } else {
                                    Button(action: {
                                        isShowingAuthSheet = true
                                    }) {
                                        Text("Sign In")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color.green)
                                            .cornerRadius(20)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            // News Stories - Instagram style
                            NewsStoriesView(newsViewModel: newsViewModel)
                                .padding(.top, 16)
                                .padding(.bottom, 8)
                            
                            // Watch Now Carousel - suggests from Watch tab
                            WatchNowCarouselView()
                                .padding(.top, 8)
                                .padding(.bottom, 16)
                            
                            // Upcoming Races List
                            UpcomingRacesCarouselView()
                                .padding(.top, 8)
                                .padding(.bottom, 32)
                        }
                    }
                    .frame(maxWidth: 800)
                    Spacer(minLength: 0)
                }
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color(.systemGray6).opacity(0.1),
                        Color.black
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
        .task {
            async let fetchN: () = {
                if newsViewModel.articles.isEmpty {
                    await newsViewModel.fetchNews()
                }
            }()
            
            async let fetchL: () = {
                if livestreamViewModel.streams.isEmpty {
                    await livestreamViewModel.fetchLivestreams()
                }
            }()
            
            _ = await (fetchN, fetchL)
        }
        .sheet(isPresented: $isSidebarShowing) {
            SidebarProfileView(isShowing: $isSidebarShowing)
                .presentationDetents([.height(350), .medium])
                .presentationCornerRadius(24)
        }
        .sheet(isPresented: $isShowingAuthSheet) {
            AuthenticationView()
        }
        .onChange(of: authVM.isAuthenticated) {
            if authVM.isAuthenticated {
                isShowingAuthSheet = false // dismiss auth sheet if successful
            } else {
                isSidebarShowing = false // dismiss profile sheet on sign out immediately
                userVM.username = nil // Reset username state safely
            }
        }
    }
}

#Preview {
    @Previewable @State var selectedTab: MainTabView.Tab = .home
    HomeView(selectedTab: $selectedTab)
        .environmentObject(RacingDataService())
        .environmentObject(LivestreamViewModel())
        .environmentObject(FantasyViewModel())
}
