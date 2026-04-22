//
//  motorsportsApp.swift
//  motorsports
//
//  Created by Vaidik Dubey on 11/07/25.
//

import SwiftUI
import AVFoundation

@main
struct motorsportsApp: App {
    @StateObject private var racingDataService = RacingDataService()
    @StateObject private var livestreamViewModel = LivestreamViewModel()
    
    init() {
        configureAudioSession()
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(racingDataService)
                .environmentObject(livestreamViewModel)
        }
    }
}
