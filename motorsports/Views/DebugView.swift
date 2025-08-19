//
//  DebugView.swift
//  motorsports
//
//  Created by Kiro on 20/08/25.
//

import SwiftUI

struct DebugView: View {
    @EnvironmentObject var dataService: RacingDataService
    
    var body: some View {
        NavigationView {
            List {
                Section("API Status") {
                    HStack {
                        Text("Connection Status")
                        Spacer()
                        Text(dataService.apiConnectionStatus)
                            .foregroundColor(dataService.apiConnectionStatus.contains("✅") ? .green : .red)
                    }
                    
                    HStack {
                        Text("Total Races Loaded")
                        Spacer()
                        Text("\(dataService.upcomingRaces.count)")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Starred Series")
                        Spacer()
                        Text("\(dataService.starredSeries.count)")
                            .fontWeight(.semibold)
                    }
                    
                    Button("Refresh Data") {
                        Task {
                            await dataService.refreshData()
                        }
                    }
                    .foregroundColor(.racingRed)
                }
                
                Section("Racing Series") {
                    ForEach(dataService.allSeries) { series in
                        HStack {
                            Image(systemName: series.iconName)
                                .foregroundColor(.racingRed)
                            
                            VStack(alignment: .leading) {
                                Text(series.name)
                                    .font(.headline)
                                Text(series.shortName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            let count = dataService.upcomingRaces.filter { $0.series == series.shortName }.count
                            Text("\(count)")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(count > 0 ? Color.racingRed : Color.gray)
                                .clipShape(Capsule())
                        }
                    }
                }
                
                Section("Sample Race Data") {
                    ForEach(dataService.upcomingRaces.prefix(5)) { race in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(race.name)
                                .font(.headline)
                            Text("\(race.series) • \(race.location)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formattedDate(race.date))
                                .font(.caption)
                                .foregroundColor(.racingRed)
                        }
                    }
                }
            }
            .navigationTitle("Debug Info")
            .refreshable {
                await dataService.refreshData()
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    DebugView()
        .environmentObject(RacingDataService())
}