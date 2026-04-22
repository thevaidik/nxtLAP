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
        loadRacingSeries()
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
    
    private func loadRacingSeries() {
        // Only include series that have actual API data (matching API service)
        allSeries = [
            // Formula Racing
            RacingSeries(name: "Formula 1", shortName: "F1", category: .formula, 
                        description: "The pinnacle of motorsport", iconName: "star.fill",
                        officialWebsite: "https://www.formula1.com",
                        aboutText: "Formula One is the highest class of international racing for open-wheel single-seater formula racing cars sanctioned by the Fédération Internationale de l'Automobile (FIA). The World Drivers' Championship, which became the FIA Formula One World Championship in 1981, has been one of the premier forms of racing around the world since its inaugural season in 1950."),
            
            // Motorcycle Racing
            RacingSeries(name: "MotoGP", shortName: "MOTO GP", category: .motorcycle, 
                        description: "Premier motorcycle racing", iconName: "star.fill",
                        officialWebsite: "https://www.motogp.com",
                        aboutText: "The FIM MotoGP World Championship is the premier class of motorcycle road racing events held on road circuits sanctioned by the Fédération Internationale de Motocyclisme (FIM)."),
            
            // Oval Racing
            RacingSeries(name: "NASCAR Cup Series", shortName: "NASCAR", category: .oval, 
                        description: "Stock car racing", iconName: "star.fill",
                        officialWebsite: "https://www.nascar.com",
                        aboutText: "The NASCAR Cup Series is the top racing series of the National Association for Stock Car Auto Racing (NASCAR). The series began in 1949 as the Strictly Stock Division, and from 1950 to 1970 it was known as the Grand National Division."),
            
            // Touring Cars
            RacingSeries(name: "British Touring Car Championship", shortName: "BTCC", category: .touring, 
                        description: "British touring car championship", iconName: "star.fill",
                        officialWebsite: "https://www.btcc.net",
                        aboutText: "The British Touring Car Championship is a touring car racing series held each year in the United Kingdom, currently organised and administered by TOCA. It was established in 1958 as the British Saloon Car Championship and has run to various rules over the years."),
            
            RacingSeries(name: "V8 Supercars", shortName: "V8SC", category: .touring, 
                        description: "Australian touring car championship", iconName: "star.fill",
                        officialWebsite: "https://www.supercars.com",
                        aboutText: "The Repco Supercars Championship is a touring car racing category in Australia and New Zealand, running as an International Series under Fédération Internationale de l'Automobile regulations, governing the sport."),
            
            // Rally
            RacingSeries(name: "World Rally Championship", shortName: "WRC", category: .rally, 
                        description: "Global rally championship", iconName: "star.fill",
                        officialWebsite: "https://www.wrc.com",
                        aboutText: "The World Rally Championship is the highest level of global competition in the motorsport discipline of rallying, owned and governed by the FIA. There are separate championships for drivers, co-drivers, manufacturers and teams."),
            
            // GT Racing
            RacingSeries(name: "Super GT Series", shortName: "SGT", category: .endurance, 
                        description: "Japanese GT championship", iconName: "star.fill",
                        officialWebsite: "https://supergt.net",
                        aboutText: "Super GT is a grand touring car racing series that began in 1993. Originally titled as the Zen Nihon GT Senshuken, generally referred to as either the JGTC or the All Japan Grand Touring Car Championship."),
            
            // Endurance Racing
            RacingSeries(name: "IMSA SportsCar Championship", shortName: "IMSA", category: .endurance, 
                        description: "North American endurance racing", iconName: "star.fill",
                        officialWebsite: "https://www.imsa.com",
                        aboutText: "The IMSA SportsCar Championship is a sports car racing series based in the United States and Canada and organized by the International Motor Sports Association (IMSA). It is a result of a merger between two existing North American sports car racing series, the American Le Mans Series and Rolex Sports Car Series."),
            
            RacingSeries(name: "IndyCar Series", shortName: "INDYCAR", category: .oval, 
                        description: "American open-wheel racing", iconName: "star.fill",
                        officialWebsite: "https://www.indycar.com",
                        aboutText: "The IndyCar Series is the top level of American open-wheel racing. The series is sanctioned by IndyCar LLC, which is owned by Penske Entertainment Corp. The series is known for the Indianapolis 500, one of the most prestigious races in the world."),
            
            RacingSeries(name: "British GT Championship", shortName: "BGT", category: .endurance, 
                        description: "British GT racing", iconName: "star.fill",
                        officialWebsite: "https://www.britishgt.com",
                        aboutText: "The British GT Championship is a sports car racing series based in the United Kingdom. The championship was founded in 1993 and is administered by the British Racing Drivers' Club.")
        ]
    }
    
    @MainActor
    private func loadRacingData() async {
        isLoadingData = true
        print("🔄 Starting to load racing data from APIs...")
        
        do {
                // Fetch all racing data from TheSportsDB - NO MOCK DATA
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

