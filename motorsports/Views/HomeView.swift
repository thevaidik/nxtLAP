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
                            
                            // Fantasy Predictor
                            WeeklyDraftView()
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
    }
}

#Preview {
    @Previewable @State var selectedTab: MainTabView.Tab = .home
    HomeView(selectedTab: $selectedTab)
        .environmentObject(RacingDataService())
        .environmentObject(LivestreamViewModel())
        .environmentObject(FantasyViewModel())
}
