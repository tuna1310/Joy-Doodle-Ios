import XCTest
@testable import DoodleStudio

final class ActionLogPlayerTests: XCTestCase {
    
    func testPlayerLoadingAndSeeking() {
        let player = ActionLogPlayer()
        
        let stroke1 = StrokeAction(
            points: [Point(x: 10, y: 10), Point(x: 20, y: 20)],
            color: CodableColor(hex: "#00E5FF"),
            strokeWidth: 10,
            timestampMs: 1000
        )
        let stroke2 = StrokeAction(
            points: [Point(x: 30, y: 30), Point(x: 40, y: 40)],
            color: CodableColor(hex: "#FF2D95"),
            strokeWidth: 10,
            timestampMs: 2500
        )
        
        player.load(actions: [stroke1, stroke2])
        XCTAssertGreaterThan(player.totalDurationMs, 0)
        XCTAssertEqual(player.progress, 0.0)
        XCTAssertFalse(player.isPlaying)
        
        // Seek to 50%
        player.seek(progress: 0.5)
        XCTAssertEqual(player.progress, 0.5, accuracy: 0.01)
        
        // Cycle speed
        XCTAssertEqual(player.speedMultiplier, 1.0)
        player.cycleSpeed()
        XCTAssertEqual(player.speedMultiplier, 2.0)
        player.cycleSpeed()
        XCTAssertEqual(player.speedMultiplier, 4.0)
        player.cycleSpeed()
        XCTAssertEqual(player.speedMultiplier, 1.0)
    }
    
    func testPlayerFrameRendering() {
        let player = ActionLogPlayer()
        let stroke1 = StrokeAction(
            points: [Point(x: 10, y: 10), Point(x: 20, y: 20)],
            color: CodableColor(hex: "#00E5FF"),
            strokeWidth: 10,
            timestampMs: 1000
        )
        
        var renderedCompleted: [StrokeAction] = []
        var renderedPartial: StrokeAction? = nil
        
        player.onUpdate = { completed, active in
            renderedCompleted = completed
            renderedPartial = active
        }
        
        player.load(actions: [stroke1])
        player.seek(progress: 1.0)
        
        XCTAssertEqual(renderedCompleted.count + (renderedPartial != nil ? 1 : 0), 1)
    }
}
