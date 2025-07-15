//
//  UpcomingRaces.swift
//  motorsports
//
//  Created by Vaidik Dubey on 11/07/25.
//

import SwiftUI

struct Race: Identifiable {
    let id = UUID()
    let name: String
    let date: Date
}

struct UpcomingRacesView: View {
    let races: [Race] = [
        Race(name: "Italian Grand Prix", date: Date().addingTimeInterval(86400 * 3)),
        Race(name: "Singapore Grand Prix", date: Date().addingTimeInterval(86400 * 10)),
        Race(name: "Japanese Grand Prix", date: Date().addingTimeInterval(86400 * 17)),
        Race(name: "Qatar Grand Prix", date: Date().addingTimeInterval(86400 * 24)),
        Race(name: "US Grand Prix", date: Date().addingTimeInterval(86400 * 31))
    ]
    
    var body: some View {
        NavigationStack {
            List(races) { race in
                HStack {
                    Text(race.name)
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Spacer()
                    
                    Text(formattedDate(race.date))
                        .font(.subheadline)
                        .foregroundColor(.racingRed)
                }
                .padding(.vertical, 4)
            }
            .listStyle(.plain)
            .navigationTitle("Upcoming Races")
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

#Preview {
    UpcomingRacesView()
}
