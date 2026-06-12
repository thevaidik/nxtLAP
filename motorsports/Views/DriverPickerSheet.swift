import SwiftUI

struct DriverPickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var fantasyViewModel: FantasyViewModel
    
    let slotIndex: Int
    let upcomingRaces: [Race]
    
    private var groupedDrivers: [(String, [DriverCardTemplate])] {
        let now = Date()
        let futureRaces = upcomingRaces.filter { race in
            // If the race doesn't have an exact time, it defaults to 00:00:00Z (midnight).
            // This safely locks the draft the night before the race to prevent cheating.
            return race.date > now
        }
        
        let drivers: [DriverCardTemplate]
        if futureRaces.isEmpty {
            drivers = []
        } else {
            drivers = fantasyViewModel.availableCards.filter { driver in
                let normalizedDriverSeries = driver.series.uppercased() == "F1" ? "FORMULA1" : driver.series.uppercased()
                return futureRaces.contains { race in
                    let normalizedRaceSeries = race.series.uppercased() == "F1" ? "FORMULA1" : race.series.uppercased()
                    return normalizedDriverSeries == normalizedRaceSeries
                }
            }
        }
        
        let dict = Dictionary(grouping: drivers, by: { $0.series })
        // sort keys so that F1 is first, others alphabetical
        let sortedSeries = dict.keys.sorted { (s1, s2) in
            if s1.uppercased() == "F1" { return true }
            if s2.uppercased() == "F1" { return false }
            return s1 < s2
        }
        return sortedSeries.map { ($0, dict[$0]!) }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 8) {
                        if !upcomingRaces.isEmpty {
                            Text("Draft")
                                .font(.headline)
                                .foregroundColor(.white)
                        } else {
                            Text("Draft Driver")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        
                        Text("Select a driver for Slot \(slotIndex + 1)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    
                    Divider().background(Color.white.opacity(0.2))
                    
                    if fantasyViewModel.availableCards.isEmpty {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .cyan))
                        Spacer()
                    } else if groupedDrivers.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "clock.badge.xmark")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("Draft Closed")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("All supported races for this week have already begun.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 32) {
                                ForEach(groupedDrivers, id: \.0) { seriesName, drivers in
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text("\(seriesName.uppercased()) DRIVERS")
                                            .font(.system(size: 14, weight: .heavy))
                                            .foregroundColor(.gray)
                                            .padding(.horizontal, 20)
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 16) {
                                                ForEach(drivers) { driver in
                                                    Button(action: {
                                                        fantasyViewModel.makeDraftPick(index: slotIndex, driver: driver)
                                                        dismiss()
                                                    }) {
                                                        VStack(spacing: 12) {
                                                            // Mini Thumbnail
                                                            ZStack {
                                                                Circle()
                                                                    .fill(Color(.systemGray6))
                                                                    .frame(width: 64, height: 64)
                                                                    
                                                                if let urlString = driver.cutoutUrl ?? driver.imageUrl, let url = URL(string: urlString) {
                                                                    CachedAsyncImage(url: url) { image in
                                                                        image
                                                                            .resizable()
                                                                            .scaledToFit()
                                                                            .padding(.top, 4)
                                                                    } placeholder: {
                                                                        ProgressView().scaleEffect(0.8)
                                                                    }
                                                                } else {
                                                                    Image(systemName: "person.fill")
                                                                        .font(.system(size: 24))
                                                                        .foregroundColor(.gray)
                                                                }
                                                            }
                                                            .frame(width: 64, height: 64)
                                                            .clipShape(Circle())
                                                            .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                                                            
                                                            VStack(spacing: 4) {
                                                                Text(driver.driverName)
                                                                    .font(.system(size: 14, weight: .bold))
                                                                    .foregroundColor(.white)
                                                                    .lineLimit(1)
                                                                
                                                                Text(driver.team)
                                                                    .font(.system(size: 11, weight: .medium))
                                                                    .foregroundColor(.gray)
                                                                    .lineLimit(1)
                                                                    
                                                                Text("DRAFT")
                                                                    .font(.system(size: 10, weight: .black))
                                                                    .foregroundColor(.black)
                                                                    .padding(.horizontal, 16)
                                                                    .padding(.vertical, 6)
                                                                    .background(Color.cyan)
                                                                    .cornerRadius(8)
                                                                    .padding(.top, 4)
                                                            }
                                                        }
                                                        .frame(width: 120)
                                                        .padding(12)
                                                        .background(Color.white.opacity(0.05))
                                                        .cornerRadius(16)
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 16)
                                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                                        )
                                                    }
                                                }
                                            }
                                            .padding(.horizontal, 20)
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
}
