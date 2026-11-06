import XCTest
@testable import DoodleStudio

final class HistoryManagerTests: XCTestCase {
    
    func testPushUndoRedo() {
        let history = HistoryManager(maxHistorySteps: 10)
        XCTAssertFalse(history.canUndo)
        XCTAssertFalse(history.canRedo)
        
        let stroke1 = StrokeAction(points: [Point(x: 10, y: 10)], color: CodableColor(hex: "#FF0000"), strokeWidth: 5)
        let stroke2 = StrokeAction(points: [Point(x: 20, y: 20)], color: CodableColor(hex: "#00FF00"), strokeWidth: 8)
        
        history.push(stroke1)
        XCTAssertTrue(history.canUndo)
        XCTAssertFalse(history.canRedo)
        XCTAssertEqual(history.currentStrokes.count, 1)
        
        history.push(stroke2)
        XCTAssertEqual(history.currentStrokes.count, 2)
        
        let undone = history.undo()
        XCTAssertEqual(undone?.id, stroke2.id)
        XCTAssertEqual(history.currentStrokes.count, 1)
        XCTAssertTrue(history.canRedo)
        
        let redone = history.redo()
        XCTAssertEqual(redone?.id, stroke2.id)
        XCTAssertEqual(history.currentStrokes.count, 2)
        XCTAssertFalse(history.canRedo)
    }
    
    func testMaxHistoryLimit() {
        let history = HistoryManager(maxHistorySteps: 3)
        for i in 0..<5 {
            let stroke = StrokeAction(points: [Point(x: Double(i), y: Double(i))], color: CodableColor(hex: "#FFFFFF"), strokeWidth: 4)
            history.push(stroke)
        }
        XCTAssertEqual(history.currentStrokes.count, 3)
    }
    
    func testClear() {
        let history = HistoryManager()
        let stroke = StrokeAction(points: [Point(x: 1, y: 1)], color: CodableColor(hex: "#FFFFFF"), strokeWidth: 4)
        history.push(stroke)
        XCTAssertTrue(history.canUndo)
        
        history.clear()
        XCTAssertFalse(history.canUndo)
        XCTAssertFalse(history.canRedo)
        XCTAssertEqual(history.currentStrokes.count, 0)
    }
}
