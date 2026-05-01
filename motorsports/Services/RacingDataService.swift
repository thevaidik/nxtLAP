//
//  RacingDataService.swift
//  motorsports
//
//  Created by Vaidik Dubey on 20/08/25.
//

import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

class RacingDataService: ObservableObject {
    @Published var allSeries: [RacingSeries] = []
    @Published var starredSeries: Set<String> = [] // Using shortName as identifier
    @Published var notificationsEnabledSeries: Set<String> = [] // Independent notification toggle
    @Published var upcomingRaces: [Race] = []
    @Published var isLoadingData = false
    @Published var isDevMode = false
    @Published var apiConnectionStatus: String = "Not tested"
    
    private let apiService = RacingAPIService()
    private let starredSeriesKey = "starredRacingSeries"
    private let notificationsEnabledKey = "notificationsEnabledSeries"
    private let devModeKey = "isDevModeEnabled"
    
    // MARK: - Widget/App Group Sharing
    // TODO: Set this to your real App Group ID and enable it in BOTH the app target and the widget extension target entitlements
    private let appGroupID = "group.vaidik.motorsports"
    private let widgetUpcomingKey = "widget_upcoming_races"
    private let widgetStarredKey = "widget_starred_series"

    private func syncWidgetData() {
        let encoder = JSONEncoder()
        // Ensure stable date encoding/decoding
        encoder.dateEncodingStrategy = .iso8601

        // Save upcoming races for the widget
        if let defaults = UserDefaults(suiteName: appGroupID) {
            do {
                let data = try encoder.encode(upcomingRaces)
                defaults.set(data, forKey: widgetUpcomingKey)
                defaults.set(Array(starredSeries), forKey: widgetStarredKey)
                defaults.synchronize()
            } catch {
                print("❌ Failed to encode upcoming races for widget: \(error)")
            }
        } else {
            print("⚠️ App Group defaults unavailable. Check App Group ID: \(appGroupID)")
        }

        #if canImport(WidgetKit)
        // Ask WidgetKit to refresh timelines
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
    
    init() {
        loadStarredSeries()
        loadNotificationPreferences()
        loadDevMode()
        Task {
            await loadRacingData()
        }
    }
    
    private func loadDevMode() {
        isDevMode = UserDefaults.standard.bool(forKey: devModeKey)
    }
    
    func toggleDevMode() {
        isDevMode.toggle()
        UserDefaults.standard.set(isDevMode, forKey: devModeKey)
        HapticManager.shared.trigger(.medium)
    }
    
    private func loadNotificationPreferences() {
        if let savedData = UserDefaults.standard.array(forKey: notificationsEnabledKey) as? [String] {
            notificationsEnabledSeries = Set(savedData)
        }
    }
    
    private func saveNotificationPreferences() {
        let array = Array(notificationsEnabledSeries)
        UserDefaults.standard.set(array, forKey: notificationsEnabledKey)
    }
    
    private func loadStarredSeries() {
        if let savedData = UserDefaults.standard.array(forKey: starredSeriesKey) as? [String] {
            starredSeries = Set(savedData)
            print("📂 Loaded \(starredSeries.count) starred series from storage: \(starredSeries)")
        } else {
            print("📂 No saved starred series found")
        }
    }
    
    private func saveStarredSeries() {
        let seriesArray = Array(starredSeries)
        UserDefaults.standard.set(seriesArray, forKey: starredSeriesKey)
        print("💾 Saved \(starredSeries.count) starred series to storage: \(starredSeries)")
    }
    
    @MainActor
    private func loadRacingData() async {
        isLoadingData = true
        print("🔄 Starting to load racing data from APIs...")
        
        do {
                // 1. Fetch Series First
                print("📡 Fetching racing series from API...")
                let serverSeries = try await apiService.fetchSeries()
                
                // Map to RacingSeries and update global slug mapper
                var newAllSeries: [RacingSeries] = []
                for ss in serverSeries {
                    RacingServerEvent.dynamicSlugToShortName[ss.id] = ss.short_name
                    
                    let series = RacingSeries(
                        name: ss.name,
                        shortName: ss.short_name,
                        category: RacingCategory.from(serverCategory: ss.category),
                        description: ss.description,
                        iconName: "star.fill",
                        officialWebsite: nil,
                        aboutText: ss.description
                    )
                    newAllSeries.append(series)
                }
                self.allSeries = newAllSeries
                print("✅ Successfully loaded \(self.allSeries.count) series")

                // 2. Fetch all racing data from TheSportsDB - NO MOCK DATA
                print("📡 Fetching real racing data from TheSportsDB...")
                let realRaces = try await apiService.fetchAllRacingData()
                
                if realRaces.isEmpty {
                    print("⚠️ WARNING: No races returned from API")
                    apiConnectionStatus = "⚠️ API Connected but No Data"
                    upcomingRaces = []
                    syncWidgetData()
                } else {
                    print("✅ Successfully loaded \(realRaces.count) real races from TheSportsDB API")
                    let today = Calendar.current.startOfDay(for: Date())
                    upcomingRaces = realRaces
                        .filter { Calendar.current.startOfDay(for: $0.date) >= today }
                        .sorted { $0.date < $1.date }
                    
                    // Automatically sync race notifications based on explicit preferences
                    NotificationManager.shared.syncRaceNotifications(races: upcomingRaces, enabledSeries: notificationsEnabledSeries)
                    
                    syncWidgetData()
                    // Log race breakdown by series
                    let racesBySeriesCount = Dictionary(grouping: upcomingRaces, by: { $0.series })
                        .mapValues { $0.count }
                    print("📊 Upcoming races by series: \(racesBySeriesCount)")
                }
        
        } catch {
            print("❌ CRITICAL ERROR loading racing data: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            if let urlError = error as? URLError {
                print("❌ URL Error code: \(urlError.code.rawValue)")
                
                print("❌ URL Error description: \(urlError.localizedDescription)")
            }
            apiConnectionStatus = "❌ Error: \(error.localizedDescription)"
            upcomingRaces = []
            syncWidgetData()
        }
        
        isLoadingData = false
        print("🏁 Finished loading racing data. Total races: \(upcomingRaces.count)")
    }
    
    // MARK: - No Mock Data - Real API Only
    
    func toggleStarredSeries(_ seriesShortName: String) {
        print("🔄 Toggling star for series: \(seriesShortName)")
        print("📊 Current starred series: \(starredSeries)")
        
        if starredSeries.contains(seriesShortName) {
            starredSeries.remove(seriesShortName)
            print("❌ Removed \(seriesShortName) from starred series")
        } else {
            starredSeries.insert(seriesShortName)
            // Enable notifications by default when starring
            if !notificationsEnabledSeries.contains(seriesShortName) {
                notificationsEnabledSeries.insert(seriesShortName)
                saveNotificationPreferences()
                NotificationManager.shared.syncRaceNotifications(races: upcomingRaces, enabledSeries: notificationsEnabledSeries)
            }
            print("✅ Added \(seriesShortName) to starred series")
        }
        
        saveStarredSeries()
        syncWidgetData()
        print("📊 Updated starred series: \(starredSeries)")
        print("📋 Starred series list count: \(starredSeriesList.count)")
    }
    
    func isSeriesStarred(_ seriesShortName: String) -> Bool {
        starredSeries.contains(seriesShortName)
    }
    
    func toggleNotificationsForSeries(_ seriesShortName: String) {
        if notificationsEnabledSeries.contains(seriesShortName) {
            notificationsEnabledSeries.remove(seriesShortName)
        } else {
            notificationsEnabledSeries.insert(seriesShortName)
        }
        saveNotificationPreferences()
        NotificationManager.shared.syncRaceNotifications(races: upcomingRaces, enabledSeries: notificationsEnabledSeries)
    }
    
    func areNotificationsEnabled(for seriesShortName: String) -> Bool {
        notificationsEnabledSeries.contains(seriesShortName)
    }
    
    var starredSeriesList: [RacingSeries] {
        let filtered = allSeries.filter { starredSeries.contains($0.shortName) }
        print("🌟 Computing starredSeriesList: \(filtered.map { $0.shortName })")
        return filtered
    }
    
    var upcomingRacesForStarredSeries: [Race] {
        upcomingRaces.filter { starredSeries.contains($0.series) }
    }
    
    func getRacesForSeries(_ seriesShortName: String) -> [Race] {
        upcomingRaces.filter { $0.series == seriesShortName }
    }
    
    func refreshData() async {
        await loadRacingData()
    }
}

