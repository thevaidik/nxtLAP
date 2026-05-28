import SwiftUI

struct WeeklyDraftView: View {
    @EnvironmentObject var fantasyViewModel: FantasyViewModel
    @StateObject var economyVM = FantasyEconomyViewModel()
    @EnvironmentObject var dataService: RacingDataService
    @State private var activeSlotIndex: Int? = nil
    
    // Compute closest upcoming race for the draft filter
    private var closestRace: Race? {
        dataService.upcomingRacesForStarredSeries.first ?? dataService.upcomingRaces.first
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Weekly Draft")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Nxt Currency Indicator
                HStack(spacing: 4) {
                    Image(systemName: "n.circle.fill")
                        .foregroundColor(.cyan)
                    Text("\(fantasyViewModel.coins)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            
            // Draft Slots
            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { index in
                    DraftSlotView(driver: fantasyViewModel.weeklyDraftPicks[index])
                        .onTapGesture {
                            activeSlotIndex = index
                        }
                }
            }
            .padding(.horizontal, 20)
        }
        .task {
            // Fetch drivers for the picker
            await economyVM.fetchMarketCards()
        }
        .sheet(item: Binding<Int?>(
            get: { activeSlotIndex },
            set: { activeSlotIndex = $0 }
        )) { index in
            DriverPickerSheet(slotIndex: index, upcomingRace: closestRace)
                .environmentObject(fantasyViewModel)
                .environmentObject(economyVM)
        }
    }
}

// Ensure Int conforms to Identifiable for the sheet
extension Int: Identifiable {
    public var id: Int { self }
}

struct DraftSlotView: View {
    let driver: DriverCardTemplate?
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6).opacity(0.15))
            
            if let driver = driver {
                // Filled State
                VStack(spacing: 0) {
                    if let urlString = driver.cutoutUrl ?? driver.imageUrl, let url = URL(string: urlString) {
                        CachedAsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFit()
                        } placeholder: {
                            ProgressView()
                        }
                        .padding(8)
                    } else {
                        Image(systemName: "person.crop.rectangle.fill")
                            .resizable()
                            .scaledToFit()
                            .padding(20)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Driver Name
                    Text(driver.driverName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal, 4)
                        .padding(.bottom, 8)
                }
            } else {
                // Empty State
                VStack {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(height: 140)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(driver != nil ? Color.cyan.opacity(0.5) : Color.white.opacity(0.2), style: driver != nil ? StrokeStyle(lineWidth: 2) : StrokeStyle(lineWidth: 1, dash: [5]))
        )
    }
}

#Preview {
    WeeklyDraftView()
        .environmentObject(FantasyViewModel())
}
