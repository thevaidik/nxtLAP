//
//  WatchNowCarouselView.swift
//  motorsports
//
//  Created by Vaidik Dubey on 22/04/26.
//

import SwiftUI

struct WatchNowCarouselView: View {
    @EnvironmentObject var viewModel: LivestreamViewModel
    @State private var selectedStream: Livestream?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("What to Watch")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Link to Watch tab (handled by parent through selectedTab binding if needed, 
                // but for now just a label or we can pass the binding)
            }
            .padding(.horizontal, 20)
            
            if viewModel.isLoading && viewModel.streams.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(0..<3) { _ in
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(white: 0.12))
                                .frame(width: 200, height: 120)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            } else if !displayStreams.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(displayStreams) { stream in
                            Button(action: {
                                selectedStream = stream
                                HapticManager.shared.trigger(.medium)
                            }) {
                                WatchSuggestionCard(stream: stream)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            } else {
                // Empty state if no streams at all
                Text("No recent broadcasts available")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
            }
        }
        .fullScreenCover(item: $selectedStream) { stream in
            YouTubeVideoPlayerView(stream: stream)
        }
    }
    
    private var displayStreams: [Livestream] {
        Array(viewModel.pastStreams.prefix(10))
    }
}

struct WatchSuggestionCard: View {
    let stream: Livestream
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thumbnail with Overlay
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: URL(string: stream.thumbnailUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color(white: 0.1)
                }
                .frame(width: 200, height: 110)
                .clipped()
                
                .frame(width: 200, height: 110)
                .clipped()
            }
            
            // Text Content
            VStack(alignment: .leading, spacing: 4) {
                Text(stream.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(height: 32, alignment: .top)
                
                Text(stream.channelTitle)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            .padding(10)
            .frame(width: 200)
            .background(Color(white: 0.12))
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    WatchNowCarouselView()
        .environmentObject(LivestreamViewModel())
        .background(Color.black)
}
