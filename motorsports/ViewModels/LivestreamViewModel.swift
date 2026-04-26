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
    @Published var isLoading = false
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
        return dict.map { ChannelGroup(name: $0.key, streams: $0.value) }
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
            let fetchedStreams = try await livestreamService.fetchLivestreams()
            self.streams = fetchedStreams
        } catch {
            print("❌ Error fetching livestreams: \(error)")
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
