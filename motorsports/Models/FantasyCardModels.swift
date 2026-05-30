//
//  FantasyCardModels.swift
//  motorsports
//
//  Created for NxtLAP.
//

import Foundation

extension Int {
    var nxtFormatted: String {
        self.formatted(.number.locale(Locale(identifier: "en_US")))
    }
}

enum CardTier: String, CaseIterable, Codable {
    case common = "Common"
    case rare = "Rare"
    case epic = "Epic"
    case iconic = "Iconic"
    
    var multiplier: Double {
        switch self {
        case .common: return 1.0
        case .rare: return 1.5
        case .epic: return 2.5
        case .iconic: return 5.0
        }
    }
    
    var colorHex: String {
        switch self {
        case .common: return "#B0BEC5" // Silver/Gray
        case .rare: return "#42A5F5"   // Blue
        case .epic: return "#AB47BC"   // Purple
        case .iconic: return "#FFD700" // Gold
        }
    }
}

struct DriverCardTemplate: Identifiable, Codable {
    let id: String
    let driverName: String
    let series: String
    let team: String
    let basePriceNxt: Int
    let imageUrl: String?
    let cutoutUrl: String?
}

struct UserDriverCard: Identifiable, Codable {
    let id: UUID
    let template: DriverCardTemplate
    var tier: CardTier
    var totalYieldNxt: Int
    let acquiredAt: Date
}

// MARK: - Mock Data
struct FantasyMockData {
    static let driverTemplates: [DriverCardTemplate] = [
        DriverCardTemplate(id: "f1_verstappen", driverName: "Max Verstappen", series: "F1", team: "Red Bull Racing", basePriceNxt: 5000, imageUrl: nil, cutoutUrl: nil),
        DriverCardTemplate(id: "f1_norris", driverName: "Lando Norris", series: "F1", team: "McLaren", basePriceNxt: 4500, imageUrl: nil, cutoutUrl: nil),
        DriverCardTemplate(id: "f1_leclerc", driverName: "Charles Leclerc", series: "F1", team: "Ferrari", basePriceNxt: 4200, imageUrl: nil, cutoutUrl: nil),
        DriverCardTemplate(id: "imsa_derani", driverName: "Pipo Derani", series: "IMSA", team: "Action Express", basePriceNxt: 2000, imageUrl: nil, cutoutUrl: nil),
        DriverCardTemplate(id: "indy_palou", driverName: "Alex Palou", series: "IndyCar", team: "Chip Ganassi", basePriceNxt: 3500, imageUrl: nil, cutoutUrl: nil)
    ]
    
    static let mockInventory: [UserDriverCard] = [
        UserDriverCard(id: UUID(), template: driverTemplates[0], tier: .rare, totalYieldNxt: 1250, acquiredAt: Date().addingTimeInterval(-86400 * 5)),
        UserDriverCard(id: UUID(), template: driverTemplates[3], tier: .common, totalYieldNxt: 300, acquiredAt: Date().addingTimeInterval(-86400 * 2))
    ]
}
