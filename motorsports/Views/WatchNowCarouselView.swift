//
//  WatchNowCarouselView.swift
//  motorsports
//
//  Created by Vaidik Dubey on 22/04/26.
//

import SwiftUI

struct WatchNowCarouselView: View {
    @EnvironmentObject var viewModel: LivestreamViewModel
    @EnvironmentObject var dataService: RacingDataService
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
                                WatchSuggestionCard(stream: stream, isLive: isStreamLive(stream))
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
        let liveRaces = dataService.upcomingRaces.filter { $0.isLive }
        let liveSeriesNames = Set(liveRaces.map { $0.series.lowercased() })
        
        // Streams that are live according to backend
        let liveByBackend = viewModel.liveStreams
        
        // Streams that match a live race according to schedule
        let liveBySchedule = viewModel.streams.filter { stream in
            if stream.status == .completed { return false } // Don't mark completed as live
            let title = stream.title.lowercased()
            let channel = stream.channelTitle.lowercased()
            return liveSeriesNames.contains { series in
                title.contains(series) || channel.contains(series)
            }
        }
        
        var combinedLive = liveByBackend
        for stream in liveBySchedule {
            if !combinedLive.contains(where: { $0.id == stream.id }) {
                combinedLive.append(stream)
            }
        }
        
        let past = viewModel.pastStreams.filter { s in !combinedLive.contains(where: { $0.id == s.id }) }.prefix(5)
        return combinedLive + Array(past)
    }
    
    private func isStreamLive(_ stream: Livestream) -> Bool {
        if stream.status == .live { return true }
        if stream.status == .completed { return false }
        
        // Check schedule
        let liveRaces = dataService.upcomingRaces.filter { $0.isLive }
        let liveSeriesNames = Set(liveRaces.map { $0.series.lowercased() })
        let title = stream.title.lowercased()
        let channel = stream.channelTitle.lowercased()
        
        return liveSeriesNames.contains { series in
            title.contains(series) || channel.contains(series)
        }
    }
}

struct WatchSuggestionCard: View {
    let stream: Livestream
    let isLive: Bool
    
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
                
                // Status Badge
                HStack {
                    if isLive {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.red)
                                .frame(width: 6, height: 6)
                            Text("LIVE")
                                .font(.system(size: 10, weight: .black))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.black.opacity(0.75))
                        .cornerRadius(4)
                        .padding(8)
                    }
                    Spacer()
                }
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
                .stroke(isLive ? Color.red.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    WatchNowCarouselView()
        .environmentObject(LivestreamViewModel())
        .environmentObject(RacingDataService())
        .background(Color.black)
}
