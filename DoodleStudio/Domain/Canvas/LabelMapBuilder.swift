import Foundation
import CoreGraphics
import UIKit
import os

private let builderLogger = Logger(subsystem: "com.doodlestudio.app", category: "LabelMapBuilder")

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
            if direct > LabelMapBuilder.borderID {
                if directCount >= 1000 {
                    return direct
                }
                // Small feature precision: if user tapped squarely inside a small region
                // (all 4 cardinal neighbors share the exact same region ID), honor the direct tap
                // instead of jumping to an adjacent large background region.
                if x > 0 && x < width - 1 && y > 0 && y < height - 1 {
                    if getRegionId(x: x + 1, y: y) == direct &&
                       getRegionId(x: x - 1, y: y) == direct &&
                       getRegionId(x: x, y: y + 1) == direct &&
                       getRegionId(x: x, y: y - 1) == direct {
                        return direct
                    }
                }
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
        guard width > 0 && height > 0, pixels.count == width * height else {
            return LabelMapResult(
                width: max(0, width),
                height: max(0, height),
                labelMap: [],
                regionCount: 0,
                regionPixelCounts: [0],
                version: 1
            )
        }

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

        // 2. Connected Components Labeling (deterministic BFS with flat preallocated queue)
        var labelMap = [Int16](repeating: borderID, count: size)
        var currentRegionId: Int16 = 0
        var countsList: [Int] = [0] // index 0 is border

        // Flat reusable queue allocated ONCE to prevent dynamic array reallocation and memory spikes
        var queue = [Int32](repeating: 0, count: size)
        var head = 0
        var tail = 0

        for y in 0..<height {
            let rowOffset = y * width
            for x in 0..<width {
                let currentIdx = rowOffset + x
                if isBorderMask[currentIdx] || labelMap[currentIdx] != borderID {
                    continue
                }

                if currentRegionId >= Int16.max - 1 {
                    builderLogger.warning("Reached maximum region count limit: \(currentRegionId)")
                    break
                }
                currentRegionId += 1

                labelMap[currentIdx] = currentRegionId
                queue[tail] = Int32(currentIdx)
                tail += 1
                var count = 0

                while head < tail {
                    let curIdx = Int(queue[head])
                    head += 1
                    count += 1
                    let curX = curIdx % width
                    let curY = curIdx / width

                    // 4-directional neighborhood: North, South, West, East
                    if curY > 0 {
                        let nIdx = curIdx - width
                        if !isBorderMask[nIdx] && labelMap[nIdx] == borderID {
                            labelMap[nIdx] = currentRegionId
                            queue[tail] = Int32(nIdx)
                            tail += 1
                        }
                    }
                    if curY < height - 1 {
                        let nIdx = curIdx + width
                        if !isBorderMask[nIdx] && labelMap[nIdx] == borderID {
                            labelMap[nIdx] = currentRegionId
                            queue[tail] = Int32(nIdx)
                            tail += 1
                        }
                    }
                    if curX > 0 {
                        let nIdx = curIdx - 1
                        if !isBorderMask[nIdx] && labelMap[nIdx] == borderID {
                            labelMap[nIdx] = currentRegionId
                            queue[tail] = Int32(nIdx)
                            tail += 1
                        }
                    }
                    if curX < width - 1 {
                        let nIdx = curIdx + 1
                        if !isBorderMask[nIdx] && labelMap[nIdx] == borderID {
                            labelMap[nIdx] = currentRegionId
                            queue[tail] = Int32(nIdx)
                            tail += 1
                        }
                    }
                }
                head = 0
                tail = 0
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

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        // ARGB_8888 (premultipliedFirst + byteOrder32Big) matches Android ARGB Int format
        let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Big.rawValue

        guard let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else { return nil }

        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let rawPtr = ctx.data else { return nil }
        let buffer = rawPtr.bindMemory(to: UInt32.self, capacity: width * height)
        let pixels = Array(UnsafeBufferPointer(start: buffer, count: width * height))

        let hasAlpha = (cgImage.alphaInfo != .none && cgImage.alphaInfo != .noneSkipLast && cgImage.alphaInfo != .noneSkipFirst)
        let start = DispatchTime.now()
        let result = buildFromPixelsSync(pixels: pixels, width: width, height: height, hasAlpha: hasAlpha, dilationPixels: dilationPixels)
        let end = DispatchTime.now()
        let ms = Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000.0
        builderLogger.info("Built LabelMap for image (\(width)x\(height)) in \(String(format: "%.1f", ms))ms with \(result.regionCount) regions")
        return result
    }
    }
}

