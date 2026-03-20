//
//  FullScreenNewsCardView.swift
//  motorsports
//
//  Created by Antigravity on 20/03/26.
//

import SwiftUI

struct FullScreenNewsCardView: View {
    let article: NewsArticle
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top Image Section
                ZStack(alignment: .topLeading) {
                    if let imageUrl = article.imageUrl, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .overlay(ProgressView().tint(.racingRed))
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                                    .overlay(
                                        Image(systemName: "photo")
                                            .font(.system(size: 60))
                                            .foregroundColor(.gray)
                                    )
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height * 0.5)
                        .clipped()
                    } else {
                        // Fallback gradient when no image
                        LinearGradient(
                            gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(width: geometry.size.width, height: geometry.size.height * 0.5)
                    }
                    
                    // Source badge overlay on image
                    HStack {
                        Image(systemName: "link.circle.fill")
                            .font(.caption)
                        Text(article.source.uppercased())
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.racingRed)
                    .cornerRadius(20)
                    .padding(16)
                }
                
                // Content Section
                VStack(alignment: .leading, spacing: 16) {
                    // Title
                    Text(article.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    
                    // Time
                    Text(article.formattedDate)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    // Summary
                    Text(article.summary)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    // Read more button
                    Link(destination: URL(string: article.articleUrl)!) {
                        HStack {
                            Spacer()
                            Text("Read more")
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right.circle.fill")
                            Spacer()
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.vertical, 14)
                        .background(Color.racingRed)
                        .cornerRadius(12)
                    }
                    .padding(.bottom, 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(Color.black)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

#Preview {
    FullScreenNewsCardView(article: NewsArticle(
        id: "1",
        title: "Wheatley emerges as Aston Martin's preferred choice as Newey seeks to step back",
        summary: "A report says Aston Martin are looking for a new team principal so Adrian Newey can step back from the role and focus on car design. Former Red Bull sporting director Jonathan Wheatley, now at Sauber/Audi, is described as the surprise front-runner.",
        imageUrl: nil,
        articleUrl: "https://example.com",
        publishedAt: "2026-03-20T12:00:00Z",
        source: "Mirror.co.uk"
    ))
    .preferredColorScheme(.dark)
}
