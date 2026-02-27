import SwiftUI

struct RacingLoadingView: View {
    @State private var lightStates = [false, false, false, false, false]
    @State private var goGreen = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
                .frame(height: 60)
            
            Text("PREPARING THE GRID")
                .font(.headline)
                .fontWeight(.black)
                .foregroundColor(.gray)
                .tracking(4)
            
            HStack(spacing: 16) {
                ForEach(0..<5) { index in
                    VStack(spacing: 8) {
                        Circle()
                            .fill(lightStates[index] ? Color.red : Color(white: 0.15))
                            .shadow(color: lightStates[index] ? .red : .clear, radius: 8, x: 0, y: 0)
                            .frame(width: 32, height: 32)
                        
                        Circle()
                            .fill(goGreen ? Color.green : Color(white: 0.15))
                            .shadow(color: goGreen ? .green : .clear, radius: 8, x: 0, y: 0)
                            .frame(width: 32, height: 32)
                    }
                    .padding(8)
                    .background(Color(white: 0.05))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(white: 0.2), lineWidth: 1)
                    )
                }
            }
            .padding(20)
            .background(Color.black)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(white: 0.1), lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 10)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Reset states
        lightStates = [false, false, false, false, false]
        goGreen = false
        
        // Turn on red lights one by one
        for i in 0..<5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i + 1) * 0.15) {
                withAnimation(.easeIn(duration: 0.1)) {
                    lightStates[i] = true
                }
            }
        }
        
        // All red lights off, turn green lights on
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeIn(duration: 0.1)) {
                lightStates = [false, false, false, false, false]
                goGreen = true
            }
        }
        
        // Restart animation after a pause if still loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            startAnimation()
        }
    }
}

#Preview {
    RacingLoadingView()
        .preferredColorScheme(.dark)
}
