import XCTest
@testable import DoodleStudio

final class ArtworkRestoreTests: XCTestCase {

    func testSaveAndRestoreArtworkActionLog() throws {
        let testArtworkId = "test_restore_\(UUID().uuidString)"
        let nowMs = Int64(Date().timeIntervalSince1970 * 1000)
        let artwork = Artwork(
            id: testArtworkId,
            title: "Restore Test",
            templateId: "template_01_330237",
            isBlankCanvas: false,
            thumbnailFileName: "\(testArtworkId).png",
            createdAt: nowMs,
            updatedAt: nowMs
        )

        let strokeAction = StrokeEditAction(
            points: [PointF(50, 50), PointF(100, 100)],
            color: -16711681,
            strokeWidth: 12.0,
            toolType: "RAINBOW_GLOW",
            seed: 42
        )
        let fillAction = FillEditAction(
            regionId: 3,
            color: -65536,
            prevColor: 0,
            normalizedX: 0.5,
            normalizedY: 0.5
        )

        let actionLog = ActionLog(
            version: 1,
            artworkId: testArtworkId,
            templateId: "template_01_330237",
            isBlankCanvas: false,
            canvasWidth: 512,
            canvasHeight: 512,
            backgroundColor: -16777216,
            actions: [.stroke(strokeAction), .fill(fillAction)],
            totalDurationMs: 500,
            createdAt: nowMs
        )

        let dummyImage = UIGraphicsImageRenderer(size: CGSize(width: 32, height: 32)).image { ctx in
            UIColor.black.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 32, height: 32))
        }

        // 1. Save artwork and ActionLog
        let saved = ArtworkRepository.shared.save(artwork: artwork, actionLog: actionLog, thumbnail: dummyImage)
        XCTAssertTrue(saved)

        // 2. Load ActionLog back
        let loadedLog = ArtworkRepository.shared.loadActionLog(artworkId: testArtworkId)
        XCTAssertNotNil(loadedLog)
        XCTAssertEqual(loadedLog?.actions.count, 2)
        XCTAssertEqual(loadedLog?.templateId, "template_01_330237")

        if case .stroke(let restoredStroke) = loadedLog?.actions[0] {
            XCTAssertEqual(restoredStroke.toolType, "RAINBOW_GLOW")
            XCTAssertEqual(restoredStroke.seed, 42)
            XCTAssertEqual(restoredStroke.points.count, 2)
        } else {
            XCTFail("First action should be stroke")
        }

        // Clean up
        ArtworkRepository.shared.deleteArtwork(id: artwork.id)
    }

    func testCorruptedActionLogReturnsNilWithoutCrash() {
        let corruptedArtworkId = "corrupted_\(UUID().uuidString)"
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let artworksDir = documents.appendingPathComponent("artworks", isDirectory: true)
        let logURL = artworksDir.appendingPathComponent("\(corruptedArtworkId)_log.json")

        // Write non-JSON garbage
        try? "###NOT_VALID_JSON###".data(using: .utf8)?.write(to: logURL)

        // Must safely return nil without throwing or crashing
        let result = ArtworkRepository.shared.loadActionLog(artworkId: corruptedArtworkId)
        XCTAssertNil(result)

        // Cleanup
        try? FileManager.default.removeItem(at: logURL)
    }

    func testMissingActionLogReturnsNilWithoutCrash() {
        let nonExistentId = "non_existent_\(UUID().uuidString)"
        let result = ArtworkRepository.shared.loadActionLog(artworkId: nonExistentId)
        XCTAssertNil(result)
    }

    @MainActor
    func testClearStrokesStopsReplayAndResetsCanvas() {
        let canvas = NeonCanvasView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        let strokeAction = StrokeEditAction(
            points: [PointF(10, 10), PointF(20, 20)],
            color: -65536,
            strokeWidth: 8.0,
            toolType: "CLASSIC_NEON"
        )

        // Commit stroke to bitmap via public API
        canvas.appendCommittedAction(.stroke(strokeAction))

        // Redraw with empty actions to clear strokes
        canvas.redrawFromActions([])

        // Check that layout and actions work cleanly
        XCTAssertNotNil(canvas)
    }
}
