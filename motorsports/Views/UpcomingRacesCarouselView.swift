import SwiftUI

struct UpcomingRacesCarouselView: View {
    @EnvironmentObject var dataService: RacingDataService
    
    // Show races from today onwards, up to next 10 races
    private var upcomingRaces: [Race] {
        let sorted = dataService.upcomingRaces.sorted { $0.date < $1.date }
        return Array(sorted.prefix(10))
    }
    
    var body: some View {
        if !upcomingRaces.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Upcoming Races")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                
                VStack(spacing: 12) {
                    ForEach(upcomingRaces) { race in
                        HStack(spacing: 16) {
                            // Date / Time Box
                            VStack(spacing: 4) {
                                Text(race.date.formatted(.dateTime.month(.abbreviated).day()))
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                
                                if race.hasExactTime {
                                    Text(race.date.formatted(date: .omitted, time: .shortened))
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.gray)
                                }
                            }
                            .frame(width: 60)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)
                            
                            // Race Details
                            VStack(alignment: .leading, spacing: 6) {
                                Text(race.series.uppercased())
                                    .font(.system(size: 10, weight: .heavy))
                                    .foregroundColor(seriesColor(for: race.series))
                                
                                Text(race.name)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                                
                                if let circuit = race.circuit {
                                    Text(circuit)
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                        .lineLimit(1)
                                }
                            }
                            Spacer()
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
                    }
                }
            }
        }
    }
    
    private func seriesColor(for series: String) -> Color {
        switch series.lowercased() {
        case "formula1": return .red
        case "indycar": return .blue
        case "motogp": return .orange
        case "nascar": return .yellow
        case "wec": return .green
        case "wrc": return .purple
        case "formulae": return .teal
        default: return .gray
        }
    }
}
