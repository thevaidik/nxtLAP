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
    
    @AppStorage("viewedArticleIds") private var viewedArticleIdsString: String = ""
    private var viewedArticleIds: Set<String> {
        get { Set(viewedArticleIdsString.components(separatedBy: ",").filter { !$0.isEmpty }) }
        nonmutating set { viewedArticleIdsString = newValue.joined(separator: ",") }
    }
    
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
                                isViewed: group.articles.allSatisfy { viewedArticleIds.contains($0.id) },
                                onTap: {
                                    selectedStoryGroup = StoryGroup(source: group.source, articles: group.articles)
                                    var current = viewedArticleIds
                                    group.articles.forEach { current.insert($0.id) }
                                    viewedArticleIds = current
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { selectedStoryGroup != nil },
            set: { if !$0 { selectedStoryGroup = nil } }
        )) {
            if let group = selectedStoryGroup {
                StoryViewerView(
                    source: group.source,
                    articles: group.articles,
                    isPresented: Binding(
                        get: { selectedStoryGroup != nil },
                        set: { if !$0 { selectedStoryGroup = nil } }
                    ),
                    onFinish: {
                        if let currentIndex = articlesBySource.firstIndex(where: { $0.source == group.source }),
                           currentIndex + 1 < articlesBySource.count {
                            let nextGroup = articlesBySource[currentIndex + 1]
                            selectedStoryGroup = StoryGroup(source: nextGroup.source, articles: nextGroup.articles)
                            
                            var current = viewedArticleIds
                            nextGroup.articles.forEach { current.insert($0.id) }
                            viewedArticleIds = current
                        } else {
                            selectedStoryGroup = nil
                        }
                    }
                )
                .id(group.source)
            }
        }
        .onAppear {
            cleanupOldViewedArticles()
        }
        .onChange(of: newsViewModel.articles) { _ in
            cleanupOldViewedArticles()
        }
    }
    
    private func cleanupOldViewedArticles() {
        let currentArticleIds = Set(newsViewModel.articles.map { $0.id })
        let validViewedIds = viewedArticleIds.intersection(currentArticleIds)
        if validViewedIds.count != viewedArticleIds.count {
            viewedArticleIdsString = validViewedIds.joined(separator: ",")
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
    let isViewed: Bool
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
                    // Gradient ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: isViewed ? [Color.white, Color.gray.opacity(0.5)] : [Color("RacingRed"), Color("RacingRed").opacity(0.6)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 72, height: 72)
                    
                    if let imageUrl = firstArticleImageUrl, let url = URL(string: imageUrl) {
                        DownsamplingAsyncImage(url: url, targetSize: CGSize(width: 64, height: 64))
                            .frame(width: 64, height: 64)
                            .clipShape(Circle())
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
    var onFinish: (() -> Void)? = nil
    
    @State private var currentIndex: Int = 0
    @State private var progress: CGFloat = 0
    
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
                
                // Fullscreen Background Image (Blurred) + Fitted Foreground
                if let imageUrl = currentArticle.imageUrl, let url = URL(string: imageUrl) {
                    ZStack {
                        // Blurred background
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .blur(radius: 40)
                                    .scaleEffect(1.2) // Prevent edges from leaking blur
                            default:
                                Color(white: 0.1)
                            }
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        
                        // Clear fitted foreground
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            default:
                                EmptyView()
                            }
                        }
                        .frame(width: geometry.size.width)
                    }
                    .edgesIgnoringSafeArea(.all)
                } else {
                    LinearGradient(
                        gradient: Gradient(colors: [Color(white: 0.15), Color.black]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .edgesIgnoringSafeArea(.all)
                }
                
                // Merging Gradient Overlay for Readability
                LinearGradient(
                    colors: [.black.opacity(0.5), .clear, .black.opacity(0.5), .black.opacity(0.95)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                // Content Overlay
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
                                .foregroundColor(.white.opacity(0.8))
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
                    
                    Spacer()
                    
                    // Text content at the bottom
                    VStack(alignment: .leading, spacing: 12) {
                        Text(currentArticle.title)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                        
                        Text(currentArticle.summary)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                        
                        HStack {
                            // Indicator for more content
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.compact.up")
                                    .font(.caption2)
                                Text("Tap left/right or swipe down")
                                    .font(.caption2)
                            }
                            .foregroundColor(.white.opacity(0.6))
                            
                            Spacer()
                            
                            // Liquid glass Read button
                            Link(destination: URL(string: currentArticle.articleUrl)!) {
                                HStack(spacing: 4) {
                                    Text("Read")
                                        .fontWeight(.semibold)
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .font(.footnote)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(.ultraThinMaterial)
                                .cornerRadius(20)
                                .environment(\.colorScheme, .dark)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(20)
                    .padding(.bottom, 20)
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
            .task(id: currentIndex) {
                // Reset progress when index changes
                progress = 0
                
                // Modern async/await loop
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
                    
                    await MainActor.run {
                        withAnimation(.linear(duration: 0.05)) {
                            progress += 0.05 / storyDuration
                        }
                        
                        if progress >= 1.0 {
                            goToNext()
                        }
                    }
                }
            }
            .onAppear {
                currentIndex = 0
            }
        }
    }
    
    private func goToNext() {
        if currentIndex < articles.count - 1 {
            currentIndex += 1
        } else {
            if let onFinish = onFinish {
                onFinish()
            } else {
                isPresented = false
            }
        }
    }
    
    private func goToPrevious() {
        if currentIndex > 0 {
            currentIndex -= 1
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

