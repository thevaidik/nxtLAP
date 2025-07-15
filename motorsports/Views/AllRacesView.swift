//  Created by Vaidik Dubey on 11/07/25.
//

import SwiftUI

struct AllRacesView: View {
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Formula 1")) {
                    RaceRow(raceName: "Monaco Grand Prix", date: "May 26, 2024")
                    RaceRow(raceName: "British Grand Prix", date: "July 7, 2024")
                    RaceRow(raceName: "Italian Grand Prix", date: "September 1, 2024")
                }
                
                Section(header: Text("MotoGP")) {
                    RaceRow(raceName: "Dutch TT", date: "June 30, 2024")
                    RaceRow(raceName: "Austrian GP", date: "August 18, 2024")
                }
                
                Section(header: Text("WRC")) {
                    RaceRow(raceName: "Rally Finland", date: "August 1-4, 2024")
                    RaceRow(raceName: "Rally Chile", date: "September 26-29, 2024")
                }
            }
            .navigationTitle("All Races")
        }
    }
}

struct RaceRow: View {
    var raceName: String
    var date: String
    
    var body: some View {
        HStack {
            Image(systemName: "flag.fill")
                .foregroundColor(.racingRed)
            
            VStack(alignment: .leading) {
                Text(raceName)
                    .font(.headline)
                Text(date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AllRacesView()
}
