//
//  StandingsView.swift
//  motorsports
//

import SwiftUI

struct StandingsView: View {
    @StateObject private var viewModel = StandingsViewModel()
    @State private var selectedTab: StandingsTab = .drivers

    enum StandingsTab: String, CaseIterable {
        case drivers = "Drivers"
        case constructors = "Constructors"
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Picker("Standings", selection: $selectedTab) {
                    ForEach(StandingsTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
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
            .navigationTitle("Standings")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
        .task { await viewModel.loadStandings() }
    }

    // MARK: - Drivers List
    private var driversList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.drivers) { driver in
                    DriverStandingRow(driver: driver)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Constructors List
    private var constructorsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.constructors) { constructor in
                    ConstructorStandingRow(constructor: constructor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - Driver Row
struct DriverStandingRow: View {
    let driver: F1DriverStanding

    var body: some View {
        HStack(spacing: 16) {
            // Position
            Text("\(driver.position)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(positionColor)
                .frame(width: 28, alignment: .center)

            // Accent bar
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

// MARK: - ViewModel
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
}
