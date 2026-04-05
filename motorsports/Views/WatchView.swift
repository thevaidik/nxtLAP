//
//  WatchView.swift
//  motorsports
//

import SwiftUI
import WebKit

// MARK: - YouTube embed

struct YouTubeEmbedView: UIViewRepresentable {
    /// Use either a single video id or a channel id for live stream embed.
    let videoID: String?
    let channelID: String?

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .black
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let urlString: String
        if let ch = channelID {
            urlString = "https://www.youtube.com/embed/live_stream?channel=\(ch)"
        } else if let id = videoID {
            urlString = "https://www.youtube.com/embed/\(id)?playsinline=1"
        } else {
            return
        }
        guard let url = URL(string: urlString) else { return }
        webView.load(URLRequest(url: url))
    }
}

// MARK: - Watch tab

struct WatchView: View {
    private struct LiveStream: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let channelID: String?
        let videoID: String?
    }

    private let streams: [LiveStream] = [
        LiveStream(
            title: "Formula 1",
            subtitle: "Official YouTube live when a session is broadcasting",
            channelID: "UCB_qr75-ydFVKSMM9H8WjJ",
            videoID: nil
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(streams) { stream in
                        streamCard(stream)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
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

    private func streamCard(_ stream: LiveStream) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(stream.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text(stream.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(white: 0.08))

                YouTubeEmbedView(videoID: stream.videoID, channelID: stream.channelID)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        LinearGradient(
                            colors: [.racingRed.opacity(0.45), Color.white.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.12), Color(white: 0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

#Preview {
    WatchView()
}
