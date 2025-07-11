import SwiftUI

struct MotorsportTheme {
    // Colors
    static let primaryColor: Color = Color("RacingRed")
    static let secondaryColor = Color.black
    static let backgroundColor = Color(red: 0.1, green: 0.1, blue: 0.1)
    
    // Font sizes
    static let titleFont = Font.title.bold()
    static let subtitleFont = Font.title2
    static let bodyFont = Font.body
    
    // Padding
    static let standardPadding: CGFloat = 16
    static let smallPadding: CGFloat = 8
    
    // Corner radius
    static let cornerRadius: CGFloat = 12
}

// View modifiers for consistent styling
extension View {
    func motorsportCardStyle() -> some View {
        self
            .background(MotorsportTheme.backgroundColor)
            .cornerRadius(MotorsportTheme.cornerRadius)
            .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
    }
    
    func motorsportButtonStyle() -> some View {
        self
            .padding()
            .background(MotorsportTheme.primaryColor)
            .foregroundColor(.white)
            .cornerRadius(MotorsportTheme.cornerRadius)
            .shadow(color: MotorsportTheme.primaryColor.opacity(0.5), radius: 5, x: 0, y: 2)
    }
}

//struct RacingBackground: View {
//    var body: some View {
//        ZStack {
//            // Gentle color blend: deep sky blue to muted indigo
//            LinearGradient(
//                gradient: Gradient(colors: [
//                    Color(red: 0.12, green: 0.18, blue: 0.35), // Soft blue
//                    Color(red: 0.18, green: 0.25, blue: 0.45)  // Indigo purple blend
//                ]),
//                startPoint: .topLeading,
//                endPoint: .bottomTrailing
//            )
//            .ignoresSafeArea()
//
//            // Subtle radial glow in center
//            RadialGradient(
//                gradient: Gradient(colors: [
//                    Color.white.opacity(0.05),
//                    Color.clear
//                ]),
//                center: .center,
//                startRadius: 80,
//                endRadius: 600
//            )
//            .blendMode(.screen)
//            .ignoresSafeArea()
//        }
//    }
//}
