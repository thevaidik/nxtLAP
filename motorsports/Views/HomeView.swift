//  Created by Vaidik Dubey on 11/07/25.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        ZStack{
            //RacingBackground() //make background later
            VStack {
                Text("NxtLAP")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Spacer()
                
                Image(systemName: "flag.checkered.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.racingRed)
                
                Text("Welcome to NxtLAP")
                    .font(.title2)
                    .padding()
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            
        }
        
    }
}

#Preview {
    HomeView()
}
