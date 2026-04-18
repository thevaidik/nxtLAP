//
//  WatchView.swift
//  motorsports
//
//  Created by Antigravity on 10/04/26.
//

import SwiftUI

struct WatchView: View {
    @EnvironmentObject var viewModel: LivestreamViewModel
    @State private var selectedTab: WatchTab = .upcoming
    
    enum WatchTab: String, CaseIterable {
        case upcoming = "Upcoming"
        case past = "Past"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background Gradient
                LinearGradient(
                    colors: [Color.black, Color(white: 0.06)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Picker("Watch", selection: $selectedTab) {
                        ForEach(WatchTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.8))
                
                    if viewModel.isLoading && viewModel.streams.isEmpty {
                        Spacer()
                        ProgressView()
                            .tint(.nxtlapRacingRed)
                        Spacer()
                    } else if let error = viewModel.errorMessage {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.nxtlapRacingRed)
                            Text("Unable to load streams")
                                .font(.headline)
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                            Button("Retry") {
                                Task {
                                    await viewModel.fetchLivestreams()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.nxtlapRacingRed)
                        }
                        .padding()
                    } else if viewModel.streams.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "play.rectangle.on.rectangle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.gray.opacity(0.3))
                            Text("No Livestreams Available")
                                .font(.title3)
                                .fontWeight(.bold)
                            Text("Check back later for live racing action.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    } else if viewModel.filteredStreams.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "eye.slash.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.gray.opacity(0.3))
                            Text("No Streams Selected")
                                .font(.title3)
                                .fontWeight(.bold)
                            Text("Manage your visible livestreams in the 'Settings' tab under 'Livestreams'.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            NavigationLink(destination: SettingsView()) {
                                Text("Go to Settings")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.nxtlapRacingRed)
                                    .clipShape(Capsule())
                            }
                            .padding(.top, 10)
                        }
                    } else {
                        ScrollView {
                            VStack(spacing: 24) {
                                if selectedTab == .upcoming {
                                    if viewModel.liveStreams.isEmpty && viewModel.upcomingStreams.isEmpty {
                                        emptyStateView(title: "No Upcoming Events", message: "Check back later for live racing action.")
                                    } else {
                                        // Live Now Section
                                        if !viewModel.liveStreams.isEmpty {
                                            VStack(alignment: .leading, spacing: 12) {
                                                SectionHeader(title: "Live Now", icon: "dot.radiowaves.left.and.right", color: .red)
                                                
                                                ScrollView(.horizontal, showsIndicators: false) {
                                                    HStack(spacing: 16) {
                                                        ForEach(viewModel.liveStreams) { stream in
                                                            LivestreamCard(stream: stream)
                                                                .frame(width: 320)
                                                        }
                                                    }
                                                    .padding(.horizontal, 4)
                                                }
                                            }
                                        }
                                        
                                        // Upcoming Events Section
                                        if !viewModel.upcomingStreams.isEmpty {
                                            VStack(alignment: .leading, spacing: 12) {
                                                SectionHeader(title: "Upcoming", icon: "calendar", color: .blue)
                                                
                                                LazyVStack(spacing: 16) {
                                                    ForEach(viewModel.upcomingStreams) { stream in
                                                        LivestreamCard(stream: stream)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                } else {
                                    if viewModel.pastStreams.isEmpty {
                                        emptyStateView(title: "No Past Broadcasts", message: "Completed streams will appear here.")
                                    } else {
                                        // Past Broadcasts Section
                                        VStack(alignment: .leading, spacing: 12) {
                                            SectionHeader(title: "Past Broadcasts", icon: "clock.arrow.circlepath", color: .gray)
                                            
                                            LazyVStack(spacing: 16) {
                                                ForEach(viewModel.pastStreams) { stream in
                                                    LivestreamCard(stream: stream)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(16)
                        }
                        .refreshable {
                            await viewModel.fetchLivestreams()
                        }
                    }
                }
            }
            .navigationTitle("Watch")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if viewModel.streams.isEmpty {
                    await viewModel.fetchLivestreams()
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    @ViewBuilder
    private func emptyStateView(title: String, message: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 100)
            Image(systemName: "play.rectangle.on.rectangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.3))
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.gray)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.top, 8)
    }
}

struct LivestreamCard: View {
    let stream: Livestream
    
    var isPast: Bool {
        stream.status == .completed
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thumbnail Section
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: stream.thumbnailUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                        .grayscale(isPast ? 0.8 : 0.0) // Desaturate past events
                        .opacity(isPast ? 0.6 : 1.0)
                } placeholder: {
                    Rectangle()
                        .fill(Color(white: 0.1))
                        .aspectRatio(16/9, contentMode: .fit)
                        .overlay(ProgressView().tint(.white))
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                
                // Status Badge
                HStack(spacing: 4) {
                    if stream.status == .live {
                        Circle()
                            .fill(.red)
                            .frame(width: 8, height: 8)
                            .shadow(color: .red, radius: 4)
                    }
                    Text(stream.status.displayName)
                        .font(.caption2)
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    BlurView(style: .systemUltraThinMaterialDark)
                        .clipShape(Capsule())
                )
                .padding(10)
            }
            
            // Content Section
            VStack(alignment: .leading, spacing: 8) {
                Text(stream.title)
                    .font(.headline)
                    .foregroundColor(isPast ? .gray : .white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "tv.fill")
                            .font(.caption2)
                        Text(stream.channelTitle)
                            .font(.caption)
                    }
                    .foregroundColor(.gray)
                    
                    Spacer()
                    
                    if let date = stream.startDate {
                        VStack(alignment: .trailing, spacing: 2) {
                            HStack(spacing: 4) {
                                Text(date, style: .date)
                                Text("•")
                                Text(date, style: .time)
                            }
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.gray)
                            
                            Text(stream.relativeTime)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(isPast ? .gray : .nxtlapRacingRed)
                        }
                    }
                }
                
                Link(destination: URL(string: stream.videoUrl)!) {
                    HStack {
                        Spacer()
                        Image(systemName: isPast ? "play.rectangle.fill" : "play.fill")
                        Text(stream.status.buttonTitle)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .background(
                        isPast ? AnyShapeStyle(Color.white.opacity(0.1)) : 
                        AnyShapeStyle(LinearGradient(
                            colors: [.nxtlapRacingRed, .nxtlapRacingRed.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                    )
                    .foregroundColor(isPast ? .gray : .white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(isPast ? 0.1 : 0), lineWidth: 1)
                    )
                }
                .padding(.top, 4)
            }
            .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(white: 0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(isPast ? 0.05 : 0.1), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

// Helper for blur effect if needed, otherwise use Material
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

#Preview {
    WatchView()
}
