import SwiftUI

struct CustomSegmentedControl<T: Hashable & RawRepresentable>: View where T.RawValue == String {
    @Binding var selection: T
    let options: [T]
    
    @Namespace private var animation
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    selection = option
                    HapticManager.shared.trigger(.light)
                }) {
                    Text(option.rawValue)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(selection == option ? .white : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            ZStack {
                                if selection == option {
                                    SegmentPuck()
                                        .matchedGeometryEffect(id: "PUCK", in: animation)
                                }
                            }
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selection)
        .padding(4)
        .background(Color(white: 0.08))
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

struct SegmentPuck: View {
    var body: some View {
        Capsule()
            .fill(Color(white: 0.18))
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}
