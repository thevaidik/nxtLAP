//
//  PayoutHistory.swift
//  motorsports
//
//  Created for NxtLAP.
//

import Foundation

struct PayoutHistory: Identifiable, Codable {
    let id = UUID()
    let date: String
    let draftYield: Int
    let garageYield: Int
    let totalYield: Int
    
    // Derived date for UI sorting if needed
    var parsedDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: date)
    }
}
