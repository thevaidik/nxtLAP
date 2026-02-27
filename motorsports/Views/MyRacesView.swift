import SwiftUI

//  Created by Vaidik Dubey on 11/07/25.
//

struct MyRacesView: View {
    @EnvironmentObject var dataService: RacingDataService
    
    var body: some View {
        NavigationView {
            Group {
                if dataService.starredSeriesList.isEmpty {
                    VStack(spacing: 24) {
                        ZStack {
                            Rectangle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [.yellow.opacity(0.3), .yellow.opacity(0.1)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 80, height: 3)
                                .cornerRadius(3)
                        }
                        
                        VStack(spacing: 8) {
                            Text("No Starred Series")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Star racing series in the 'All' tab to see them here")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(RacingCategory.allCases, id: \.self) { category in
                                let starredSeriesInCategory = dataService.starredSeriesList.filter { $0.category == category }
                                if !starredSeriesInCategory.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Text(category.rawValue)
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.white)
                                            Spacer()
                                        }
                                        .padding(.horizontal, 20)
                                        
                                        LazyVStack(spacing: 8) {
                                            ForEach(starredSeriesInCategory) { series in
                                                MySeriesRow(series: series)
                                            }
                                        }
                                        .padding(.horizontal, 16)
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
                }
            }
            .navigationTitle("My Racing Series")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }
}

struct MySeriesRow: View {
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
        NavigationLink(destination: SeriesDetailView(series: series)) {
            HStack(spacing: 16) {
                // Icon with gradient background
                ZStack {
                    Rectangle()
                        .fill(seriesGradient)
                        .frame(width: 3, height: 45)
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
                    
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 14, weight: .medium))
                    
                    // Navigation indicator
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 35/255, green: 35/255, blue: 35/255),
                            Color(red: 20/255, green: 20/255, blue: 20/255)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    MyRacesView()
        .environmentObject(RacingDataService())
}
