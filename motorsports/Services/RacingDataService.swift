//
//  RacingDataService.swift
//  motorsports
//
//  Created by Kiro on 20/08/25.
//

import Foundation

class RacingDataService: ObservableObject {
    @Published var allSeries: [RacingSeries] = []
    @Published var starredSeries: Set<String> = [] // Using shortName as identifier
    @Published var upcomingRaces: [Race] = []
    @Published var isLoadingData = false
    @Published var apiConnectionStatus: String = "Not tested"
    
    private let apiService = RacingAPIService()
    
    init() {
        loadRacingSeries()
        Task {
            await loadRacingData()
        }
    }
    
    private func loadRacingSeries() {
        allSeries = [
            // Formula Racing
            RacingSeries(name: "Formula 1", shortName: "F1", category: .formula, 
                        description: "The pinnacle of motorsport", iconName: "star.fill",
                        officialWebsite: "https://www.formula1.com",
                        aboutText: "Formula One is the highest class of international racing for open-wheel single-seater formula racing cars sanctioned by the Fédération Internationale de l'Automobile (FIA). The World Drivers' Championship, which became the FIA Formula One World Championship in 1981, has been one of the premier forms of racing around the world since its inaugural season in 1950."),
            
            RacingSeries(name: "Formula 2", shortName: "F2", category: .formula, 
                        description: "The pathway to Formula 1", iconName: "star.fill",
                        officialWebsite: "https://www.fiaformula2.com",
                        aboutText: "The FIA Formula 2 Championship is a second-tier single-seater racing championship that was introduced in 2017. It is the direct feeder series to Formula 1, designed to showcase the best up-and-coming drivers in identical cars."),
            
            RacingSeries(name: "Formula E", shortName: "FE", category: .formula, 
                        description: "Electric single-seater racing", iconName: "star.fill",
                        officialWebsite: "https://www.fiaformulae.com",
                        aboutText: "Formula E is a class of auto racing that uses only electric-powered cars. The series was conceived in 2011, and the inaugural championship started in Beijing in September 2014. It is sanctioned by the FIA and is the world's first fully-electric racing series."),
            
            // Endurance Racing
            RacingSeries(name: "World Endurance Championship", shortName: "WEC", category: .endurance, 
                        description: "Including Le Mans 24 Hours", iconName: "star.fill",
                        officialWebsite: "https://www.fiawec.com",
                        aboutText: "The FIA World Endurance Championship is an auto racing world championship organized by the Automobile Club de l'Ouest (ACO) and sanctioned by the Fédération Internationale de l'Automobile (FIA). The series superseded the ACO's former Intercontinental Le Mans Cup which began in 2010 and is the first endurance series of world championship status since the demise of the World Sportscar Championship at the end of 1992."),
            
            RacingSeries(name: "IMSA SportsCar Championship", shortName: "IMSA", category: .endurance, 
                        description: "North American endurance racing", iconName: "star.fill",
                        officialWebsite: "https://www.imsa.com",
                        aboutText: "The IMSA SportsCar Championship is a sports car racing series based in the United States and Canada and organized by the International Motor Sports Association (IMSA). It is a result of a merger between two existing North American sports car racing series, the American Le Mans Series and Rolex Sports Car Series."),
            
            RacingSeries(name: "European Le Mans Series", shortName: "ELMS", category: .endurance, 
                        description: "European endurance championship", iconName: "star.fill",
                        officialWebsite: "https://www.europeanlemansseries.com",
                        aboutText: "The European Le Mans Series is a European sports car racing endurance series inspired by the 24 Hours of Le Mans race and organized by the Automobile Club de l'Ouest (ACO). The ELMS was created in 2013 following the success of the Le Mans Series."),
            
            // Touring Cars
            RacingSeries(name: "Deutsche Tourenwagen Masters", shortName: "DTM", category: .touring, 
                        description: "German touring car championship", iconName: "star.fill",
                        officialWebsite: "https://www.dtm.com",
                        aboutText: "Deutsche Tourenwagen Masters (DTM) is a touring car series based in Germany, but also with rounds elsewhere in Europe. The series is regulated by DMSB and has been run by ITR since 2013."),
            
            // Rally
            RacingSeries(name: "World Rally Championship", shortName: "WRC", category: .rally, 
                        description: "Global rally championship", iconName: "star.fill",
                        officialWebsite: "https://www.wrc.com",
                        aboutText: "The World Rally Championship is the highest level of global competition in the motorsport discipline of rallying, owned and governed by the FIA. There are separate championships for drivers, co-drivers, manufacturers and teams."),
            
            // Oval Racing
            RacingSeries(name: "IndyCar Series", shortName: "INDYCAR", category: .oval, 
                        description: "American open-wheel racing", iconName: "star.fill",
                        officialWebsite: "https://www.indycar.com",
                        aboutText: "The IndyCar Series is the top level of American open-wheel racing. The series is sanctioned by IndyCar LLC, which is owned by Penske Entertainment Corp. The series is known for the Indianapolis 500, one of the most prestigious races in the world."),
            
            RacingSeries(name: "NASCAR Cup Series", shortName: "NASCAR", category: .oval, 
                        description: "Stock car racing", iconName: "star.fill",
                        officialWebsite: "https://www.nascar.com",
                        aboutText: "The NASCAR Cup Series is the top racing series of the National Association for Stock Car Auto Racing (NASCAR). The series began in 1949 as the Strictly Stock Division, and from 1950 to 1970 it was known as the Grand National Division."),
            
            // Motorcycle Racing
            RacingSeries(name: "MotoGP", shortName: "MOTO GP", category: .motorcycle, 
                        description: "Premier motorcycle racing", iconName: "star.fill",
                        officialWebsite: "https://www.motogp.com",
                        aboutText: "The FIM MotoGP World Championship is the premier class of motorcycle road racing events held on road circuits sanctioned by the Fédération Internationale de Motocyclisme (FIM)."),
            
            // Other
            RacingSeries(name: "Mazda Cup", shortName: "Mazda", category: .touring, 
                        description: "Spec racing series", iconName: "star.fill",
                        officialWebsite: "https://www.mazdamotorsports.com",
                        aboutText: "The Mazda Cup is a spec racing series featuring identical Mazda race cars, providing close competition and a pathway for developing racing talent.")
        ]
    }
    
    @MainActor
    private func loadRacingData() async {
        isLoadingData = true
        
        do {
            // Test API connection first
            let isConnected = await apiService.testAPIConnection()
            apiConnectionStatus = isConnected ? "✅ Connected" : "❌ Failed"
            
            var allRaces: [Race] = []
            
            // Try to fetch real F1 data
            if isConnected {
                let f1Races = try await apiService.fetchF1Schedule()
                allRaces.append(contentsOf: f1Races)
                print("✅ Loaded \(f1Races.count) F1 races from API")
            }
            
            // Add mock data for other series
            let mockRaces = apiService.fetchMockSeriesData()
            allRaces.append(contentsOf: mockRaces)
            
            // Add some mock F1 races if API failed
            if !isConnected {
                allRaces.append(contentsOf: loadMockF1Races())
            }
            
            // Sort by date and update
            upcomingRaces = allRaces.sorted { $0.date < $1.date }
            
        } catch {
            print("❌ Error loading racing data: \(error)")
            apiConnectionStatus = "❌ Error: \(error.localizedDescription)"
            // Fallback to mock data
            upcomingRaces = loadAllMockRaces()
        }
        
        isLoadingData = false
    }
    
    private func loadMockF1Races() -> [Race] {
        let calendar = Calendar.current
        let now = Date()
        
        return [
            Race(name: "Italian Grand Prix", series: "F1", 
                 date: calendar.date(byAdding: .day, value: 3, to: now)!, 
                 location: "Monza, Italy", circuit: "Autodromo Nazionale Monza"),
            Race(name: "Singapore Grand Prix", series: "F1", 
                 date: calendar.date(byAdding: .day, value: 17, to: now)!, 
                 location: "Singapore", circuit: "Marina Bay Street Circuit"),
            Race(name: "Japanese Grand Prix", series: "F1", 
                 date: calendar.date(byAdding: .day, value: 24, to: now)!, 
                 location: "Suzuka, Japan", circuit: "Suzuka International Racing Course")
        ]
    }
    
    private func loadAllMockRaces() -> [Race] {
        let calendar = Calendar.current
        let now = Date()
        
        return [
            // Formula 1
            Race(name: "Italian Grand Prix", series: "F1", 
                 date: calendar.date(byAdding: .day, value: 3, to: now)!, 
                 location: "Monza, Italy", circuit: "Autodromo Nazionale Monza"),
            Race(name: "Singapore Grand Prix", series: "F1", 
                 date: calendar.date(byAdding: .day, value: 17, to: now)!, 
                 location: "Singapore", circuit: "Marina Bay Street Circuit"),
            
            // WEC
            Race(name: "6 Hours of Fuji", series: "WEC", 
                 date: calendar.date(byAdding: .day, value: 10, to: now)!, 
                 location: "Fuji, Japan", circuit: "Fuji Speedway"),
            Race(name: "8 Hours of Bahrain", series: "WEC", 
                 date: calendar.date(byAdding: .day, value: 45, to: now)!, 
                 location: "Sakhir, Bahrain", circuit: "Bahrain International Circuit"),
            
            // IndyCar
            Race(name: "Grand Prix of Portland", series: "INDYCAR", 
                 date: calendar.date(byAdding: .day, value: 7, to: now)!, 
                 location: "Portland, OR", circuit: "Portland International Raceway"),
            
            // MotoGP
            Race(name: "Austrian Grand Prix", series: "MOTO GP", 
                 date: calendar.date(byAdding: .day, value: 14, to: now)!, 
                 location: "Spielberg, Austria", circuit: "Red Bull Ring"),
            
            // NASCAR
            Race(name: "Cook Out Southern 500", series: "NASCAR", 
                 date: calendar.date(byAdding: .day, value: 21, to: now)!, 
                 location: "Darlington, SC", circuit: "Darlington Raceway"),
            
            // Formula E
            Race(name: "London E-Prix", series: "FE", 
                 date: calendar.date(byAdding: .day, value: 28, to: now)!, 
                 location: "London, UK", circuit: "ExCeL London"),
            
            // WRC
            Race(name: "Rally Finland", series: "WRC", 
                 date: calendar.date(byAdding: .day, value: 35, to: now)!, 
                 location: "Jyväskylä, Finland"),
            
            // DTM
            Race(name: "DTM Hockenheim", series: "DTM", 
                 date: calendar.date(byAdding: .day, value: 42, to: now)!, 
                 location: "Hockenheim, Germany", circuit: "Hockenheimring")
        ]
    }
    
    func toggleStarredSeries(_ seriesShortName: String) {
        print("🔄 Toggling star for series: \(seriesShortName)")
        print("📊 Current starred series: \(starredSeries)")
        
        if starredSeries.contains(seriesShortName) {
            starredSeries.remove(seriesShortName)
            print("❌ Removed \(seriesShortName) from starred series")
        } else {
            starredSeries.insert(seriesShortName)
            print("✅ Added \(seriesShortName) to starred series")
        }
        
        print("📊 Updated starred series: \(starredSeries)")
        print("📋 Starred series list count: \(starredSeriesList.count)")
    }
    
    func isSeriesStarred(_ seriesShortName: String) -> Bool {
        starredSeries.contains(seriesShortName)
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