import XCTest
@testable import DoodleStudio

final class RegionFillerTests: XCTestCase {

    func testRegionFillerClosedRegion() {
        // Create a 64x64 canvas
        let w = 64
        let h = 64
        let size = w * h

        // Fill with white background (0xFFFFFFFF)
        var pixels = [UInt32](repeating: 0xFFFFFFFF, count: size)

        // Draw a black square border (0xFF000000) from (16, 16) to (48, 48)
        let blackColor: UInt32 = 0xFF000000
        for x in 16...48 {
            pixels[16 * w + x] = blackColor // top
            pixels[48 * w + x] = blackColor // bottom
        }
        for y in 16...48 {
            pixels[y * w + 16] = blackColor // left
            pixels[y * w + 48] = blackColor // right
        }

        // Build LabelMap with 0 dilation for crisp boundary test
        let labelMapResult = LabelMapBuilder.buildFromPixelsSync(
            pixels: pixels,
            width: w,
            height: h,
            hasAlpha: false,
            dilationPixels: 0
        )

        // Should have at least 2 distinct regions:
        // Region A (outside the square) and Region B (inside the square)
        XCTAssertGreaterThanOrEqual(labelMapResult.regionCount, 2)

        // Find the region ID inside the square (at center 32, 32)
        let centerRegionId = Int(labelMapResult.getRegionId(x: 32, y: 32))
        XCTAssertGreaterThan(centerRegionId, 0)

        // Create RegionFiller
        let filler = RegionFiller(labelMapResult: labelMapResult)
        let testColor = -65536 // Red ARGB Int (0xFFFF0000)

        // Fill center region
        let action = filler.fill(regionId: centerRegionId, color: testColor)
        XCTAssertNotNil(action)

        // Verify pixel at (32, 32) is filled with red
        let centerPixel = filler.fillPixels[32 * w + 32]
        let expectedRed: UInt32 = 0xFFFF0000
        XCTAssertEqual(centerPixel, expectedRed)

        // Verify pixel outside the square (at 5, 5) remains uncolored (0)
        let outsidePixel = filler.fillPixels[5 * w + 5]
        XCTAssertEqual(outsidePixel, 0)

        // Test radial neighbor search when tapping directly on border pixel (16, 32)
        let nearestRegion = labelMapResult.findNearestRegionId(x: 16, y: 32, maxRadius: 24)
        XCTAssertGreaterThan(nearestRegion, 0)

        // Test Undo & Redo on fill
        if let action = action, case .fill(let fillAction) = action {
            filler.revertFill(fillAction)
            XCTAssertEqual(filler.fillPixels[32 * w + 32], 0)

            filler.applyFill(fillAction)
            XCTAssertEqual(filler.fillPixels[32 * w + 32], expectedRed)
        }
    }

    func testRegionFillerZeroSizeCanvas() {
        // Build with 0x0 canvas
        let labelMapResult = LabelMapBuilder.buildFromPixelsSync(
            pixels: [],
            width: 0,
            height: 0,
            hasAlpha: false,
            dilationPixels: 0
        )
        XCTAssertEqual(labelMapResult.width, 0)
        XCTAssertEqual(labelMapResult.height, 0)
        XCTAssertEqual(labelMapResult.regionCount, 0)

        let filler = RegionFiller(labelMapResult: labelMapResult)
        XCTAssertEqual(filler.width, 0)
        XCTAssertEqual(filler.height, 0)
        XCTAssertEqual(filler.regionCount, 0)

        // Filling on zero-size canvas must return nil and not crash
        let action = filler.fill(regionId: 1, color: -65536)
        XCTAssertNil(action)

        // Reset on zero-size canvas must not crash
        filler.reset()

        // Generate image on zero-size canvas must return nil and not crash
        let image = filler.generateImage()
        XCTAssertNil(image)
    }

    func testSmallFeaturePrecision() {
        // Create 32x32 canvas
        let w = 32
        let h = 32
        var pixels = [UInt32](repeating: 0xFFFFFFFF, count: w * h)

        // Draw a large outer boundary
        let black: UInt32 = 0xFF000000
        for x in 0..<w {
            pixels[x] = black
            pixels[(h - 1) * w + x] = black
        }
        for y in 0..<h {
            pixels[y * w] = black
            pixels[y * w + (w - 1)] = black
        }

        // Draw a tiny inner box from (13, 13) to (18, 18)
        for x in 13...18 {
            pixels[13 * w + x] = black
            pixels[18 * w + x] = black
        }
        for y in 13...18 {
            pixels[y * w + 13] = black
            pixels[y * w + 18] = black
        }

        let labelMap = LabelMapBuilder.buildFromPixelsSync(
            pixels: pixels,
            width: w,
            height: h,
            hasAlpha: false,
            dilationPixels: 0
        )

        let smallCenterId = labelMap.getRegionId(x: 15, y: 15)
        let bigRegionId = labelMap.getRegionId(x: 5, y: 5)
        XCTAssertGreaterThan(smallCenterId, 0)
        XCTAssertGreaterThan(bigRegionId, 0)
        XCTAssertNotEqual(smallCenterId, bigRegionId)

        // When tapping inside the small feature (15, 15):
        let nearestInsideSmall = labelMap.findNearestRegionId(x: 15, y: 15, maxRadius: 10)
        XCTAssertEqual(nearestInsideSmall, smallCenterId, "Tapping inside small feature must select the small region ID")

        // When tapping on the border (13, 15):
        let nearestOnBorder = labelMap.findNearestRegionId(x: 13, y: 15, maxRadius: 10)
        XCTAssertGreaterThan(nearestOnBorder, 0)
    }
}

