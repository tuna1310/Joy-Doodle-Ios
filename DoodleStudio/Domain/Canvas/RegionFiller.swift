import Foundation
import CoreGraphics
import UIKit

// MARK: - RegionFiller
// Region Coloring Engine based on LabelMap.
// Ports Android's RegionFiller.kt 1:1.

public final class RegionFiller {
    public let labelMapResult: LabelMapBuilder.LabelMapResult
    public let width: Int
    public let height: Int
    public let regionCount: Int

    // Region color lookup table (1...regionCount). 0 is uncolored.
    private var regionColors: [Int]

    // Working ARGB_8888 pixel buffer for the fill layer
    public private(set) var fillPixels: [UInt32]

    public init(labelMapResult: LabelMapBuilder.LabelMapResult) {
        self.labelMapResult = labelMapResult
        self.width = labelMapResult.width
        self.height = labelMapResult.height
        self.regionCount = labelMapResult.regionCount
        self.regionColors = [Int](repeating: 0, count: regionCount + 1)
        self.fillPixels = [UInt32](repeating: 0, count: width * height)
    }

    /// Fills a region with a new color.
    /// Returns the created EditAction.fill, or nil if already that color or invalid.
    public func fill(regionId: Int, color: Int, normalizedX: Float = 0, normalizedY: Float = 0) -> EditAction? {
        guard regionId > 0 && regionId <= regionCount else { return nil }
        let prev = regionColors[regionId]
        if prev == color { return nil } // Skip redundant action

        regionColors[regionId] = color
        recolorRegion(targetRegionId: Int16(regionId), newColor: color)

        let action = FillEditAction(
            regionId: regionId,
            color: color,
            prevColor: prev,
            normalizedX: normalizedX,
            normalizedY: normalizedY,
            timestampMs: Int64(Date().timeIntervalSince1970 * 1000)
        )
        return .fill(action)
    }

    public func applyFill(_ action: FillEditAction) {
        guard action.regionId > 0 && action.regionId <= regionCount else { return }
        regionColors[action.regionId] = action.color
        recolorRegion(targetRegionId: Int16(action.regionId), newColor: action.color)
    }

    public func revertFill(_ action: FillEditAction) {
        guard action.regionId > 0 && action.regionId <= regionCount else { return }
        regionColors[action.regionId] = action.prevColor
        recolorRegion(targetRegionId: Int16(action.regionId), newColor: action.prevColor)
    }

    public func getRegionColor(regionId: Int) -> Int {
        guard regionId > 0 && regionId <= regionCount else { return 0 }
        return regionColors[regionId]
    }

    public func reset() {
        for i in 0...regionCount { regionColors[i] = 0 }
        for i in 0..<fillPixels.count { fillPixels[i] = 0 }
    }

    private func recolorRegion(targetRegionId: Int16, newColor: Int) {
        let labels = labelMapResult.labelMap
        let size = width * height
        let uColor = UInt32(bitPattern: Int32(truncatingIfNeeded: newColor))

        for i in 0..<size {
            if labels[i] == targetRegionId {
                fillPixels[i] = uColor
            }
        }
    }

    /// Generates a UIImage from current fillPixels
    public func generateImage() -> UIImage? {
        guard width > 0, height > 0 else { return nil }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue

        var pixelsCopy = fillPixels
        guard let ctx = CGBitmapContextCreate(
            &pixelsCopy,
            width,
            height,
            8,
            width * 4,
            colorSpace,
            bitmapInfo
        ), let cgImage = ctx.makeImage() else { return nil }

        return UIImage(cgImage: cgImage)
    }
}

