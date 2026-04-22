//
//  YouTubeVideoPlayerView.swift
//  motorsports
//
//  Created by Vaidik Dubey on 26/04/22.
//

import SwiftUI
import YouTubePlayerKit

struct YouTubeVideoPlayerView: View {
    let stream: Livestream
    @Environment(\.dismiss) private var dismiss
    @State private var youTubePlayer: YouTubePlayer
    
    init(stream: Livestream) {
        self.stream = stream
        // Initialize the player with the video URL and custom parameters
        self._youTubePlayer = State(initialValue: YouTubePlayer(
            source: .init(urlString: stream.videoUrl),
            parameters: .init(
                autoPlay: true,
                showControls: true,
                restrictRelatedVideosToSameChannel: true
            ),
            configuration: .init(
                allowsInlineMediaPlayback: false, // Forces native iOS player takeover immediately
                allowsAirPlayForMediaPlayback: true,
                allowsPictureInPictureMediaPlayback: true,
                customUserAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1"
            )
        ))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Player Area
                    YouTubePlayerView(self.youTubePlayer) { state in
                        switch state {
                        case .idle:
                            ProgressView()
                                .tint(.white)
                        case .ready:
                            EmptyView()
                        case .error(let error):
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.title)
                                    .foregroundColor(.nxtlapRacingRed)
                                Text("Failed to load video")
                                    .font(.headline)
                                Text(error.localizedDescription)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .aspectRatio(16/9, contentMode: .fit)
                    .background(Color.black)
                    
                    // Info Area
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(stream.title)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                HStack(spacing: 12) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "tv.fill")
                                        Text(stream.channelTitle)
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    
                                    if let date = stream.startDate {
                                        Text("•")
                                            .foregroundColor(.gray)
                                        Text(date, style: .date)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding(.top, 20)
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Status")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)
                                    .textCase(.uppercase)
                                
                                HStack {
                                    Circle()
                                        .fill(stream.status.statusColor)
                                        .frame(width: 8, height: 8)
                                    Text(stream.status.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(stream.status.statusColor.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            Spacer(minLength: 50)
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Watching")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }
}
