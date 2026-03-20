//
//  NewsView.swift
//  motorsports
//
//  Created by Antigravity on 20/03/26.
//

import SwiftUI

struct NewsView: View {
    @StateObject private var viewModel = NewsViewModel()
    @State private var currentIndex = 0
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if viewModel.isLoading && viewModel.articles.isEmpty {
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .racingRed))
                        .scaleEffect(1.5)
                    Text("Loading latest news...")
                        .foregroundColor(.secondary)
                        .padding(.top)
                }
            } else if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.racingRed)
                    Text(errorMessage)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    Button(action: {
                        Task {
                            await viewModel.fetchNews()
                        }
                    }) {
                        Text("Retry")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Color.racingRed)
                            .cornerRadius(8)
                    }
                }
                .padding()
            } else if !viewModel.articles.isEmpty {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.articles) { article in
                            FullScreenNewsCardView(article: article)
                                .containerRelativeFrame(.vertical)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .ignoresSafeArea()
            }
        }
        .task {
            if viewModel.articles.isEmpty {
                await viewModel.fetchNews()
            }
        }
    }
}

#Preview {
    NewsView()
        .preferredColorScheme(.dark)
}
