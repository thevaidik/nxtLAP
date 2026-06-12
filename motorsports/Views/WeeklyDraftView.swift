import SwiftUI

struct WeeklyDraftView: View {
    @EnvironmentObject var fantasyViewModel: FantasyViewModel
    @EnvironmentObject var dataService: RacingDataService
    @EnvironmentObject var authVM: AuthenticationViewModel
    
    @State private var activeSlotIndex: Int? = nil
    @State private var showInsufficientFundsAlert: Bool = false
    @State private var showSignInAlert: Bool = false
    
    private var upcomingFantasyRaces: [Race] {
        let now = Date()
        let availableFantasySeries = Set(fantasyViewModel.availableCards.map { $0.series.uppercased() })
        
        let validRaces = dataService.upcomingRaces.filter { race in 
            let normalizedRaceSeries = race.series.uppercased() == "FORMULA1" ? "F1" : race.series.uppercased()
            return race.date > now &&
            availableFantasySeries.contains(normalizedRaceSeries) &&
            !race.name.localizedCaseInsensitiveContains("Practice") &&
            !race.name.localizedCaseInsensitiveContains("Qualifying") &&
            !race.name.localizedCaseInsensitiveContains("Warm Up")
        }.sorted { $0.date < $1.date }
        
        var seriesFound = [String]()
        
        for race in validRaces {
            let normalizedRaceSeries = race.series.uppercased() == "FORMULA1" ? "F1" : race.series.uppercased()
            if !seriesFound.contains(normalizedRaceSeries) {
                if seriesFound.count < 2 {
                    seriesFound.append(normalizedRaceSeries)
                }
            }
        }
        
        return validRaces.filter { race in 
            let normalizedRaceSeries = race.series.uppercased() == "FORMULA1" ? "F1" : race.series.uppercased()
            return seriesFound.contains(normalizedRaceSeries)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pick drivers, get NXT for every win.")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.gray)
                .padding(.horizontal, 20)
            
            if dataService.isLoadingData {
                RacingLoadingView()
                    .frame(minHeight: 250)
            } else {
            if upcomingFantasyRaces.isEmpty {
                // OFF-SEASON STATE
                VStack(spacing: 16) {
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    
                    Text("No Upcoming Fantasy Races")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("The draft will reopen when the next supported race week begins. Rest up!")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color(.systemGray6).opacity(0.1))
                .cornerRadius(16)
                .padding(.horizontal, 20)
                
            } else {

                // Draft Slots & Action Button
                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { index in
                        DraftSlotView(driver: fantasyViewModel.weeklyDraftPicks[index])
                            .onTapGesture {
                                if !authVM.isAuthenticated {
                                    showSignInAlert = true
                                } else if !fantasyViewModel.draftLocked {
                                    activeSlotIndex = index
                                }
                            }
                            .opacity((fantasyViewModel.draftLocked || !authVM.isAuthenticated) ? 0.6 : 1.0)
                    }
                    
                    Spacer()
                    
                    // Lock In / Edit Picks Small Button
                    if fantasyViewModel.weeklyDraftPicks.compactMap({ $0 }).count == 3 {
                        Button(action: {
                            if !authVM.isAuthenticated {
                                showSignInAlert = true
                                return
                            }
                            
                            if fantasyViewModel.draftLocked {
                                if fantasyViewModel.coins >= 500 {
                                    fantasyViewModel.unlockDraft(fee: 500)
                                } else {
                                    showInsufficientFundsAlert = true
                                    HapticManager.shared.trigger(.heavy)
                                }
                            } else {
                                Task {
                                    await fantasyViewModel.lockInDraft()
                                }
                            }
                        }) {
                            HStack(spacing: 4) {
                                if fantasyViewModel.isSyncing {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.8)
                                } else {
                                    Text(fantasyViewModel.draftLocked ? "Edit (500 NXT)" : "Draft")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Capsule())
                        }
                        .disabled(fantasyViewModel.isSyncing)
                        .animation(.spring(), value: fantasyViewModel.draftLocked)
                    }
                }
                .padding(.horizontal, 20)
            }
            } // End of else block for isLoadingData
        }
        .task {
            // Fetch drivers for the picker
            await fantasyViewModel.fetchMarketCards()
        }
        .sheet(item: Binding<Int?>(
            get: { activeSlotIndex },
            set: { activeSlotIndex = $0 }
        )) { index in
            DriverPickerSheet(slotIndex: index, upcomingRaces: upcomingFantasyRaces)
        }
        .alert("Insufficient Nxt", isPresented: $showInsufficientFundsAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You need 500 Nxt to edit a locked draft.")
        }
        .alert("Sign In Required", isPresented: $showSignInAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You must be signed in to play the Nxt Draft and earn rewards.")
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
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color(.systemGray6).opacity(0.15))
                    .frame(width: 72, height: 72)
                
                if let driver = driver {
                    if let urlString = driver.cutoutUrl ?? driver.imageUrl, let url = URL(string: urlString) {
                        CachedAsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 72, height: 72)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .foregroundColor(.gray)
                            .frame(width: 72, height: 72)
                    }
                } else {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.gray.opacity(0.6))
                }
            }
            .overlay(
                Circle()
                    .stroke(driver != nil ? Color.cyan.opacity(0.5) : Color.white.opacity(0.15), 
                            style: driver != nil ? StrokeStyle(lineWidth: 2) : StrokeStyle(lineWidth: 1, dash: [4]))
            )
            
            Text(driver?.driverName ?? "Empty")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(driver != nil ? .white : .gray.opacity(0.8))
                .lineLimit(1)
                .frame(width: 80)
        }
    }
}

#Preview {
    WeeklyDraftView()
        .environmentObject(FantasyViewModel())
}
