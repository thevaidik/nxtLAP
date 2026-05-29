//
//  StandingsView.swift
//  motorsports
//

import SwiftUI

struct StandingsView: View {
    @EnvironmentObject var dataService: RacingDataService
    
    enum CalendarWeekSegment: String, CaseIterable {
        case thisWeek = "This week"
        case nextWeek = "Next week"
        case past = "Past"
    }
    
    @State private var weekSegment: CalendarWeekSegment = .thisWeek
    @State private var showSettings = false
    
    private func isInThisWeek(_ date: Date) -> Bool {
        Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear)
    }
    
    private func isInNextWeek(_ date: Date) -> Bool {
        let cal = Calendar.current
        guard let thisWeekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())),
              let nextWeekStart = cal.date(byAdding: .weekOfYear, value: 1, to: thisWeekStart) else { return false }
        return cal.isDate(date, equalTo: nextWeekStart, toGranularity: .weekOfYear)
    }
    
    private var upcomingWeekendGroups: [WeekendGroup] {
        let allUpcoming = dataService.upcomingRacesForStarredSeries
        guard !allUpcoming.isEmpty else { return [] }
        
        var groups: [String: [Race]] = [:]
        for race in allUpcoming {
            let venueKey: String
            if let circuit = race.circuit, !circuit.isEmpty {
                venueKey = circuit
            } else {
                let words = race.name.components(separatedBy: " ")
                venueKey = words.prefix(2).joined(separator: " ")
            }
            let key = "\(race.series)_\(venueKey)"
            groups[key, default: []].append(race)
        }
        
        let mapped = groups.compactMap { _, sessions -> WeekendGroup? in
            let sortedSessions = sessions.sorted { $0.date < $1.date }
            guard let lastForTitle = sortedSessions.last,
                  let firstForMeta = sortedSessions.first else { return nil }
            let components = lastForTitle.name.components(separatedBy: " - ")
            let displayName = components.first ?? lastForTitle.name
            return WeekendGroup(
                weekendName: displayName,
                location: firstForMeta.location,
                sessions: sortedSessions,
                series: firstForMeta.series
            )
        }
        
        return mapped.sorted {
            let d1 = $0.sessions.first?.date ?? Date.distantFuture
            let d2 = $1.sessions.first?.date ?? Date.distantFuture
            return d1 < d2
        }
    }
    
    private var pastWeekendGroups: [WeekendGroup] {
        let allPast = dataService.pastRacesForStarredSeries
        guard !allPast.isEmpty else { return [] }
        
        var groups: [String: [Race]] = [:]
        for race in allPast {
            let venueKey: String
            if let circuit = race.circuit, !circuit.isEmpty {
                venueKey = circuit
            } else {
                let words = race.name.components(separatedBy: " ")
                venueKey = words.prefix(2).joined(separator: " ")
            }
            let key = "\(race.series)_\(venueKey)"
            groups[key, default: []].append(race)
        }
        
        let mapped = groups.compactMap { _, sessions -> WeekendGroup? in
            let sortedSessions = sessions.sorted { $0.date > $1.date } // sort descending
            guard let lastForTitle = sortedSessions.last,
                  let firstForMeta = sortedSessions.first else { return nil }
            let components = lastForTitle.name.components(separatedBy: " - ")
            let displayName = components.first ?? lastForTitle.name
            return WeekendGroup(
                weekendName: displayName,
                location: firstForMeta.location,
                sessions: sortedSessions,
                series: firstForMeta.series
            )
        }
        
        return mapped.sorted {
            let d1 = $0.sessions.first?.date ?? Date.distantPast
            let d2 = $1.sessions.first?.date ?? Date.distantPast
            return d1 > d2 // most recent past races first
        }
    }
    
    private var thisWeekGroups: [WeekendGroup] {
        upcomingWeekendGroups.filter { g in
            guard let start = g.sessions.map(\.date).min() else { return false }
            return isInThisWeek(start)
        }
    }
    
    private var nextWeekGroups: [WeekendGroup] {
        upcomingWeekendGroups.filter { g in
            guard let start = g.sessions.map(\.date).min() else { return false }
            return isInNextWeek(start)
        }
    }
    
    private var activeWeekGroups: [WeekendGroup] {
        switch weekSegment {
        case .thisWeek: return thisWeekGroups
        case .nextWeek: return nextWeekGroups
        case .past: return pastWeekendGroups
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Calendar Title & Manage Button
                    HStack(alignment: .center, spacing: 12) {
                        Text("Calendar")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                        
                        Button(action: { showSettings = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 11, weight: .bold))
                                Text("Manage Races")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundColor(.racingRed)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(Color.racingRed.opacity(0.15))
                            )
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // Standings Navigation Button
                    NavigationLink(destination: StandingsListView()) {
                        HStack(spacing: 12) {
                            Image(systemName: "list.number")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.racingRed)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("F1 Standings")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text("Drivers & Constructors Championship")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.05))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Divider
                    Divider()
                        .background(Color.white.opacity(0.1))
                        .padding(.horizontal, 20)

                    // Schedule UI
                    if dataService.isLoadingData && dataService.upcomingRaces.isEmpty {
                        RacingLoadingView()
                            .padding(.top, 40)
                    } else if dataService.starredSeriesList.isEmpty {
                        emptyStateView
                    } else {
                        racesContentView
                    }
                }
                .padding(.bottom, 40)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 32) {
            Spacer()
                .frame(height: 40)
            
            // Animated Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .racingRed.opacity(0.2),
                                .racingRed.opacity(0.05)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.racingRed, .orange]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 12) {
                Text("No Favorites Yet")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Start by adding your favorite racing series to see upcoming races here")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .lineSpacing(4)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Races Content
    private var racesContentView: some View {
        VStack(spacing: 28) {
            if upcomingWeekendGroups.isEmpty {
                Text("No upcoming sessions for your favorite series right now.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
            }
            
            if thisWeekGroups.isEmpty && nextWeekGroups.isEmpty && !upcomingWeekendGroups.isEmpty && weekSegment != .past {
                Text("no races - but these are upcoming later")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            if (!upcomingWeekendGroups.isEmpty || !pastWeekendGroups.isEmpty) && (!thisWeekGroups.isEmpty || !nextWeekGroups.isEmpty || !pastWeekendGroups.isEmpty) {
                CustomSegmentedControl(selection: $weekSegment, options: CalendarWeekSegment.allCases)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
            }
            
            if !activeWeekGroups.isEmpty {
                LazyVStack(spacing: 14) {
                    ForEach(Array(activeWeekGroups.enumerated()), id: \.element.id) { index, group in
                        UpcomingWeekendCard(
                            group: group,
                            prominence: index == 0 ? .primary : .compact
                        )
                    }
                }
                .padding(.horizontal, 20)
            } else if (!thisWeekGroups.isEmpty || !nextWeekGroups.isEmpty || !pastWeekendGroups.isEmpty) {
                Text(emptyText(for: weekSegment))
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
            }
        }
    }
    
    private func emptyText(for segment: CalendarWeekSegment) -> String {
        switch segment {
        case .thisWeek: return "No races this week."
        case .nextWeek: return "No races next week."
        case .past: return "No past races yet."
        }
    }
}

// MARK: - Old Standings List View
struct StandingsListView: View {
    @StateObject private var viewModel = StandingsViewModel()
    @State private var selectedTab: StandingsTab = .drivers

    enum StandingsTab: String, CaseIterable {
        case drivers = "Drivers"
        case constructors = "Constructors"
    }

    var body: some View {
        VStack(spacing: 0) {
            CustomSegmentedControl(selection: $selectedTab, options: StandingsTab.allCases)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

            if viewModel.isLoading {
                Spacer()
                ProgressView()
                    .tint(.racingRed)
                Spacer()
            } else if let error = viewModel.errorMessage {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 36))
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Button("Retry") {
                        Task { await viewModel.loadStandings() }
                    }
                    .foregroundColor(.racingRed)
                }
                Spacer()
            } else {
                if selectedTab == .drivers {
                    driversList
                } else {
                    constructorsList
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("F1 Standings")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .task { await viewModel.loadStandings() }
    }

    private var driversList: some View {
        ScrollView {
            HStack {
                Spacer(minLength: 0)
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.drivers) { driver in
                        DriverStandingRow(driver: driver)
                    }
                }
                .frame(maxWidth: 800)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private var constructorsList: some View {
        ScrollView {
            HStack {
                Spacer(minLength: 0)
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.constructors) { constructor in
                        ConstructorStandingRow(constructor: constructor)
                    }
                }
                .frame(maxWidth: 800)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - Models and Rows from HomeView/StandingsView
struct WeekendGroup: Identifiable {
    let id = UUID()
    let weekendName: String
    let location: String
    let sessions: [Race]
    let series: String
}

enum WeekendCardProminence {
    case primary
    case compact
}

struct UpcomingWeekendCard: View {
    let group: WeekendGroup
    var prominence: WeekendCardProminence = .primary
    
    private var venueLine: String {
        let loc = group.location
        if let c = group.sessions.first?.circuit, !c.isEmpty {
            return "\(loc) · \(c)"
        }
        return loc
    }
    
    private var isPrimary: Bool { prominence == .primary }
    
    var body: some View {
        let corner: CGFloat = isPrimary ? 20 : 16
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: isPrimary ? 10 : 6) {
                HStack {
                    Text(group.series)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.95))
                        .padding(.horizontal, isPrimary ? 10 : 8)
                        .padding(.vertical, isPrimary ? 5 : 4)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.08))
                                .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
                        )
                    Spacer()
                }
                
                Text(group.weekendName)
                    .font(isPrimary ? .title2 : .headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(isPrimary ? .caption : .caption2)
                        .foregroundColor(.racingRed.opacity(0.9))
                    Text(venueLine)
                        .font(isPrimary ? .subheadline : .caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(isPrimary ? 18 : 14)
            
            VStack(spacing: isPrimary ? 10 : 8) {
                ForEach(group.sessions) { session in
                    SessionRow(race: session, compact: !isPrimary)
                }
            }
            .padding(.horizontal, isPrimary ? 14 : 10)
            .padding(.bottom, isPrimary ? 16 : 12)
        }
        .background(
            RoundedRectangle(cornerRadius: corner)
                .fill(
                    LinearGradient(
                        colors: [Color(white: isPrimary ? 0.14 : 0.11), Color(white: 0.07)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: corner)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(isPrimary ? 0.14 : 0.1), .racingRed.opacity(isPrimary ? 0.28 : 0.18)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(isPrimary ? 0.35 : 0.22), radius: isPrimary ? 12 : 6, x: 0, y: isPrimary ? 6 : 3)
    }
}

struct SessionRow: View {
    let race: Race
    var compact: Bool = false
    
    private var sessionColor: Color {
        let name = race.name.uppercased()
        if name.contains("SPRINT") { return .orange }
        if name.contains("PRACTICE 1") || name.contains("FP1") { return .racingRed }
        if name.contains("PRACTICE 2") || name.contains("FP2") { return .purple }
        if name.contains("PRACTICE 3") || name.contains("FP3") { return .blue }
        if name.contains("QUALIFYING") || name.contains("QUALI") { return .green }
        
        let colors: [Color] = [.racingRed, .blue, .green, .orange, .purple, .pink, .cyan, .mint, .indigo, .teal]
        let index = abs(race.name.hashValue) % colors.count
        return colors[index]
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: compact ? 8 : 12) {
            VStack(alignment: .leading, spacing: compact ? 4 : 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(race.name)
                        .font(compact ? .caption : .subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer(minLength: 8)
                    
                    Text(countdownText(for: race))
                        .font(compact ? .caption2 : .caption)
                        .fontWeight(.semibold)
                        .foregroundColor(sessionColor)
                        .padding(.horizontal, compact ? 6 : 8)
                        .padding(.vertical, compact ? 3 : 4)
                        .background(Capsule().fill(sessionColor.opacity(0.18)))
                }
                
                Text(sessionWhenString(race))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, compact ? 8 : 10)
        .padding(.horizontal, compact ? 10 : 12)
        .background(
            RoundedRectangle(cornerRadius: compact ? 10 : 12)
                .fill(Color.white.opacity(0.04))
        )
    }
    
    private func sessionWhenString(_ race: Race) -> String {
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE, MMM d"
        var s = dayFormatter.string(from: race.date)
        if race.hasExactTime {
            let timeFormatter = DateFormatter()
            timeFormatter.dateStyle = .none
            timeFormatter.timeStyle = .short
            s += " · " + timeFormatter.string(from: race.date)
        }
        return s
    }
    
    private func countdownText(for race: Race) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(race.date) {
            if race.hasExactTime {
                if race.date < Date() {
                    return "Past"
                }
                let components = calendar.dateComponents([.hour], from: Date(), to: race.date)
                let hours = components.hour ?? 0
                return hours == 0 ? "Soon" : "in \(hours)h"
            } else {
                return "Today"
            }
        } else if calendar.isDateInTomorrow(race.date) {
            return "Tomorrow"
        } else if let dayCount = calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()), to: calendar.startOfDay(for: race.date)).day, dayCount > 0 {
            return "in \(dayCount)d"
        } else {
            return "Past"
        }
    }
}

func seriesColor(for seriesName: String) -> Color {
    let colors: [Color] = [.red, .blue, .green, .orange, .purple, .cyan, .pink, .indigo, .mint, .yellow]
    let index = abs(seriesName.hashValue) % colors.count
    return colors[index]
}

// Standings Row Definitions
struct DriverStandingRow: View {
    let driver: F1DriverStanding

    var body: some View {
        HStack(spacing: 16) {
            Text("\(driver.position)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(positionColor)
                .frame(width: 28, alignment: .center)

            Rectangle()
                .fill(positionColor.opacity(0.8))
                .frame(width: 3, height: 40)
                .cornerRadius(2)

            VStack(alignment: .leading, spacing: 3) {
                Text(driverName(for: driver.driverNumber))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Text("#\(driver.driverNumber)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Text("\(Int(driver.points)) pts")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 35/255, green: 35/255, blue: 35/255),
                        Color(red: 20/255, green: 20/255, blue: 20/255)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(white: 0.2), lineWidth: 1)
                )
        )
    }

    func driverName(for number: Int) -> String {
        switch number {
        case 1: return "Max Verstappen"
        case 3: return "Daniel Ricciardo"
        case 6: return "Nicholas Latifi"
        case 10: return "Pierre Gasly"
        case 11: return "Sergio Perez"
        case 12: return "Andrea Kimi Antonelli"
        case 14: return "Fernando Alonso"
        case 16: return "Charles Leclerc"
        case 18: return "Lance Stroll"
        case 23: return "Alexander Albon"
        case 27: return "Nico Hulkenberg"
        case 30: return "Liam Lawson"
        case 31: return "Esteban Ocon"
        case 41: return "Jack Doohan"
        case 43: return "Franco Colapinto"
        case 44: return "Lewis Hamilton"
        case 55: return "Carlos Sainz"
        case 63: return "George Russell"
        case 77: return "Valtteri Bottas"
        case 81: return "Oscar Piastri"
        case 87: return "Isack Hadjar"
        default: return "Driver #\(number)"
        }
    }

    var positionColor: Color {
        switch driver.position {
        case 1: return .yellow
        case 2: return Color(white: 0.75)
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return .gray
        }
    }
}

struct ConstructorStandingRow: View {
    let constructor: F1ConstructorStanding

    var body: some View {
        HStack(spacing: 16) {
            Text("\(constructor.position)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(positionColor)
                .frame(width: 28, alignment: .center)

            Rectangle()
                .fill(positionColor.opacity(0.8))
                .frame(width: 3, height: 40)
                .cornerRadius(2)

            Text(constructor.teamName)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Spacer()

            Text("\(Int(constructor.points)) pts")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 35/255, green: 35/255, blue: 35/255),
                        Color(red: 20/255, green: 20/255, blue: 20/255)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(white: 0.2), lineWidth: 1)
                )
        )
    }

    var positionColor: Color {
        switch constructor.position {
        case 1: return .yellow
        case 2: return Color(white: 0.75)
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return .gray
        }
    }
}

@MainActor
class StandingsViewModel: ObservableObject {
    @Published var drivers: [F1DriverStanding] = []
    @Published var constructors: [F1ConstructorStanding] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private let apiService = RacingAPIService()

    func loadStandings() async {
        isLoading = true
        errorMessage = nil
        do {
            let standings = try await apiService.fetchF1Standings()
            drivers = standings.drivers
            constructors = standings.constructors
        } catch {
            errorMessage = "Could not load standings. \(error.localizedDescription)"
        }
        isLoading = false
    }
}

#Preview {
    StandingsView()
        .environmentObject(RacingDataService())
}
