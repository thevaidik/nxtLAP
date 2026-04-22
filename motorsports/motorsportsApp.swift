//
//  motorsportsApp.swift
//  motorsports
//
//  Created by Vaidik Dubey on 11/07/25.
//

import SwiftUI
import AVFoundation

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait
    }
}

@main
struct motorsportsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var racingDataService = RacingDataService()
    @StateObject private var livestreamViewModel = LivestreamViewModel()
    @StateObject private var notificationManager = NotificationManager.shared
    
    init() {
        configureAudioSession()
        HapticManager.shared.prepare()
        NotificationManager.shared.requestPermission()
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }
    }
    
    @Environment(\.scenePhase) var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(racingDataService)
                .environmentObject(livestreamViewModel)
                .environmentObject(notificationManager)
                .onChange(of: scenePhase) {
                    if scenePhase == .active {
                        notificationManager.updateScheduledStatus()
                    }
                }
        }
    }
}
