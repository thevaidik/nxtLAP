//
//  WatchView.swift
//  motorsports
//
//  Created by Vaidik Dubey on 10/04/26.
//

import SwiftUI

struct WatchView: View {
    @EnvironmentObject var viewModel: LivestreamViewModel
    @State private var selectedTab: WatchTab = .watch
    @State private var selectedStream: Livestream?
    
    enum WatchTab: String, CaseIterable {
        case watch = "Watch"
        case upcoming = "Upcoming"
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
                                if selectedTab == .watch {
                                    if viewModel.pastStreams.isEmpty {
                                        emptyStateView(title: "No Past Broadcasts", message: "Completed streams will appear here.")
                                    } else {
                                        // Past Broadcasts Section
                                        VStack(alignment: .leading, spacing: 12) {
                                            SectionHeader(title: "Past Broadcasts", icon: "clock.arrow.circlepath", color: .gray)
                                            
                                            LazyVStack(spacing: 16) {
                                                ForEach(viewModel.pastStreams) { stream in
                                                    LivestreamCard(stream: stream, isWatchTab: true) {
                                                        selectedStream = stream
                                                    }
                                                }
                                            }
                                        }
                                    }
                                } else {
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
                                                            LivestreamCard(stream: stream) {
                                                                selectedStream = stream
                                                            }
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
                                                        LivestreamCard(stream: stream) {
                                                            // Logic handled in card
                                                        }
                                                    }
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
            .fullScreenCover(item: $selectedStream) { stream in
                YouTubeVideoPlayerView(stream: stream)
            }
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
    @EnvironmentObject var notificationManager: NotificationManager
    var isWatchTab: Bool = false
    var onPlay: () -> Void
    
    var isPast: Bool {
        stream.status == .completed || isWatchTab
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            thumbnailSection
            contentSection
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(white: 0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    private var thumbnailSection: some View {
        ZStack(alignment: .topTrailing) {
            AsyncImage(url: URL(string: stream.thumbnailUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(16/9, contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color(white: 0.1))
                    .aspectRatio(16/9, contentMode: .fit)
                    .overlay(ProgressView().tint(.white))
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            if stream.status == .upcoming && !isWatchTab {
                reminderToggle
            }
        }
    }
    
    private var reminderToggle: some View {
        Button(action: {
            notificationManager.toggleLivestreamNotification(stream: stream)
        }) {
            ZStack {
                Circle()
                    .fill(.black.opacity(0.6))
                    .blur(radius: 2)
                
                Image(systemName: notificationManager.isNotificationScheduled(id: stream.id) ? "bell.fill" : "bell")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(notificationManager.isNotificationScheduled(id: stream.id) ? .nxtlapRacingRed : .white)
            }
            .frame(width: 36, height: 36)
            .background(
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(12)
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(stream.title)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            infoRow
            actionButton
        }
        .padding(16)
    }
    
    private var infoRow: some View {
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
    }
    
    private var actionButton: some View {
        Button(action: {
            HapticManager.shared.trigger(.medium)
            if stream.status == .upcoming && !isWatchTab {
                notificationManager.toggleLivestreamNotification(stream: stream)
            } else {
                onPlay()
            }
        }) {
            HStack(spacing: 8) {
                Spacer()
                buttonLabel
                Spacer()
            }
            .padding(.vertical, 14)
            .background { buttonBackground }
            .foregroundColor(buttonForegroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(buttonBorder)
            .shadow(color: buttonShadowColor, radius: 10, x: 0, y: 5)
        }
        .padding(.top, 4)
    }
    
    @ViewBuilder
    private var buttonLabel: some View {
        if stream.status == .upcoming && !isWatchTab {
            Image(systemName: notificationManager.isNotificationScheduled(id: stream.id) ? "bell.fill" : "bell")
                .font(.system(size: 14, weight: .bold))
            Text(notificationManager.isNotificationScheduled(id: stream.id) ? "Reminder Set" : "Set Reminder")
                .font(.system(size: 15, weight: .bold, design: .rounded))
        } else {
            Image(systemName: (stream.status == .live && !isWatchTab) ? "dot.radiowaves.left.and.right" : "play.fill")
                .font(.system(size: 14, weight: .bold))
            Text((stream.status == .live && !isWatchTab) ? "Watch Now" : "Watch")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .tracking(0.5)
        }
    }
    
    @ViewBuilder
    private var buttonBackground: some View {
        if stream.status == .upcoming && !isWatchTab {
            ZStack {
                Color.blue.opacity(0.12)
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            }
        } else {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.1, blue: 0.1),
                        Color.nxtlapRacingRed,
                        Color(red: 0.7, green: 0, blue: 0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                LinearGradient(
                    colors: [.white.opacity(0.15), .clear],
                    startPoint: .top,
                    endPoint: .center
                )
            }
        }
    }
    
    private var buttonForegroundColor: Color {
        (stream.status == .upcoming && !isWatchTab) ? (notificationManager.isNotificationScheduled(id: stream.id) ? .nxtlapRacingRed : .blue) : .white
    }
    
    private var buttonBorder: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color.white.opacity(isWatchTab || stream.status != .upcoming ? 0.2 : 0), lineWidth: 0.5)
    }
    
    private var buttonShadowColor: Color {
        ((stream.status == .upcoming && !isWatchTab) ? Color.clear : Color.nxtlapRacingRed.opacity(0.4))
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
