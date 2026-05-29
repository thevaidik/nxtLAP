import Foundation
import UIKit

actor ImageCache {
    static let shared = ImageCache()
    
    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    
    private var cacheDirectory: URL {
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        return urls[0].appendingPathComponent("NxtLAPImageCache")
    }
    
    private init() {
        memoryCache.countLimit = 100 // Prevent memory bloating
        
        // Ensure cache directory exists
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }
    
    func image(for urlString: String) -> UIImage? {
        let key = NSString(string: urlString)
        
        // 1. Check RAM (NSCache) first for 0ms loading
        if let image = memoryCache.object(forKey: key) {
            return image
        }
        
        // 2. Check Disk Cache
        let fileURL = getFileURL(for: urlString)
        if let data = try? Data(contentsOf: fileURL), let image = UIImage(data: data) {
            // Restore it to RAM for next time
            memoryCache.setObject(image, forKey: key)
            return image
        }
        
        return nil
    }
    
    func insertImage(_ image: UIImage, data: Data, for urlString: String) {
        let key = NSString(string: urlString)
        
        // 1. Save to RAM (Limit set to 100 images)
        memoryCache.setObject(image, forKey: key)
        
        // 2. Save raw downloaded data directly to Disk (Avoids massive memory spike from pngData() compression)
        let fileURL = getFileURL(for: urlString)
        try? data.write(to: fileURL)
    }
    
    private func getFileURL(for urlString: String) -> URL {
        // Base64 encode the URL to make a safe filename without slashes
        let safeName = Data(urlString.utf8).base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "=", with: "")
        
        return cacheDirectory.appendingPathComponent(safeName)
    }
}
