//
//  NewsStoriesView.swift
//  motorsports
//
//  Created by Vaidik Dubey on 08/04/26.
//

import SwiftUI

struct NewsStoriesView: View {
    @ObservedObject var newsViewModel: NewsViewModel
    @State private var selectedStoryGroup: StoryGroup? = nil
    
    // Group articles by source
    private var articlesBySource: [(source: String, articles: [NewsArticle])] {
        let grouped = Dictionary(grouping: newsViewModel.articles) { $0.source }
        return grouped.map { (source: $0.key, articles: $0.value) }
            .sorted { $0.source < $1.source }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if newsViewModel.isLoading && newsViewModel.articles.isEmpty {
                // Loading skeleton
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(0..<5) { _ in
                            StoryCircleSkeleton()
                        }
                    }
                    .padding(.horizontal, 20)
                }
            } else if !articlesBySource.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(articlesBySource, id: \.source) { group in
                            StoryCircle(
                                source: group.source,
                                articles: group.articles,
                                onTap: {
                                    selectedStoryGroup = StoryGroup(source: group.source, articles: group.articles)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .sheet(item: $selectedStoryGroup) { group in
            StoryViewerView(
                source: group.source,
                articles: group.articles,
                isPresented: Binding(
                    get: { selectedStoryGroup != nil },
                    set: { if !$0 { selectedStoryGroup = nil } }
                )
            )
        }
    }
}

// Helper struct for sheet presentation
struct StoryGroup: Identifiable {
    let id = UUID()
    let source: String
    let articles: [NewsArticle]
}

// MARK: - Story Circle (Instagram style)
struct StoryCircle: View {
    let source: String
    let articles: [NewsArticle]
    let onTap: () -> Void
    
    private var displayName: String {
        // Clean up source name for display
        let cleaned = source
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "www.", with: "")
        
        if let dotIndex = cleaned.firstIndex(of: ".") {
            return String(cleaned.prefix(upTo: dotIndex))
        }
        return cleaned
    }
    
    private var initial: String {
        displayName.prefix(1).uppercased()
    }
    
    private var ringColor: Color {
        return Color("RacingRed")
    }
    
    private var firstArticleImageUrl: String? {
        articles.first?.imageUrl
    }
    
    var body: some View {
        VStack(spacing: 6) {
            Button(action: onTap) {
                ZStack {
                    // Gradient ring (unread story style) - always red
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color("RacingRed"), Color("RacingRed").opacity(0.6)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 72, height: 72)
                    
                    // Inner circle with article image or fallback
                    if let imageUrl = firstArticleImageUrl, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                Circle()
                                    .fill(Color(white: 0.12))
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .clipShape(Circle())
                            case .failure:
                                Circle()
                                    .fill(Color(white: 0.12))
                                    .overlay(
                                        Text(initial)
                                            .font(.system(size: 28, weight: .bold))
                                            .foregroundColor(Color("RacingRed"))
                                    )
                            @unknown default:
                                Circle()
                                    .fill(Color(white: 0.12))
                            }
                        }
                        .frame(width: 64, height: 64)
                    } else {
                        Circle()
                            .fill(Color(white: 0.12))
                            .frame(width: 64, height: 64)
                            .overlay(
                                Text(initial)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(Color("RacingRed"))
                            )
                    }
                    
                    // Small dot showing article count
                    if articles.count > 1 {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                ZStack {
                                    Circle()
                                        .fill(Color.black)
                                        .frame(width: 22, height: 22)
                                    Circle()
                                        .fill(Color("RacingRed"))
                                        .frame(width: 18, height: 18)
                                        .overlay(
                                            Text("\(articles.count)")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                }
                            }
                        }
                        .frame(width: 72, height: 72)
                    }
                }
            }
            
            Text(displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(width: 80)
        }
    }
}

// MARK: - Story Circle Skeleton (loading state)
struct StoryCircleSkeleton: View {
    var body: some View {
        VStack(spacing: 6) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 72, height: 72)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 12)
        }
    }
}

// MARK: - Story Viewer (full screen story view)
struct StoryViewerView: View {
    let source: String
    let articles: [NewsArticle]
    @Binding var isPresented: Bool
    
    @State private var currentIndex = 0
    @State private var progress: CGFloat = 0
    @State private var timer: Timer?
    
    private let storyDuration: TimeInterval = 5.0
    
    private var currentArticle: NewsArticle {
        articles[currentIndex]
    }
    
    private var displayName: String {
        let cleaned = source
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "www.", with: "")
        
        if let dotIndex = cleaned.firstIndex(of: ".") {
            return String(cleaned.prefix(upTo: dotIndex))
        }
        return cleaned
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                // Content
                VStack(spacing: 0) {
                    // Progress bars
                    HStack(spacing: 4) {
                        ForEach(0..<articles.count, id: \.self) { index in
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.3))
                                        .cornerRadius(2)
                                    
                                    if index < currentIndex {
                                        Rectangle()
                                            .fill(Color.white)
                                            .cornerRadius(2)
                                    } else if index == currentIndex {
                                        Rectangle()
                                            .fill(Color.white)
                                            .cornerRadius(2)
                                            .frame(width: geo.size.width * progress)
                                    }
                                }
                            }
                            .frame(height: 3)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                    
                    // Header
                    HStack {
                        // Source avatar
                        Circle()
                            .fill(Color(white: 0.2))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Text(displayName.prefix(1).uppercased())
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color("RacingRed"))
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(displayName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text(currentArticle.formattedDate)
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        // Close button
                        Button(action: { isPresented = false }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(8)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    
                    // Article content
                    ScrollView {
                        VStack(spacing: 0) {
                            // Image
                            if let imageUrl = currentArticle.imageUrl, let url = URL(string: imageUrl) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.2))
                                            .overlay(ProgressView().tint(Color("RacingRed")))
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    case .failure:
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.1))
                                            .overlay(
                                                Image(systemName: "photo")
                                                    .font(.system(size: 40))
                                                    .foregroundColor(.gray)
                                            )
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                .frame(height: 250)
                                .clipped()
                            } else {
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .frame(height: 200)
                            }
                            
                            // Text content
                            VStack(alignment: .leading, spacing: 12) {
                                Text(currentArticle.title)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .lineLimit(3)
                                
                                Text(currentArticle.summary)
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.85))
                                    .lineLimit(10)
                                
                                Link(destination: URL(string: currentArticle.articleUrl)!) {
                                    HStack {
                                        Spacer()
                                        Text("Read Full Article")
                                            .fontWeight(.semibold)
                                        Image(systemName: "arrow.up.right")
                                        Spacer()
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 12)
                                    .background(Color("RacingRed"))
                                    .cornerRadius(10)
                                }
                                .padding(.top, 8)
                            }
                            .padding(16)
                            .padding(.bottom, 30)
                        }
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { location in
                    let screenWidth = geometry.size.width
                    if location.x < screenWidth / 2 {
                        goToPrevious()
                    } else {
                        goToNext()
                    }
                }
            }
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.height > 100 {
                            isPresented = false
                        }
                    }
            )
            .onAppear {
                currentIndex = 0
                progress = 0
                startTimer()
            }
            .onDisappear {
                stopTimer()
            }
        }
    }
    
    private func startTimer() {
        progress = 0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            withAnimation(.linear(duration: 0.05)) {
                progress += 0.05 / storyDuration
            }
            
            if progress >= 1.0 {
                goToNext()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func goToNext() {
        stopTimer()
        if currentIndex < articles.count - 1 {
            currentIndex += 1
            startTimer()
        } else {
            isPresented = false
        }
    }
    
    private func goToPrevious() {
        stopTimer()
        if currentIndex > 0 {
            currentIndex -= 1
            startTimer()
        }
    }
}    
    //#Preview {
    //    let viewModel = NewsViewModel()
    //    viewModel.articles = [
    //        NewsArticle(
    //            id: "1",
    //            title: "F1 News",
    //            summary: "Summary here",
    //            imageUrl: nil,
    //            articleUrl: "https://example.com",
    //            publishedAt: "2026-04-08T10:00:00Z",
    //            source: "bbc.com"
    //        ),
    //        NewsArticle(
    //            id: "2",
    //            title: "Racing Update",
    //            summary: "Another summary",
    //            imageUrl: nil,
    //            articleUrl: "https://example.com",
    //            publishedAt: "2026-04-08T09:00:00Z",
    //            source: "espn.com"
    //        )
    //    ]
    //
    //    NewsStoriesView(newsViewModel: viewModel)
    //        .preferredColorScheme(.dark)
    //}

