import XCTest
@testable import DoodleStudio

final class ActionLogTests: XCTestCase {
    
    func testActionLogSerializationRoundTrip() throws {
        let p1 = Point(x: 100.5, y: 200.5)
        let p2 = Point(x: 150.0, y: 250.0)
        let color = CodableColor(red: 1.0, green: 0.2, blue: 0.5, alpha: 0.9)
        
        let stroke = StrokeAction(
            points: [p1, p2],
            color: color,
            strokeWidth: 12.0,
            alpha: 0.9,
            toolType: .neon,
            style: .neonGlow,
            timestampMs: 1700000000123
        )
        
        let log = ActionLog(
            version: 1,
            artworkId: "test-artwork-uuid-1234",
            canvasWidth: 720.0,
            canvasHeight: 1280.0,
            backgroundColor: "#000000",
            actions: [stroke],
            totalDurationMs: 5000
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(log)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ActionLog.self, from: data)
        
        XCTAssertEqual(decoded.version, log.version)
        XCTAssertEqual(decoded.artworkId, log.artworkId)
        XCTAssertEqual(decoded.canvasWidth, log.canvasWidth)
        XCTAssertEqual(decoded.canvasHeight, log.canvasHeight)
        XCTAssertEqual(decoded.backgroundColor, log.backgroundColor)
        XCTAssertEqual(decoded.totalDurationMs, log.totalDurationMs)
        XCTAssertEqual(decoded.actions.count, 1)
        
        let decodedStroke = decoded.actions[0]
        XCTAssertEqual(decodedStroke.points.count, 2)
        XCTAssertEqual(decodedStroke.points[0].x, 100.5)
        XCTAssertEqual(decodedStroke.points[0].y, 200.5)
        XCTAssertEqual(decodedStroke.strokeWidth, 12.0)
        XCTAssertEqual(decodedStroke.toolType, .neon)
        XCTAssertEqual(decodedStroke.style, .neonGlow)
        XCTAssertEqual(decodedStroke.timestampMs, 1700000000123)
        XCTAssertEqual(decodedStroke.color.red, 1.0, accuracy: 0.001)
        XCTAssertEqual(decodedStroke.color.green, 0.2, accuracy: 0.001)
    }
}
