//
//  WatchView.swift
//  motorsports
//

import SwiftUI

struct WatchView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(
                                LinearGradient(
                                    colors: [Color(white: 0.13), Color(white: 0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .aspectRatio(16 / 9, contentMode: .fit)

                        VStack(spacing: 10) {
                            Image(systemName: "play.rectangle.fill")
                                .font(.system(size: 44, weight: .semibold))
                                .foregroundColor(.racingRed)
                            Text("Coming Soon")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text("Live race streaming will be available here.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color(white: 0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(
                            LinearGradient(
                                colors: [.racingRed.opacity(0.35), Color.white.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .padding(.horizontal, 16)

                Spacer(minLength: 0)
            }
            .background(
                LinearGradient(
                    colors: [Color.black, Color(white: 0.06)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Watch")
            .navigationBarTitleDisplayMode(.large)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    WatchView()
}
