import SwiftUI

struct FantasyAvailabilityView: View {
    @State private var eligibleSeries: [RacingServerSeries] = []
    @State private var upcomingSeries: [RacingServerSeries] = []
    @State private var isLoading: Bool = true
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                // Futuristic dark background
                Color.black.ignoresSafeArea()
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.black]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ).ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            
                            // Header Text
                            VStack(spacing: 8) {
                                Text("FANTASY ECONOMY")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(.blue)
                                    .tracking(2)
                                
                                Text("Supported Series")
                                    .font(.system(size: 32, weight: .heavy))
                                    .foregroundColor(.white)
                                
                                Text("Supported series for fantasy economy.")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .padding(.top, 20)
                            
                            // Eligible Section
                            if !eligibleSeries.isEmpty {
                                availabilitySection(
                                    title: "Available for Fantasy",
                                    icon: "checkmark.circle.fill",
                                    color: .green,
                                    series: eligibleSeries
                                )
                            }
                            
                            // Coming Soon Section
                            if !upcomingSeries.isEmpty {
                                availabilitySection(
                                    title: "Results Not Supported Yet",
                                    icon: "xmark.circle.fill",
                                    color: .red,
                                    series: upcomingSeries
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 24))
                    }
                }
            }
        }
        .task {
            await fetchSeries()
        }
    }
    
    private func availabilitySection(title: String, icon: String, color: Color, series: [RacingServerSeries]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .padding(.leading, 8)
            
            VStack(spacing: 12) {
                ForEach(series, id: \.id) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name)
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(item.category)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray.opacity(0.5))
                            .font(.system(size: 14, weight: .bold))
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(color.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
            }
        }
    }
    
    private func fetchSeries() async {
        do {
            let fetchedSeries = try await RacingAPIService().fetchSeries()
            
            DispatchQueue.main.async {
                withAnimation {
                    // Filter based on is_fantasy_eligible
                    self.eligibleSeries = fetchedSeries.filter { $0.is_fantasy_eligible == true }
                    self.upcomingSeries = fetchedSeries.filter { $0.is_fantasy_eligible != true }
                    self.isLoading = false
                }
            }
        } catch {
            print("Failed to fetch series for availability: \(error)")
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
}
