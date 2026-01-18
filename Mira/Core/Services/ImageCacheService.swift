import SwiftUI
import UIKit

/// Simple in-memory image cache for product images
final class ImageCacheService {
    static let shared = ImageCacheService()

    private let cache = NSCache<NSString, UIImage>()
    private let memoryLimit: Int = 50 * 1024 * 1024 // 50 MB

    private init() {
        cache.totalCostLimit = memoryLimit
    }

    func image(for urlString: String) -> UIImage? {
        cache.object(forKey: urlString as NSString)
    }

    func setImage(_ image: UIImage, for urlString: String) {
        let cost = image.jpegData(compressionQuality: 1.0)?.count ?? 0
        cache.setObject(image, forKey: urlString as NSString, cost: cost)
    }

    func clearCache() {
        cache.removeAllObjects()
    }
}

/// A cached image view that uses NSCache for fast loading
struct CachedAsyncImage: View {
    let url: String?
    let size: CGFloat
    let cornerRadius: CGFloat

    @State private var image: UIImage?
    @State private var isLoading = true

    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if isLoading {
                Rectangle()
                    .fill(Color.backgroundSecondary)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .primaryBlue))
                    )
            } else {
                // Fallback placeholder
                Rectangle()
                    .fill(Color.backgroundSecondary)
                    .overlay(
                        Image("MiraLogo")
                            .resizable()
                            .scaledToFit()
                            .padding(size * 0.2)
                    )
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        guard let urlString = url?.trimmingCharacters(in: .whitespacesAndNewlines),
              !urlString.isEmpty else {
            isLoading = false
            return
        }

        // Check cache first
        if let cached = ImageCacheService.shared.image(for: urlString) {
            self.image = cached
            self.isLoading = false
            return
        }

        // Fetch from network
        guard let imageURL = URL(string: urlString) else {
            isLoading = false
            return
        }

        URLSession.shared.dataTask(with: imageURL) { data, _, error in
            DispatchQueue.main.async {
                self.isLoading = false

                guard let data = data,
                      let downloadedImage = UIImage(data: data) else {
                    return
                }

                // Cache the image
                ImageCacheService.shared.setImage(downloadedImage, for: urlString)
                self.image = downloadedImage
            }
        }.resume()
    }
}
