//
//  motorsportsApp.swift
//  motorsports
//
//  Created by Vaidik Dubey on 11/07/25.
//

import SwiftUI

@main
struct motorsportsApp: App {
    @StateObject private var racingDataService = RacingDataService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(racingDataService)
        }
    }
}
