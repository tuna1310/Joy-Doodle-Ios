import XCTest
@testable import DoodleStudio

final class ActionLogPlayerTests: XCTestCase {

    func testPlayerStepAndRelativeTimeQueries() {
        let player = ActionLogPlayer()

        let stroke1 = EditAction.stroke(StrokeEditAction(
            points: [PointF(10, 10)],
            color: -65536,
            strokeWidth: 10,
            timestampMs: 1000
        ))
        let stroke2 = EditAction.stroke(StrokeEditAction(
            points: [PointF(20, 20)],
            color: -16711681,
            strokeWidth: 10,
            timestampMs: 2000
        ))
        let stroke3 = EditAction.stroke(StrokeEditAction(
            points: [PointF(30, 30)],
            color: -54188,
            strokeWidth: 10,
            timestampMs: 3000
        ))

        player.load(actions: [stroke1, stroke2, stroke3])

        XCTAssertEqual(player.actionCount, 3)
        XCTAssertEqual(player.startTimeMs, 1000)
        XCTAssertEqual(player.endTimeMs, 3000)
        XCTAssertEqual(player.rawDurationMs, 2000)

        // Query by step
        XCTAssertEqual(player.getActionsUpToStep(0).count, 0)
        XCTAssertEqual(player.getActionsUpToStep(1).count, 1)
        XCTAssertEqual(player.getActionsUpToStep(2).count, 2)
        XCTAssertEqual(player.getActionsUpToStep(10).count, 3)

        // Query by relative time
        let actionsAt0 = player.getActionsUpToRelativeTime(0)
        XCTAssertEqual(actionsAt0.count, 1) // timestampMs <= 1000

        let actionsAt1500 = player.getActionsUpToRelativeTime(1500)
        XCTAssertEqual(actionsAt1500.count, 2) // timestampMs <= 2500

        let actionsAt2000 = player.getActionsUpToRelativeTime(2000)
        XCTAssertEqual(actionsAt2000.count, 3) // timestampMs <= 3000
    }

    func testTimelapseFrameMapping() {
        let player = ActionLogPlayer()

        let stroke1 = EditAction.stroke(StrokeEditAction(points: [PointF(0, 0)], color: -1, strokeWidth: 5, timestampMs: 1000))
        let stroke2 = EditAction.stroke(StrokeEditAction(points: [PointF(1, 1)], color: -1, strokeWidth: 5, timestampMs: 2000))
        let stroke3 = EditAction.stroke(StrokeEditAction(points: [PointF(2, 2)], color: -1, strokeWidth: 5, timestampMs: 3000))

        player.load(actions: [stroke1, stroke2, stroke3])

        let frame0 = player.getActionsForTimelapseFrame(frameIndex: 0, totalFrames: 5)
        XCTAssertEqual(frame0.count, 1)

        let frameLast = player.getActionsForTimelapseFrame(frameIndex: 4, totalFrames: 5)
        XCTAssertEqual(frameLast.count, 3)
    }
}
