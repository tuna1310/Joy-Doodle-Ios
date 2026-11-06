import XCTest
@testable import DoodleStudio

final class ActionLogTests: XCTestCase {

    func testActionLogSerializationRoundTrip() throws {
        let p1 = PointF(120.5, 340.5)
        let p2 = PointF(180.0, 420.0)

        let stroke = StrokeEditAction(
            points: [p1, p2],
            color: -16711681, // Cyan ARGB Int (0xFF00FFFF)
            strokeWidth: 14.0,
            alpha: 0.95,
            toolType: "CLASSIC_NEON",
            seed: 9876543210123,
            timestampMs: 1700000000100
        )

        let erase = EraseEditAction(
            points: [PointF(50.0, 50.0)],
            strokeWidth: 20.0,
            timestampMs: 1700000000200
        )

        let fill = FillEditAction(
            regionId: 4,
            color: -65536, // Red ARGB Int (0xFFFF0000)
            prevColor: 0,
            normalizedX: 0.25,
            normalizedY: 0.5,
            timestampMs: 1700000000300
        )

        let log = ActionLog(
            version: 1,
            artworkId: "art_test_roundtrip_123",
            templateId: "template_01_330237",
            isBlankCanvas: false,
            canvasWidth: 1024,
            canvasHeight: 1024,
            backgroundColor: -16777216, // Black
            actions: [
                .stroke(stroke),
                .erase(erase),
                .fill(fill)
            ],
            totalDurationMs: 200,
            createdAt: 1700000000000
        )

        // Serialize
        let jsonString = try log.serialize()
        XCTAssertFalse(jsonString.isEmpty)

        // Deserialize
        let decoded = try ActionLog.deserialize(from: jsonString)

        XCTAssertEqual(decoded.version, 1)
        XCTAssertEqual(decoded.artworkId, "art_test_roundtrip_123")
        XCTAssertEqual(decoded.templateId, "template_01_330237")
        XCTAssertEqual(decoded.isBlankCanvas, false)
        XCTAssertEqual(decoded.canvasWidth, 1024)
        XCTAssertEqual(decoded.canvasHeight, 1024)
        XCTAssertEqual(decoded.backgroundColor, -16777216)
        XCTAssertEqual(decoded.actions.count, 3)

        // Verify toolType and seed preservation
        if case .stroke(let decodedStroke) = decoded.actions[0] {
            XCTAssertEqual(decodedStroke.toolType, "CLASSIC_NEON")
            XCTAssertEqual(decodedStroke.seed, 9876543210123)
            XCTAssertEqual(decodedStroke.points.count, 2)
            XCTAssertEqual(decodedStroke.points[0].x, 120.5)
            XCTAssertEqual(decodedStroke.points[0].y, 340.5)
            XCTAssertEqual(decodedStroke.color, -16711681)
            XCTAssertEqual(decodedStroke.strokeWidth, 14.0)
        } else {
            XCTFail("Expected first action to be a stroke")
        }

        if case .fill(let decodedFill) = decoded.actions[2] {
            XCTAssertEqual(decodedFill.regionId, 4)
            XCTAssertEqual(decodedFill.color, -65536)
            XCTAssertEqual(decodedFill.normalizedX, 0.25, accuracy: 0.001)
            XCTAssertEqual(decodedFill.normalizedY, 0.5, accuracy: 0.001)
        } else {
            XCTFail("Expected third action to be a fill")
        }
    }

    /// Tests decoding a real sample JSON string formatted identically to Android ActionLogSerializer output
    func testDecodeAndroidActionLogPayload() throws {
        let androidJson = """
        {
          "version": 1,
          "artworkId": "artwork_android_sample_01",
          "templateId": "template_05_352670",
          "isBlankCanvas": false,
          "canvasWidth": 1024,
          "canvasHeight": 1024,
          "backgroundColor": -16777216,
          "actions": [
            {
              "type": "stroke",
              "points": [
                {"x": 100.0, "y": 150.0},
                {"x": 105.0, "y": 155.0}
              ],
              "color": -54188,
              "strokeWidth": 14.0,
              "alpha": 1.0,
              "toolType": "RAINBOW_GLOW",
              "seed": 123456789,
              "timestampMs": 1700000001000
            },
            {
              "type": "fill",
              "regionId": 2,
              "color": -16711681,
              "normalizedX": 0.45,
              "normalizedY": 0.65,
              "timestampMs": 1700000002000
            }
          ],
          "totalDurationMs": 1000,
          "createdAt": 1700000000000
        }
        """

        let decoded = try ActionLog.deserialize(from: androidJson)
        XCTAssertEqual(decoded.version, 1)
        XCTAssertEqual(decoded.artworkId, "artwork_android_sample_01")
        XCTAssertEqual(decoded.templateId, "template_05_352670")
        XCTAssertFalse(decoded.isBlankCanvas)
        XCTAssertEqual(decoded.actions.count, 2)

        guard case .stroke(let s) = decoded.actions[0] else {
            XCTFail("Expected stroke")
            return
        }
        XCTAssertEqual(s.toolType, "RAINBOW_GLOW")
        XCTAssertEqual(s.seed, 123456789)
        XCTAssertEqual(s.points.count, 2)

        guard case .fill(let f) = decoded.actions[1] else {
            XCTFail("Expected fill")
            return
        }
        XCTAssertEqual(f.regionId, 2)
        XCTAssertEqual(f.color, -16711681)
    }
}
