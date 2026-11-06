import Foundation
import CoreGraphics
import UIKit

// MARK: - LabelMapBuilder
// Deterministic Connected Components Label Map Builder.
// Ports Android's LabelMapBuilder.kt 1:1.

public enum LabelMapBuilder {

    public static let borderID: Int16 = 0
    public static let defaultMaxRadius: Int = 24

    public struct LabelMapResult: Equatable {
        public let width: Int
        public let height: Int
        public let labelMap: [Int16]
        public let regionCount: Int
        public let regionPixelCounts: [Int]
        public let version: Int

        public init(
            width: Int,
            height: Int,
            labelMap: [Int16],
            regionCount: Int,
            regionPixelCounts: [Int],
            version: Int = 1
        ) {
            self.width = width
            self.height = height
            self.labelMap = labelMap
            self.regionCount = regionCount
            self.regionPixelCounts = regionPixelCounts
            self.version = version
        }

        public func getRegionId(x: Int, y: Int) -> Int16 {
            if x >= 0 && x < width && y >= 0 && y < height {
                return labelMap[y * width + x]
            } else {
                return LabelMapBuilder.borderID
            }
        }

        /// Radial neighbor search: Finds nearest significant region (>= 1000px) within maxRadius.
        /// When tapping on or near a border line, this smoothly selects the adjacent enclosed region.
        public func findNearestRegionId(x: Int, y: Int, maxRadius: Int = LabelMapBuilder.defaultMaxRadius) -> Int16 {
            let direct = getRegionId(x: x, y: y)
            let directCount = (direct > 0 && Int(direct) < regionPixelCounts.count) ? regionPixelCounts[Int(direct)] : 0
            if direct > LabelMapBuilder.borderID && directCount >= 1000 {
                return direct
            }

            var fallbackId: Int16 = (direct > LabelMapBuilder.borderID) ? direct : LabelMapBuilder.borderID
            let maxRSq = maxRadius * maxRadius

            for r in 1...maxRadius {
                let rSq = r * r
                for dy in -r...r {
                    for dx in -r...r {
                        if dx * dx + dy * dy <= rSq {
                            let id = getRegionId(x: x + dx, y: y + dy)
                            if id > LabelMapBuilder.borderID {
                                let count = (Int(id) < regionPixelCounts.count) ? regionPixelCounts[Int(id)] : 0
                                if count >= 1000 {
                                    return id
                                } else if fallbackId <= LabelMapBuilder.borderID {
                                    fallbackId = id
                                }
                            }
                        }
                    }
                }
            }
            return fallbackId
        }
    }

    // MARK: - Synchronous Builder

    public static func buildFromPixelsSync(
        pixels: [UInt32],
        width: Int,
        height: Int,
        hasAlpha: Bool = false,
        dilationPixels: Int = 1
    ) -> LabelMapResult {
        precondition(width > 0 && height > 0, "Dimensions must be positive")
        precondition(pixels.count == width * height, "Pixel array size must match width * height")

        let size = width * height
        var isBorderMask = [Bool](repeating: false, count: size)

        // 1. Identify line-art type: Neon (bright on dark) vs Classic (dark on white)
        var whiteStrokeCount = 0
        var darkStrokeCount = 0
        let sampleStep = max(8, size / 10000)

        var idx = 0
        while idx < size {
            let p = pixels[idx]
            let a = (p >> 24) & 0xFF
            if a > 100 {
                let r = (p >> 16) & 0xFF
                let g = (p >> 8) & 0xFF
                let b = p & 0xFF
                let lum = Int(0.299 * Double(r) + 0.587 * Double(g) + 0.114 * Double(b))
                if lum > 128 { whiteStrokeCount += 1 } else { darkStrokeCount += 1 }
            }
            idx += sampleStep
        }
        let isNeonLineArt = hasAlpha || (whiteStrokeCount > darkStrokeCount && whiteStrokeCount > 0)

        for i in 0..<size {
            let p = pixels[i]
            let a = (p >> 24) & 0xFF
            let r = (p >> 16) & 0xFF
            let g = (p >> 8) & 0xFF
            let b = p & 0xFF
            let lum = Int(0.299 * Double(r) + 0.587 * Double(g) + 0.114 * Double(b))

            if isNeonLineArt {
                isBorderMask[i] = (a > 100 && lum > 100)
            } else if hasAlpha {
                isBorderMask[i] = (a > 128 && lum < 128)
            } else {
                isBorderMask[i] = (lum < 128)
            }
        }

        // 2. Connected Components Labeling (deterministic BFS queue)
        var labelMap = [Int16](repeating: borderID, count: size)
        var currentRegionId: Int16 = 0
        var countsList: [Int] = [0] // index 0 is border

        var queue = [Int]()
        queue.reserveCapacity(size / 8)

        for y in 0..<height {
            let rowOffset = y * width
            for x in 0..<width {
                let currentIdx = rowOffset + x
                if isBorderMask[currentIdx] || labelMap[currentIdx] != borderID {
                    continue
                }

                currentRegionId += 1
                precondition(currentRegionId < Int16.max, "Exceeded maximum region count")

                labelMap[currentIdx] = currentRegionId
                queue.append(currentIdx)
                var count = 0

                var head = 0
                while head < queue.count {
                    let curIdx = queue[head]
                    head += 1
                    count += 1
                    let curX = curIdx % width
                    let curY = curIdx / width

                    // 4-directional neighborhood: North, South, West, East
                    if curY > 0 {
                        let nIdx = curIdx - width
                        if !isBorderMask[nIdx] && labelMap[nIdx] == borderID {
                            labelMap[nIdx] = currentRegionId
                            queue.append(nIdx)
                        }
                    }
                    if curY < height - 1 {
                        let nIdx = curIdx + width
                        if !isBorderMask[nIdx] && labelMap[nIdx] == borderID {
                            labelMap[nIdx] = currentRegionId
                            queue.append(nIdx)
                        }
                    }
                    if curX > 0 {
                        let nIdx = curIdx - 1
                        if !isBorderMask[nIdx] && labelMap[nIdx] == borderID {
                            labelMap[nIdx] = currentRegionId
                            queue.append(nIdx)
                        }
                    }
                    if curX < width - 1 {
                        let nIdx = curIdx + 1
                        if !isBorderMask[nIdx] && labelMap[nIdx] == borderID {
                            labelMap[nIdx] = currentRegionId
                            queue.append(nIdx)
                        }
                    }
                }
                queue.removeAll(keepingCapacity: true)
                countsList.append(count)
            }
        }

        // 3. Morphological Dilation (expands regions under border lines to avoid white halos)
        if dilationPixels > 0 {
            applyDeterministicDilation(labelMap: &labelMap, isBorderMask: isBorderMask, width: width, height: height, radius: dilationPixels)
        }

        return LabelMapResult(
            width: width,
            height: height,
            labelMap: labelMap,
            regionCount: Int(currentRegionId),
            regionPixelCounts: countsList,
            version: 1
        )
    }

    // MARK: - Morphological Dilation

    private static func applyDeterministicDilation(
        labelMap: inout [Int16],
        isBorderMask: [Bool],
        width: Int,
        height: Int,
        radius: Int
    ) {
        var dilatedLabels = labelMap

        for _ in 1...radius {
            for y in 0..<height {
                let rowOffset = y * width
                for x in 0..<width {
                    let idx = rowOffset + x
                    if isBorderMask[idx] {
                        var best = dilatedLabels[idx]
                        if y > 0 { best = arbitrate(best, labelMap[idx - width]) }
                        if y < height - 1 { best = arbitrate(best, labelMap[idx + width]) }
                        if x > 0 { best = arbitrate(best, labelMap[idx - 1]) }
                        if x < width - 1 { best = arbitrate(best, labelMap[idx + 1]) }
                        dilatedLabels[idx] = best
                    }
                }
            }
            labelMap = dilatedLabels
        }
    }

    private static func arbitrate(_ current: Int16, _ candidate: Int16) -> Int16 {
        if candidate <= borderID { return current }
        if current <= borderID { return candidate }
        return (candidate < current) ? candidate : current
    }

    // MARK: - Convenience builder from UIImage
    public static func buildFromImage(_ image: UIImage, dilationPixels: Int = 1) -> LabelMapResult? {
        guard let cgImage = image.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height
        guard width > 0 && height > 0 else { return nil }

        var pixels = [UInt32](repeating: 0, count: width * height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue

        guard let ctx = CGBitmapContextCreate(
            &pixels,
            width,
            height,
            8,
            width * 4,
            colorSpace,
            bitmapInfo
        ) else { return nil }

        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        let hasAlpha = (cgImage.alphaInfo != .none && cgImage.alphaInfo != .noneSkipLast && cgImage.alphaInfo != .noneSkipFirst)
        return buildFromPixelsSync(pixels: pixels, width: width, height: height, hasAlpha: hasAlpha, dilationPixels: dilationPixels)
    }
}

