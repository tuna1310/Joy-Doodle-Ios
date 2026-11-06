import XCTest
@testable import DoodleStudio

final class HistoryManagerTests: XCTestCase {

    func testRecordUndoRedo() {
        let history = HistoryManager(maxHistorySize: 30)
        XCTAssertFalse(history.canUndo)
        XCTAssertFalse(history.canRedo)
        XCTAssertEqual(history.size, 0)

        let action1 = EditAction.stroke(StrokeEditAction(
            points: [PointF(10, 10)],
            color: -65536,
            strokeWidth: 10,
            toolType: "CLASSIC_NEON"
        ))
        let action2 = EditAction.stroke(StrokeEditAction(
            points: [PointF(20, 20)],
            color: -16711681,
            strokeWidth: 12,
            toolType: "RAINBOW_GLOW"
        ))

        history.recordAction(action1)
        XCTAssertTrue(history.canUndo)
        XCTAssertFalse(history.canRedo)
        XCTAssertEqual(history.size, 1)

        history.recordAction(action2)
        XCTAssertEqual(history.size, 2)

        // Undo action2
        let undone = history.undo()
        XCTAssertEqual(undone, action2)
        XCTAssertEqual(history.size, 1)
        XCTAssertTrue(history.canUndo)
        XCTAssertTrue(history.canRedo)

        // Redo action2
        let redone = history.redo()
        XCTAssertEqual(redone, action2)
        XCTAssertEqual(history.size, 2)
        XCTAssertFalse(history.canRedo)
    }

    func testMaxHistoryLimit() {
        let capacity = 30
        let history = HistoryManager(maxHistorySize: capacity)

        for i in 0..<50 {
            let act = EditAction.stroke(StrokeEditAction(
                points: [PointF(Float(i), Float(i))],
                color: -1,
                strokeWidth: 10,
                timestampMs: Int64(i)
            ))
            history.recordAction(act)
        }

        XCTAssertEqual(history.size, capacity)
        let log = history.getActionLog()
        XCTAssertEqual(log.count, capacity)
        XCTAssertEqual(log.first?.timestampMs, 20)
        XCTAssertEqual(log.last?.timestampMs, 49)
    }

    func testReset() {
        let history = HistoryManager()
        let act = EditAction.stroke(StrokeEditAction(points: [PointF(1, 1)], color: -1, strokeWidth: 5))
        history.recordAction(act)
        XCTAssertTrue(history.canUndo)

        history.reset()
        XCTAssertFalse(history.canUndo)
        XCTAssertFalse(history.canRedo)
        XCTAssertEqual(history.size, 0)
    }
}
