//
//  RacingModels.swift
//  motorsports
//
//  Created by Vaidik Dubey on 20/08/25.
//

import Foundation

struct RacingSeries: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let shortName: String
    let category: RacingCategory
    let description: String
    let iconName: String
    let officialWebsite: String
    let aboutText: String
}

enum RacingCategory: String, CaseIterable {
    case formula = "Formula Racing"
    case endurance = "Endurance Racing"
    case touring = "Touring Cars"
    case rally = "Rally"
    case oval = "Oval Racing"
    case motorcycle = "Motorcycle Racing"
    
    var color: String {
        switch self {
        case .formula: return "blue"
        case .endurance: return "green"
        case .touring: return "orange"
        case .rally: return "purple"
        case .oval: return "red"
        case .motorcycle: return "yellow"
        }
    }
}

struct Race: Identifiable, Codable {
    let id = UUID()
    let name: String
    let series: String
    let date: Date
    let location: String
    let circuit: String?
    let isStarred: Bool
    
    init(name: String, series: String, date: Date, location: String, circuit: String? = nil, isStarred: Bool = false) {
        self.name = name
        self.series = series
        self.date = date
        self.location = location
        self.circuit = circuit
        self.isStarred = isStarred
    }
}

struct RaceEvent: Identifiable {
    let id = UUID()
    let race: Race
    let startTime: Date
    let endTime: Date?
    let sessionType: SessionType
}

enum SessionType: String, CaseIterable {
    case practice = "Practice"
    case qualifying = "Qualifying"
    case race = "Race"
    case sprint = "Sprint"
}
