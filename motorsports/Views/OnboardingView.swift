import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var dataService: RacingDataService
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    @State private var localSelectedSeries: Set<String> = []
    
    let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 16)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Text("Welcome to NxtLAP")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 40)
                
                Text("Select the racing series you follow to personalize your dashboard. You must pick at least one.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.bottom, 32)
            
            // Series Grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(dataService.allSeries) { series in
                        SeriesSelectionCard(
                            series: series,
                            isSelected: localSelectedSeries.contains(series.shortName)
                        ) {
                            toggleSelection(for: series.shortName)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            
            // Bottom Action Bar
            VStack {
                Button(action: finishOnboarding) {
                    Text("Continue")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(localSelectedSeries.isEmpty ? .gray : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(localSelectedSeries.isEmpty ? Color.gray.opacity(0.3) : Color.racingRed)
                        )
                }
                .disabled(localSelectedSeries.isEmpty)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(
                Rectangle()
                    .fill(Color.black.opacity(0.8))
                    .ignoresSafeArea()
            )
        }
        .background(Color.black.ignoresSafeArea())
    }
    
    private func toggleSelection(for seriesShortName: String) {
        if localSelectedSeries.contains(seriesShortName) {
            localSelectedSeries.remove(seriesShortName)
        } else {
            localSelectedSeries.insert(seriesShortName)
        }
    }
    
    private func finishOnboarding() {
        // Save the selected series to the data service
        for series in localSelectedSeries {
            if !dataService.isSeriesStarred(series) {
                dataService.toggleStarredSeries(series)
            }
        }
        
        // This triggers the view transition in ContentView
        withAnimation(.spring) {
            hasSeenOnboarding = true
        }
    }
}

struct SeriesSelectionCard: View {
    let series: RacingSeries
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(series.category.colorValue.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: series.iconName)
                        .font(.system(size: 24))
                        .foregroundColor(series.category.colorValue)
                }
                
                VStack(spacing: 4) {
                    Text(series.shortName)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(series.name)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? series.category.colorValue.opacity(0.15) : Color(.systemGray6).opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? series.category.colorValue : Color.clear, lineWidth: 2)
                    )
            )
            // Add a subtle scale effect when selected
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        // Button style plain to avoid default button opacity changes on tap
        .buttonStyle(.plain)
    }
}

// Extension to map the string color from the enum to an actual SwiftUI Color
extension RacingCategory {
    var colorValue: Color {
        switch self.color {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "red": return .red
        case "yellow": return .yellow
        default: return .gray
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(RacingDataService())
}
