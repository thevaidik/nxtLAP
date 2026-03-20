//
//  AllRacesView.swift
//  motorsports
//

import SwiftUI

struct AllRacesView: View {
    @EnvironmentObject var dataService: RacingDataService
    @State private var selectedTab: RacesTab = .all

    enum RacesTab: String, CaseIterable {
        case all = "All Races"
        case myRaces = "My Races"
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Segmented picker
                Picker("Races", selection: $selectedTab) {
                    ForEach(RacesTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                if selectedTab == .all {
                    allRacesContent
                } else {
                    myRacesContent
                }
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Races")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - All Races
    private var allRacesContent: some View {
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
    }

    // MARK: - My Races
    private var myRacesContent: some View {
        Group {
            if dataService.starredSeriesList.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "star")
                        .font(.system(size: 40))
                        .foregroundColor(.yellow.opacity(0.5))
                    Text("No Starred Series")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("Star a series in 'All Races' to see it here")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(RacingCategory.allCases, id: \.self) { category in
                            let starred = dataService.starredSeriesList.filter { $0.category == category }
                            if !starred.isEmpty {
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
                                        ForEach(starred) { series in
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
            }
        }
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
                    Rectangle()
                        .fill(seriesGradient)
                        .frame(width: 3, height: 39)
                        .cornerRadius(3)

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
                        if !seriesRaces.isEmpty {
                            Text("\(seriesRaces.count) Race\(seriesRaces.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundColor(.racingRed)
                                .fontWeight(.medium)
                        }
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
                .fill(LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 35/255, green: 35/255, blue: 35/255),
                        Color(red: 20/255, green: 20/255, blue: 20/255)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(white: 0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    AllRacesView()
        .environmentObject(RacingDataService())
}
