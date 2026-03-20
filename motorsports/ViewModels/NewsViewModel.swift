//
//  NewsViewModel.swift
//  motorsports
//
//  Created by Antigravity on 20/03/26.
//

import SwiftUI
import Combine

@MainActor
class NewsViewModel: ObservableObject {
    @Published var articles: [NewsArticle] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let newsService = NewsService()
    
    func fetchNews() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedArticles = try await newsService.fetchNews()
            // Deduplicate if needed (though server should handle it)
            self.articles = fetchedArticles
        } catch {
            print("❌ Error fetching news: \(error)")
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func refresh() async {
        // Same as fetch but could be used for specific refresh logic
        await fetchNews()
    }
}
