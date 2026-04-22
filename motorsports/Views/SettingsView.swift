//
//  AllRacesView.swift
//  motorsports
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var dataService: RacingDataService
    @EnvironmentObject var livestreamViewModel: LivestreamViewModel
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var selectedTab: SettingsTab = .series

    enum SettingsTab: String, CaseIterable {
        case series = "Series"
        case streams = "Livestreams"
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerActions
                
                // Segmented picker
                Picker("Settings", selection: $selectedTab) {
                    ForEach(SettingsTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                if selectedTab == .series {
                    allRacesContent
                } else {
                    liveContent
                }
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if livestreamViewModel.streams.isEmpty {
                    await livestreamViewModel.fetchLivestreams()
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Header Actions
    private var headerActions: some View {
        HStack(spacing: 12) {
            // Suggest a Feature (Left)
            Button(action: {
                if let url = URL(string: "mailto:founders@nxtlap.com?subject=App%20Feedback") {
                    UIApplication.shared.open(url)
                }
            }) {
                VStack(alignment: .leading, spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing).opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: "sparkles")
                            .foregroundColor(.yellow)
                            .font(.system(size: 14, weight: .bold))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Suggest")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Feature / Bug")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color(white: 0.12))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
            
            // Widgets & Notifications (Right)
            NavigationLink(destination: WidgetsAndNotificationsView()) {
                VStack(alignment: .leading, spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.nxtlapRacingRed, .orange], startPoint: .topLeading, endPoint: .bottomTrailing).opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: "square.grid.2x2.fill")
                            .foregroundColor(.nxtlapRacingRed)
                            .font(.system(size: 14, weight: .bold))
                            .overlay(
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 8))
                                    .offset(x: 8, y: -8)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Widgets & Alerts")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Manage Everything")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color(white: 0.12))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 6)
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

    // MARK: - Live Content
    private var liveContent: some View {
        Group {
            if livestreamViewModel.isLoading && livestreamViewModel.streams.isEmpty {
                VStack {
                    Spacer()
                    ProgressView()
                        .tint(.racingRed)
                    Text("Loading channels...")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 10)
                    Spacer()
                }
            } else if livestreamViewModel.streams.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "video.slash")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("No Channels Found")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("Connect to the network to see available streaming channels.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("STREAMING CHANNELS")
                            .font(.footnote)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)

                        LazyVStack(spacing: 12) {
                            ForEach(livestreamViewModel.groupedChannels) { channelGroup in
                                ChannelToggleRow(channelGroup: channelGroup)
                            }
                        }
                        .padding(.horizontal, 18)
                    }
                    .padding(.bottom, 20)
                }
                .refreshable {
                    await livestreamViewModel.fetchLivestreams()
                }
            }
        }
    }
}

struct ChannelToggleRow: View {
    let channelGroup: LivestreamViewModel.ChannelGroup
    @EnvironmentObject var viewModel: LivestreamViewModel

    var body: some View {
        HStack(spacing: 16) {
            // Channel Icon / Thumbnail
            if let firstStream = channelGroup.streams.first {
                AsyncImage(url: URL(string: firstStream.thumbnailUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
                .frame(width: 80, height: 45)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    // Badge for stream count
                    ZStack {
                        Circle()
                            .fill(Color.racingRed)
                            .frame(width: 20, height: 20)
                        Text("\(channelGroup.streams.count)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: 5, y: -5),
                    alignment: .topTrailing
                )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(channelGroup.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("\(channelGroup.streams.count) \(channelGroup.streams.count == 1 ? "Livestream" : "Livestreams")")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { viewModel.isChannelEnabled(name: channelGroup.name) },
                set: { _ in
                    withAnimation {
                        viewModel.toggleChannel(name: channelGroup.name)
                    }
                }
            ))
            .labelsHidden()
            .tint(.racingRed)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(white: 0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

struct SeriesRow: View {
    let series: RacingSeries
    @EnvironmentObject var dataService: RacingDataService

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
                        Text("View")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(.racingRed.opacity(0.9))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }

            Toggle(
                "",
                isOn: Binding(
                    get: { dataService.isSeriesStarred(series.shortName) },
                    set: { _ in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            dataService.toggleStarredSeries(series.shortName)
                        }
                    }
                )
            )
            .labelsHidden()
            .toggleStyle(.switch)
            .tint(.racingRed)
            .padding(.trailing, 18)
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
    SettingsView()
        .environmentObject(RacingDataService())
}
