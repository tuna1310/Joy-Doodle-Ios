import SwiftUI
import Combine

public final class DrawViewModel: ObservableObject {
    // Current artwork identity
    public let artworkId: UUID
    public var artworkTitle: String
    
    // Tools & Brushes
    @Published public var currentTool: BrushTool = .neon
    @Published public var currentStyle: BrushStyle = .neonGlow
    @Published public var currentColor: Color = AppColors.neonYellow
    @Published public var currentStrokeWidth: CGFloat = 10.0
    @Published public var currentAlpha: CGFloat = 1.0
    
    // State of strokes
    @Published public var strokes: [StrokeAction] = []
    public let historyManager = HistoryManager()
    
    // Replay Player
    @Published public var isReplaying: Bool = false
    @Published public var replayCompletedStrokes: [StrokeAction] = []
    @Published public var replayActiveStroke: StrokeAction? = nil
    public let player = ActionLogPlayer()
    
    // UI state
    @Published public var showBrushPicker: Bool = false
    @Published public var showShareSubmenu: Bool = false
    @Published public var showClearAlert: Bool = false
    @Published public var showMovieExport: Bool = false
    @Published public var showShareSheet: Bool = false
    @Published public var shareItems: [Any] = []
    @Published public var toastMessage: String? = nil
    
    // Canvas reference for snapshots
    public weak var canvasView: NeonCanvasView?
    
    public init(artworkId: UUID? = nil) {
        let id = artworkId ?? UUID()
        self.artworkId = id
        self.artworkTitle = "Artwork \(Date().formatted(date: .abbreviated, time: .shortened))"
        
        setupPlayer()
        
        if let existingId = artworkId, let saved = ArtworkRepository.shared.loadStrokes(for: existingId) {
            self.strokes = saved
            self.historyManager.load(actions: saved)
        }
    }
    
    private func setupPlayer() {
        player.onUpdate = { [weak self] completed, active in
            guard let self = self else { return }
            self.replayCompletedStrokes = completed
            self.replayActiveStroke = active
        }
        
        player.onPlaybackEnded = { [weak self] in
            // Playback completed
        }
    }
    
    // MARK: - Actions
    
    public func addStroke(_ stroke: StrokeAction) {
        historyManager.push(stroke)
        strokes = historyManager.currentStrokes
    }
    
    public func undo() {
        guard historyManager.canUndo else { return }
        SoundEffectManager.shared.playUndo()
        historyManager.undo()
        strokes = historyManager.currentStrokes
    }
    
    public func redo() {
        guard historyManager.canRedo else { return }
        SoundEffectManager.shared.playPop()
        historyManager.redo()
        strokes = historyManager.currentStrokes
    }
    
    public func clearCanvas() {
        SoundEffectManager.shared.playTrash()
        historyManager.clear()
        strokes = []
        canvasView?.clear()
    }
    
    public func toggleBrushPicker() {
        if currentTool == .eraser {
            currentTool = (currentStyle == .rainbow) ? .rainbow : .neon
        }
        showBrushPicker.toggle()
        showShareSubmenu = false
    }
    
    public func toggleEraser() {
        showBrushPicker = false
        showShareSubmenu = false
        if currentTool == .eraser {
            currentTool = (currentStyle == .rainbow) ? .rainbow : .neon
        } else {
            currentTool = .eraser
        }
    }
    
    public func startReplay() {
        guard !strokes.isEmpty else {
            toastMessage = "Draw something first to play replay!"
            return
        }
        showBrushPicker = false
        showShareSubmenu = false
        isReplaying = true
        player.load(actions: strokes)
        player.play()
    }
    
    public func exitReplay() {
        player.stop()
        isReplaying = false
        replayCompletedStrokes.removeAll()
        replayActiveStroke = nil
        canvasView?.exitReplayMode()
    }
    
    public func toggleShareSubmenu() {
        showBrushPicker = false
        showShareSubmenu.toggle()
    }
    
    public func saveToPhotoAlbum() {
        guard let canvas = canvasView else { return }
        let snapshot = canvas.snapshot()
        PNGExporter.saveToPhotosAlbum(image: snapshot) { [weak self] success, err in
            if success {
                self?.toastMessage = "Saved drawing to Photos!"
                HapticManager.shared.success()
            } else {
                self?.toastMessage = "Could not save: \(err?.localizedDescription ?? "Permission required")"
                HapticManager.shared.warning()
            }
        }
    }
    
    public func openShareSheet() {
        guard let canvas = canvasView else { return }
        let snapshot = canvas.snapshot()
        shareItems = [snapshot]
        showShareSheet = true
    }
    
    public func saveArtwork() {
        guard !strokes.isEmpty, let canvas = canvasView else { return }
        let thumbnail = canvas.snapshot()
        ArtworkRepository.shared.save(
            id: artworkId,
            title: artworkTitle,
            strokes: strokes,
            thumbnail: thumbnail,
            canvasSize: canvas.bounds.size
        )
    }
}
