import Foundation

public final class HistoryManager {
    private var undoStack: [StrokeAction] = []
    private var redoStack: [StrokeAction] = []
    private let maxHistorySteps: Int
    
    public init(maxHistorySteps: Int = 100) {
        self.maxHistorySteps = maxHistorySteps
    }
    
    public var canUndo: Bool {
        !undoStack.isEmpty
    }
    
    public var canRedo: Bool {
        !redoStack.isEmpty
    }
    
    public var currentStrokes: [StrokeAction] {
        undoStack
    }
    
    public func push(_ action: StrokeAction) {
        undoStack.append(action)
        if undoStack.count > maxHistorySteps {
            undoStack.removeFirst()
        }
        redoStack.removeAll()
    }
    
    @discardableResult
    public func undo() -> StrokeAction? {
        guard let last = undoStack.popLast() else { return nil }
        redoStack.append(last)
        return last
    }
    
    @discardableResult
    public func redo() -> StrokeAction? {
        guard let restored = redoStack.popLast() else { return nil }
        undoStack.append(restored)
        return restored
    }
    
    public func clear() {
        undoStack.removeAll()
        redoStack.removeAll()
    }
    
    public func load(actions: [StrokeAction]) {
        undoStack = actions
        redoStack.removeAll()
    }
}
