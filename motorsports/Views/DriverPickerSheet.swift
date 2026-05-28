import SwiftUI

struct DriverPickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var fantasyViewModel: FantasyViewModel
    @EnvironmentObject var economyVM: FantasyEconomyViewModel
    
    let slotIndex: Int
    let upcomingRace: Race?
    
    private var filteredDrivers: [DriverCardTemplate] {
        guard let race = upcomingRace else {
            return economyVM.availableCards // Fallback to all if no upcoming race
        }
        return economyVM.availableCards.filter { $0.series == race.series }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Draft Driver")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Select a driver for Slot \(slotIndex + 1)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    
                    Divider().background(Color.white.opacity(0.2))
                    
                    if economyVM.availableCards.isEmpty {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .cyan))
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(filteredDrivers) { driver in
                                    Button(action: {
                                        fantasyViewModel.makeDraftPick(index: slotIndex, driver: driver)
                                        dismiss()
                                    }) {
                                        HStack {
                                            // Mini Thumbnail
                                            if let urlString = driver.imageUrl ?? driver.cutoutUrl, let url = URL(string: urlString) {
                                                CachedAsyncImage(url: url) { image in
                                                    image
                                                        .resizable()
                                                        .scaledToFill()
                                                } placeholder: {
                                                    Color.gray.opacity(0.3)
                                                }
                                                .frame(width: 40, height: 40)
                                                .clipShape(Circle())
                                            } else {
                                                Circle()
                                                    .fill(Color.gray.opacity(0.3))
                                                    .frame(width: 40, height: 40)
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(driver.driverName)
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundColor(.white)
                                                Text(driver.team)
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "plus.circle.fill")
                                                .font(.title2)
                                                .foregroundColor(.cyan)
                                        }
                                        .padding()
                                        .background(Color(.systemGray6).opacity(0.1))
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
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
