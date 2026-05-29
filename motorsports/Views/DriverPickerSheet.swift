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
                futureRaces.contains { race in
                    driver.series.caseInsensitiveCompare(race.series) == .orderedSame
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
                            Text("Weekly Draft")
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
                            VStack(spacing: 24) {
                                ForEach(groupedDrivers, id: \.0) { seriesName, drivers in
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("\(seriesName.uppercased()) DRIVERS")
                                            .font(.system(size: 14, weight: .heavy))
                                            .foregroundColor(.gray)
                                            .padding(.horizontal, 8)
                                        
                                        VStack(spacing: 12) {
                                            ForEach(drivers) { driver in
                                                Button(action: {
                                                    fantasyViewModel.makeDraftPick(index: slotIndex, driver: driver)
                                                    dismiss()
                                                }) {
                                                    HStack(spacing: 16) {
                                                        // Mini Thumbnail
                                                        ZStack {
                                                            Circle()
                                                                .fill(Color(.systemGray6))
                                                                .frame(width: 48, height: 48)
                                                                
                                                            if let urlString = driver.cutoutUrl ?? driver.imageUrl, let url = URL(string: urlString) {
                                                                CachedAsyncImage(url: url) { image in
                                                                    image
                                                                        .resizable()
                                                                        .scaledToFit()
                                                                        .padding(.top, 4)
                                                                } placeholder: {
                                                                    ProgressView().scaleEffect(0.7)
                                                                }
                                                            } else {
                                                                Image(systemName: "person.fill")
                                                                    .foregroundColor(.gray)
                                                            }
                                                        }
                                                        .frame(width: 48, height: 48)
                                                        .clipShape(Circle())
                                                        .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                                                        
                                                        VStack(alignment: .leading, spacing: 4) {
                                                            Text(driver.driverName)
                                                                .font(.system(size: 16, weight: .bold))
                                                                .foregroundColor(.white)
                                                            
                                                            HStack(spacing: 6) {
                                                                Text(driver.team)
                                                                    .font(.system(size: 12, weight: .medium))
                                                                    .foregroundColor(.gray)
                                                                
                                                                Circle()
                                                                    .fill(Color.gray)
                                                                    .frame(width: 3, height: 3)
                                                                    
                                                                Text("Est. \(driver.basePriceNxt) Nxt")
                                                                    .font(.system(size: 11, weight: .bold))
                                                                    .foregroundColor(.cyan)
                                                            }
                                                        }
                                                        
                                                        Spacer()
                                                        
                                                        // Select Button
                                                        Text("DRAFT")
                                                            .font(.system(size: 12, weight: .bold))
                                                            .foregroundColor(.black)
                                                            .padding(.horizontal, 16)
                                                            .padding(.vertical, 8)
                                                            .background(Color.white)
                                                            .cornerRadius(20)
                                                    }
                                                    .padding()
                                                    .background(Color(.systemGray6).opacity(0.15))
                                                    .cornerRadius(16)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 16)
                                                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                                                    )
                                                }
                                            }
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
