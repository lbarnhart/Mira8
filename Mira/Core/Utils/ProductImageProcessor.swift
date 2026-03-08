import UIKit
import CoreImage
import os

/// Processes product images for AI recognition.
/// Handles resizing, compression, and quality optimization.
struct ProductImageProcessor {

    private static let logger = Logger(subsystem: "com.mira8.app", category: "ImageProcessor")

    // MARK: - Image Processing

    /// Process an image for product recognition.
    /// - Parameters:
    ///   - image: The original UIImage
    ///   - configuration: Processing configuration
    /// - Returns: JPEG data ready for API submission
    static func processForRecognition(
        _ image: UIImage,
        configuration: ImageScanConfiguration = .default
    ) -> Data? {
        logger.debug("Processing image: \(image.size.width)x\(image.size.height)")

        // Step 1: Fix orientation
        let orientedImage = fixOrientation(image)

        // Step 2: Resize if needed
        let resizedImage = resize(
            orientedImage,
            maxDimension: configuration.maxImageSize
        )

        // Step 3: Skip cropping for product labels (text might wrap around cans)
        // Keep full image to ensure all text is visible

        // Step 4: Compress to JPEG with high quality for text readability
        // Use higher quality than config to ensure text is readable
        let quality = max(configuration.compressionQuality, 0.85)
        guard let jpegData = resizedImage.jpegData(
            compressionQuality: quality
        ) else {
            logger.error("Failed to create JPEG data")
            return nil
        }

        logger.debug("Processed image size: \(jpegData.count / 1024)KB")

        return jpegData
    }

    /// Process image from raw camera data
    static func processFromData(
        _ data: Data,
        configuration: ImageScanConfiguration = .default
    ) -> Data? {
        guard let image = UIImage(data: data) else {
            logger.error("Failed to create UIImage from data")
            return nil
        }

        return processForRecognition(image, configuration: configuration)
    }

    // MARK: - Fix Orientation

    private static func fixOrientation(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }

        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return normalizedImage ?? image
    }

    // MARK: - Resize

    private static func resize(_ image: UIImage, maxDimension: Int) -> UIImage {
        let maxDim = CGFloat(maxDimension)

        let width = image.size.width
        let height = image.size.height

        // No resize needed if within bounds
        if width <= maxDim && height <= maxDim {
            return image
        }

        // Calculate new size maintaining aspect ratio
        let aspectRatio = width / height
        let newSize: CGSize

        if width > height {
            newSize = CGSize(width: maxDim, height: maxDim / aspectRatio)
        } else {
            newSize = CGSize(width: maxDim * aspectRatio, height: maxDim)
        }

        // Render at new size
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

        logger.debug("Resized from \(width)x\(height) to \(newSize.width)x\(newSize.height)")

        return resized
    }

    // MARK: - Crop to Square

    private static func cropToSquare(_ image: UIImage) -> UIImage {
        let originalWidth = image.size.width
        let originalHeight = image.size.height

        // Already square (with some tolerance)
        if abs(originalWidth - originalHeight) < 10 {
            return image
        }

        let squareSize = min(originalWidth, originalHeight)
        let x = (originalWidth - squareSize) / 2
        let y = (originalHeight - squareSize) / 2

        let cropRect = CGRect(x: x, y: y, width: squareSize, height: squareSize)

        guard let cgImage = image.cgImage,
              let cropped = cgImage.cropping(to: cropRect) else {
            return image
        }

        return UIImage(cgImage: cropped, scale: image.scale, orientation: image.imageOrientation)
    }

    // MARK: - Enhancement (Optional)

    /// Apply basic enhancement to improve recognition.
    /// Only use if image quality is poor.
    static func enhance(_ image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }

        let context = CIContext()

        // Auto-adjust levels
        let adjustedImage: CIImage

        if let filter = CIFilter(name: "CIColorControls") {
            filter.setDefaults()
            filter.setValue(ciImage, forKey: kCIInputImageKey)
            filter.setValue(1.1, forKey: kCIInputContrastKey) // Slight contrast boost
            filter.setValue(0.0, forKey: kCIInputSaturationKey) // Keep colors
            filter.setValue(0.0, forKey: kCIInputBrightnessKey)

            adjustedImage = filter.outputImage ?? ciImage
        } else {
            adjustedImage = ciImage
        }

        // Render back to UIImage
        guard let cgImage = context.createCGImage(adjustedImage, from: adjustedImage.extent) else {
            return image
        }

        return UIImage(cgImage: cgImage)
    }

    // MARK: - Validation

    /// Check if image is suitable for product recognition
    static func validate(_ image: UIImage) -> ImageValidationResult {
        let width = image.size.width
        let height = image.size.height

        // Check minimum size
        if width < 200 || height < 200 {
            return .invalid(reason: "Image is too small. Please use a higher resolution photo.")
        }

        // Check aspect ratio (shouldn't be too extreme)
        let aspectRatio = max(width, height) / min(width, height)
        if aspectRatio > 4 {
            return .invalid(reason: "Image aspect ratio is too extreme. Please center the product in frame.")
        }

        // Estimate quality from file size (rough heuristic)
        if let data = image.jpegData(compressionQuality: 0.8) {
            let bytesPerPixel = Double(data.count) / (Double(width) * Double(height))
            if bytesPerPixel < 0.1 {
                return .warning(reason: "Image may be low quality. Results might be less accurate.")
            }
        }

        return .valid
    }
}

/// Result of image validation
enum ImageValidationResult {
    case valid
    case warning(reason: String)
    case invalid(reason: String)

    var isUsable: Bool {
        switch self {
        case .valid, .warning:
            return true
        case .invalid:
            return false
        }
    }
}
