//
//  WatchView.swift
//  motorsports
//
//  Created by Antigravity on 10/04/26.
//

import SwiftUI

struct WatchView: View {
    @EnvironmentObject var viewModel: LivestreamViewModel
    
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
                
                if viewModel.isLoading && viewModel.streams.isEmpty {
                    ProgressView()
                        .tint(.nxtlapRacingRed)
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
                        LazyVStack(spacing: 20) {
                            ForEach(viewModel.filteredStreams) { stream in
                                LivestreamCard(stream: stream)
                            }
                        }
                        .padding(16)
                    }
                    .refreshable {
                        await viewModel.fetchLivestreams()
                    }
                }
            }
            .navigationTitle("Watch")
            .navigationBarTitleDisplayMode(.large)
            .task {
                if viewModel.streams.isEmpty {
                    await viewModel.fetchLivestreams()
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct LivestreamCard: View {
    let stream: Livestream
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thumbnail Section
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
                    .foregroundColor(.white)
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
                    
                    if let date = ISO8601DateFormatter().date(from: stream.scheduledStartTime) {
                        Text(date, style: .time)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.nxtlapRacingRed)
                    }
                }
                
                Link(destination: URL(string: stream.videoUrl)!) {
                    HStack {
                        Spacer()
                        Image(systemName: "play.fill")
                        Text(stream.status == .live ? "Watch Now" : "Set Reminder")
                            .fontWeight(.bold)
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [.nxtlapRacingRed, .nxtlapRacingRed.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
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
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
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
