import Foundation

// MARK: - HistoryManager (port of Android's HistoryManager.kt)
// Manages undo/redo stacks for EditAction. Min 30, default 50 actions.

public final class HistoryManager: ObservableObject {
    private let maxHistorySize: Int
    private var undoStack: [EditAction] = []
    private var redoStack: [EditAction] = []

    @Published public private(set) var canUndo: Bool = false
    @Published public private(set) var canRedo: Bool = false

    public init(maxHistorySize: Int = 50) {
        precondition(maxHistorySize >= 30, "History capacity must be at least 30 steps")
        self.maxHistorySize = maxHistorySize
    }

    public func recordAction(_ action: EditAction) {
        if undoStack.count >= maxHistorySize {
            undoStack.removeFirst()
        }
        undoStack.append(action)
        redoStack.removeAll()
        updatePublished()
    }

    @discardableResult
    public func undo() -> EditAction? {
        guard !undoStack.isEmpty else { return nil }
        let action = undoStack.removeLast()
        redoStack.append(action)
        updatePublished()
        return action
    }

    @discardableResult
    public func redo() -> EditAction? {
        guard !redoStack.isEmpty else { return nil }
        let action = redoStack.removeLast()
        undoStack.append(action)
        updatePublished()
        return action
    }

    public func getActionLog() -> [EditAction] { undoStack }

    public func load(actions: [EditAction]) {
        undoStack = Array(actions.suffix(maxHistorySize))
        redoStack.removeAll()
        updatePublished()
    }

    public func reset() {
        undoStack.removeAll(); redoStack.removeAll()
        updatePublished()
    }

    public var size: Int { undoStack.count }

    private func updatePublished() {
        canUndo = !undoStack.isEmpty
        canRedo = !redoStack.isEmpty
    }
}

// MARK: - ActionLogPlayer (port of Android's ActionLogPlayer.kt)
// Step-based playback engine for ActionLog replay.

public final class ActionLogPlayer: ObservableObject {
    private var actions: [EditAction] = []

    public var actionCount: Int { actions.count }
    public var startTimeMs: Int64 { actions.first?.timestampMs ?? 0 }
    public var endTimeMs: Int64   { actions.last?.timestampMs ?? 0 }
    public var rawDurationMs: Int64 {
        guard actions.count > 1 else { return 1 }
        return max(endTimeMs - startTimeMs, 1)
    }

    public var onUpdate: (([EditAction], EditAction?) -> Void)?
    public var onPlaybackEnded: (() -> Void)?

    @Published public private(set) var isPlaying: Bool = false
    private var playbackTask: Task<Void, Never>?
    private var speedMultiplier: Double = 1.0

    public func load(actionLog: ActionLog) {
        self.actions = actionLog.actions
    }

    public func load(actions: [EditAction]) {
        self.actions = actions
    }

    // MARK: Step-based queries (match Android API)

    public func getActionsUpToRelativeTime(_ relativeTimeMs: Int64) -> [EditAction] {
        guard !actions.isEmpty else { return [] }
        let targetAbsoluteTime = startTimeMs + relativeTimeMs
        return actions.filter { $0.timestampMs <= targetAbsoluteTime }
    }

    public func getActionsUpToStep(_ step: Int) -> [EditAction] {
        guard !actions.isEmpty, step > 0 else { return [] }
        return Array(actions.prefix(min(step, actions.count)))
    }

    public func getActionsForTimelapseFrame(frameIndex: Int, totalFrames: Int) -> [EditAction] {
        guard totalFrames > 0, !actions.isEmpty else { return [] }
        if frameIndex <= 0 { return [actions[0]] }
        if frameIndex >= totalFrames - 1 { return actions }
        let progress = Double(frameIndex) / Double(totalFrames - 1)
        let targetRelTime = Int64(progress * Double(rawDurationMs))
        let targetTime = startTimeMs + targetRelTime
        let matching = actions.filter { $0.timestampMs <= targetTime }
        return matching.isEmpty ? [actions[0]] : matching
    }

    // MARK: - Playback

    public func play(speed: Double = 1.0) {
        guard !actions.isEmpty else { onPlaybackEnded?(); return }
        stop()
        isPlaying = true
        speedMultiplier = speed

        playbackTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            var completed: [EditAction] = []
            for (idx, action) in self.actions.enumerated() {
                guard self.isPlaying else { break }
                completed.append(action)
                self.onUpdate?(Array(completed.dropLast()), action)

                // Delay between actions (capped to max 500ms per step at 1x speed)
                let nextTimestamp = idx + 1 < self.actions.count ? self.actions[idx + 1].timestampMs : action.timestampMs
                let rawDelay = max(0, nextTimestamp - action.timestampMs)
                let delay = min(Double(rawDelay) / 1000.0 / self.speedMultiplier, 0.5)
                if delay > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
            if self.isPlaying {
                self.isPlaying = false
                self.onUpdate?(self.actions, nil)
                self.onPlaybackEnded?()
            }
        }
    }

    public func stop() {
        isPlaying = false
        playbackTask?.cancel()
        playbackTask = nil
    }
}

