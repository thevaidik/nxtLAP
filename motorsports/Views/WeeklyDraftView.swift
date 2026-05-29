import SwiftUI

struct WeeklyDraftView: View {
    @EnvironmentObject var fantasyViewModel: FantasyViewModel
    @EnvironmentObject var dataService: RacingDataService
    @State private var activeSlotIndex: Int? = nil
    @State private var showInsufficientFundsAlert = false
    @State private var showRulesSheet = false
    
    private var upcomingFantasyRaces: [Race] {
        let cal = Calendar.current
        let today = Date()
        let availableFantasySeries = Set(fantasyViewModel.availableCards.map { $0.series.uppercased() })
        
        return dataService.upcomingRaces.filter { race in 
            cal.isDate(race.date, equalTo: today, toGranularity: .weekOfYear) &&
            availableFantasySeries.contains(race.series.uppercased()) &&
            !race.name.localizedCaseInsensitiveContains("Practice") &&
            !race.name.localizedCaseInsensitiveContains("Qualifying") &&
            !race.name.localizedCaseInsensitiveContains("Warm Up")
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("🏆 Nxt Weekly Draft")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Rules Button
                Button(action: {
                    showRulesSheet = true
                }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.gray)
                }
                .padding(.trailing, 4)
                
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
            
            if dataService.isLoadingData {
                RacingLoadingView()
                    .frame(minHeight: 250)
            } else {
                // This Week's Fantasy Races List
            if !upcomingFantasyRaces.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(upcomingFantasyRaces) { race in
                            HStack(spacing: 10) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(race.series.uppercased())
                                        .font(.system(size: 10, weight: .heavy))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(seriesColor(for: race.series))
                                        .cornerRadius(4)
                                    
                                    Text(race.name)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    
                                    if race.hasExactTime {
                                        Text(race.date.formatted(date: .abbreviated, time: .shortened))
                                            .font(.system(size: 11))
                                            .foregroundColor(.gray)
                                    } else {
                                        Text(race.date.formatted(date: .abbreviated, time: .omitted))
                                            .font(.system(size: 11))
                                            .foregroundColor(.gray)
                                    }
                                }
                                Spacer()
                            }
                            .padding(12)
                            .frame(width: 180, alignment: .leading)
                            .background(Color(.systemGray6).opacity(0.15))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            
            if upcomingFantasyRaces.isEmpty {
                // OFF-SEASON STATE
                VStack(spacing: 16) {
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    
                    Text("No Fantasy Races This Week")
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
                // Stakes Banner
                VStack(alignment: .leading, spacing: 4) {
                    Text("THE STAKES")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(.cyan)
                        .tracking(1.5)
                    
                    Text("Pick drivers, get NXT for every win.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray)
                        .lineSpacing(2)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6).opacity(0.15))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                
                // Draft Slots
                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { index in
                        DraftSlotView(driver: fantasyViewModel.weeklyDraftPicks[index])
                            .onTapGesture {
                                if !fantasyViewModel.draftLocked {
                                    activeSlotIndex = index
                                }
                            }
                            .opacity(fantasyViewModel.draftLocked ? 0.6 : 1.0)
                    }
                }
                .padding(.horizontal, 20)
                
                // Lock In / Edit Picks Button
                if fantasyViewModel.weeklyDraftPicks.compactMap({ $0 }).count == 3 {
                    Button(action: {
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
                        HStack {
                            if fantasyViewModel.isSyncing {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.trailing, 4)
                            }
                            
                            if fantasyViewModel.draftLocked {
                                Text("EDIT PICKS (500 NXT)")
                                    .font(.system(size: 16, weight: .bold))
                                    .tracking(1.0)
                            } else {
                                Text("LOCK IN PREDICTION")
                                    .font(.system(size: 16, weight: .bold))
                                    .tracking(1.0)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            fantasyViewModel.draftLocked ? Color.orange : Color.cyan
                        )
                        .foregroundColor(fantasyViewModel.draftLocked ? .white : .black)
                        .cornerRadius(16)
                        .shadow(color: fantasyViewModel.draftLocked ? Color.orange.opacity(0.4) : Color.cyan.opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                    .disabled(fantasyViewModel.isSyncing)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .animation(.spring(), value: fantasyViewModel.draftLocked)
                }
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
        .sheet(isPresented: $showRulesSheet) {
            FantasyRulesSheet()
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
