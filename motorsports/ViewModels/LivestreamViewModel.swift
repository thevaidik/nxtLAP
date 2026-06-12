//
//  LivestreamViewModel.swift
//  motorsports
//
//  Created by Vaidik Dubey on 10/04/26.
//

import SwiftUI
import Combine

@MainActor
class LivestreamViewModel: ObservableObject {
    @Published var streams: [Livestream] = []
    @Published var channels: [ChannelMetadata] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var excludedChannelNames: Set<String> = []
    
    private let livestreamService = LivestreamService()
    private let excludedKey = "excludedChannelLivestreams"
    
    struct ChannelGroup: Identifiable {
        var id: String { name }
        let name: String
        let streams: [Livestream]
    }
    
    init() {
        loadExcludedChannels()
    }
    
    var groupedChannels: [ChannelGroup] {
        let dict = Dictionary(grouping: streams) { $0.channelTitle }
        
        // Start with dynamically fetched channels list
        var channelsSet = Set(channels.map { $0.channelTitle })
        
        // Add any additional channel titles from the streams
        for stream in streams {
            channelsSet.insert(stream.channelTitle)
        }
        
        return channelsSet.map { name in
            ChannelGroup(name: name, streams: dict[name] ?? [])
        }
        .sorted { $0.name < $1.name }
    }
    
    var filteredStreams: [Livestream] {
        streams.filter { !excludedChannelNames.contains($0.channelTitle) }
    }
    
    private var now: Date { Date() }
    
    var liveStreams: [Livestream] {
        [] // No longer using a separate Live section in the UI
    }
    
    var upcomingStreams: [Livestream] {
        filteredStreams.filter { $0.effectiveStatus == .upcoming }
            .sorted { ($0.scheduledStartTime) < ($1.scheduledStartTime) }
    }
    
    var pastStreams: [Livestream] {
        filteredStreams.filter { $0.effectiveStatus != .upcoming }
            .sorted { $0.scheduledStartTime > $1.scheduledStartTime }
    }
    
    func fetchLivestreams() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let fetchedStreams = livestreamService.fetchLivestreams()
            async let fetchedChannels = livestreamService.fetchChannels()
            
            let (streamsResult, channelsResult) = try await (fetchedStreams, fetchedChannels)
            self.streams = streamsResult
            self.channels = channelsResult
        } catch {
            print("❌ Error fetching livestreams/channels: \(error)")
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func toggleChannel(name: String) {
        if excludedChannelNames.contains(name) {
            excludedChannelNames.remove(name)
        } else {
            excludedChannelNames.insert(name)
        }
        saveExcludedChannels()
    }
    
    func isChannelEnabled(name: String) -> Bool {
        !excludedChannelNames.contains(name)
    }
    
    private func loadExcludedChannels() {
        if let saved = UserDefaults.standard.stringArray(forKey: excludedKey) {
            excludedChannelNames = Set(saved)
        }
    }
    
    private func saveExcludedChannels() {
        UserDefaults.standard.set(Array(excludedChannelNames), forKey: excludedKey)
    }
}
