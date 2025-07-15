import SwiftUI

//  Created by Vaidik Dubey on 11/07/25.
//

struct MyRacesView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    FeaturedRaceCard(
                        raceName: "Monaco Grand Prix",
                        series: "Formula 1",
                        date: "May 26, 2024",
                        imageName: "flag.checkered"
                    )
                    
                    FeaturedRaceCard(
                        raceName: "Indianapolis 500",
                        series: "IndyCar",
                        date: "May 26, 2024",
                        imageName: "flag.checkered"
                    )
                    
                    FeaturedRaceCard(
                        raceName: "24 Hours of Le Mans",
                        series: "WEC",
                        date: "June 15-16, 2024",
                        imageName: "flag.checkered"
                    )
                    
                    FeaturedRaceCard(
                        raceName: "Daytona 500",
                        series: "NASCAR",
                        date: "February 16, 2025",
                        imageName: "flag.checkered"
                    )
                }
                .padding()
            }
            .navigationTitle("My Races")
        }
    }
}

struct FeaturedRaceCard: View {
    var raceName: String
    var series: String
    var date: String
    var imageName: String
    
    var body: some View {
        VStack {
            ZStack(alignment: .bottomLeading) {
                Rectangle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.racingRed, .black]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(height: 150)
                    .cornerRadius(12)
                
                HStack {
                    Image(systemName: imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .foregroundColor(.white)
                        .padding(.leading)
                    
                    VStack(alignment: .leading) {
                        Text(raceName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(series)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text(date)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding()
                }
            }
        }
    }
}

#Preview {
    MyRacesView()
}
