//  Created by Vaidik Dubey on 11/07/25.
//

import SwiftUI

struct AllRacesView: View {
    @EnvironmentObject var dataService: RacingDataService
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(RacingCategory.allCases, id: \.self) { category in
                        let seriesInCategory = dataService.allSeries.filter { $0.category == category }
                        if !seriesInCategory.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(category.rawValue)
                                        .font(.footnote)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                
                                LazyVStack(spacing: 8) {
                                    ForEach(seriesInCategory) { series in
                                        SeriesRow(series: series)
                                    }
                                }
                                .padding(.horizontal, 18)
                            }
                        }
                    }
                }
                .padding(.vertical, 16)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemGray6).opacity(0.05),
                        Color(.systemGray5).opacity(0.1),
                        Color(.systemGray6).opacity(0.05)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("All Racing Series")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }
}

struct SeriesRow: View {
    let series: RacingSeries
    @EnvironmentObject var dataService: RacingDataService
    
    var seriesRaces: [Race] {
        dataService.getRacesForSeries(series.shortName)
    }
    
    var seriesGradient: LinearGradient {
        let gradients: [LinearGradient] = [
            LinearGradient(gradient: Gradient(colors: [.red, .orange]), startPoint: .topLeading, endPoint: .bottomTrailing),
            LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing),
            LinearGradient(gradient: Gradient(colors: [.green, .mint]), startPoint: .topLeading, endPoint: .bottomTrailing),
            LinearGradient(gradient: Gradient(colors: [.orange, .yellow]), startPoint: .topLeading, endPoint: .bottomTrailing),
            LinearGradient(gradient: Gradient(colors: [.purple, .pink]), startPoint: .topLeading, endPoint: .bottomTrailing),
            LinearGradient(gradient: Gradient(colors: [.cyan, .blue]), startPoint: .topLeading, endPoint: .bottomTrailing),
            LinearGradient(gradient: Gradient(colors: [.indigo, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing),
            LinearGradient(gradient: Gradient(colors: [.pink, .red]), startPoint: .topLeading, endPoint: .bottomTrailing),
            LinearGradient(gradient: Gradient(colors: [.mint, .green]), startPoint: .topLeading, endPoint: .bottomTrailing),
            LinearGradient(gradient: Gradient(colors: [.yellow, .orange]), startPoint: .topLeading, endPoint: .bottomTrailing),
            LinearGradient(gradient: Gradient(colors: [.teal, .cyan]), startPoint: .topLeading, endPoint: .bottomTrailing),
            LinearGradient(gradient: Gradient(colors: [.brown, .orange]), startPoint: .topLeading, endPoint: .bottomTrailing)
        ]
        
        let index = abs(series.shortName.hashValue) % gradients.count
        return gradients[index]
    }
    
    var body: some View {
        HStack(spacing: 0) {
            NavigationLink(destination: SeriesDetailView(series: series)) {
                HStack(spacing: 16) {
                    // Icon with gradient background
                    ZStack {
                        Rectangle()
                            .fill(seriesGradient)
                            .frame(width: 3, height: 39)
                            .cornerRadius(3)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(series.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        Text(series.description)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        // Race count text
                        if !seriesRaces.isEmpty {
                            Text("\(seriesRaces.count) Race\(seriesRaces.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundColor(.racingRed)
                                .fontWeight(.medium)
                        }
                        
                        // Navigation indicator
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            
            Button(action: {
                withAnimation(.default) {
                    dataService.toggleStarredSeries(series.shortName)
                    print("⭐ Toggled star for \(series.shortName), starred: \(dataService.isSeriesStarred(series.shortName))")
                }
            }) {
                Image(systemName: dataService.isSeriesStarred(series.shortName) ? "star.fill" : "star")
                    .foregroundColor(dataService.isSeriesStarred(series.shortName) ? .yellow : .gray)
                    .font(.system(size: 16, weight: .medium))
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.trailing, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6).opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    AllRacesView()
        .environmentObject(RacingDataService())
}
