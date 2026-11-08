import UIKit

// MARK: - BrushPreviewCache
// Thread-safe cache for generated brush thumbnail previews in brush picker.
public final class BrushPreviewCache {
    public static let shared = BrushPreviewCache()

    private var cache: [String: UIImage] = [:]
    private let lock = NSLock()

    public init() {}

    public func getPreview(for brush: any BrushEffect, size: CGSize = CGSize(width: 64, height: 64)) -> UIImage {
        lock.lock()
        if let cached = cache[brush.id] {
            lock.unlock()
            return cached
        }
        lock.unlock()

        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { format in
            let ctx = format.cgContext
            ctx.setFillColor(UIColor.black.cgColor)
            ctx.fill(CGRect(origin: .zero, size: size))
            brush.drawPreview(ctx: ctx, width: size.width, height: size.height)
        }

        lock.lock()
        cache[brush.id] = img
        lock.unlock()
        return img
    }

    public func clear() {
        lock.lock()
        cache.removeAll()
        lock.unlock()
    }
}

