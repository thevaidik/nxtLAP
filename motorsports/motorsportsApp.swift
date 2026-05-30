//
//  motorsportsApp.swift
//  motorsports
//
//  Created by Vaidik Dubey on 11/07/25.
//

import SwiftUI
import AVFoundation
import Amplify
import AWSCognitoAuthPlugin

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
    @StateObject private var newsViewModel = NewsViewModel()
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var fantasyViewModel = FantasyViewModel()
    @StateObject private var userViewModel = UserViewModel()
    @StateObject private var storeManager = StoreManager()
    
    init() {
        configureAmplify()
        configureAudioSession()
        HapticManager.shared.prepare()
        NotificationManager.shared.requestPermission()
    }
    
    private func configureAmplify() {
        do {
            Amplify.Logging.logLevel = .verbose
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.configure()
            print("✅ Amplify configured securely")
        } catch {
            print("❌ Failed to initialize Amplify with error \(error)")
        }
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
                .environmentObject(newsViewModel)
                .environmentObject(notificationManager)
                .environmentObject(fantasyViewModel)
                .environmentObject(userViewModel)
                .environmentObject(storeManager)
                .fontWidth(Font.Width(0.1))
                .onChange(of: scenePhase) {
                    if scenePhase == .active {
                        notificationManager.updateScheduledStatus()
                    }
                }
        }
    }
}
