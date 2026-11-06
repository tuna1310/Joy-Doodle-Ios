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
        if case .fill(let fillAction) = action! {
            filler.revertFill(fillAction)
            XCTAssertEqual(filler.fillPixels[32 * w + 32], 0)

            filler.applyFill(fillAction)
            XCTAssertEqual(filler.fillPixels[32 * w + 32], expectedRed)
        }
    }
}

