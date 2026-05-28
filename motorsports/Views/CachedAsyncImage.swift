import SwiftUI

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    private let url: URL
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder
    
    @State private var loadedImage: UIImage?
    
    init(url: URL, @ViewBuilder content: @escaping (Image) -> Content, @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let uiImage = loadedImage {
                content(Image(uiImage: uiImage))
            } else {
                placeholder()
                    .task {
                        await loadImage()
                    }
            }
        }
    }
    
    private func loadImage() async {
        let urlString = url.absoluteString
        
        // 1. Check Cache
        if let cached = await ImageCache.shared.image(for: urlString) {
            self.loadedImage = cached
            return
        }
        
        // 2. Download from Network
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let downloadedImage = UIImage(data: data) {
                // Save to Cache
                await ImageCache.shared.insertImage(downloadedImage, for: urlString)
                
                await MainActor.run {
                    self.loadedImage = downloadedImage
                }
            }
        } catch {
            print("❌ Failed to download image from: \(urlString)")
            print("❌ Error details: \(error.localizedDescription)")
        }
    }
}
