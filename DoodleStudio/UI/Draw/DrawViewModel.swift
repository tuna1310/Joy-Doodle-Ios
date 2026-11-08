import SwiftUI
import Combine
import UIKit

// MARK: - DrawViewModel
// Port of Android's EditorViewModel. Full state machine for Drawing & Coloring.

// MARK: - EditorMode
public enum EditorMode: String, Codable {
    case draw
    case fill
}

@MainActor
public final class DrawViewModel: ObservableObject {

    // MARK: - Identity
    public var artworkId: String
    public var artworkTitle: String = "Neon Doodle"
    @Published public var templateId: String? = nil
    @Published public var isBlankCanvas: Bool = true

    // MARK: - Mode
    @Published public var editorMode: EditorMode = .draw

    // MARK: - Brush Settings
    @Published public var currentBrushId: String = "CLASSIC_NEON"
    @Published public var currentColor: Color = Color(UIColor(hex: 0xFFFF2D95))
    @Published public var currentStrokeWidth: CGFloat = 14
    @Published public var currentAlpha: CGFloat = 1.0
    @Published public var isEraser: Bool = false
    @Published public var isColorFillMode: Bool = false

    // MARK: - History
    public let historyManager = HistoryManager()
    @Published public var canUndo: Bool = false
    @Published public var canRedo: Bool = false

    // MARK: - Actions (committed strokes)
    public var committedActions: [EditAction] = []

    // MARK: - Replay
    @Published public var isReplaying: Bool = false
    @Published public var replaySpeed: Double = 1.0
    public let player = ActionLogPlayer()

    // MARK: - Template & Region Filler
    @Published public var templateUIImage: UIImage? = nil
    public var regionFiller: RegionFiller? = nil

    // MARK: - UI State
    @Published public var showBrushPicker: Bool = false
    @Published public var showShareSubmenu: Bool = false
    @Published public var showClearAlert: Bool = false
    @Published public var showExitDialog: Bool = false
    @Published public var showTemplatePicker: Bool = false
    @Published public var showShareSheet: Bool = false
    @Published public var shareItems: [Any] = []
    @Published public var toastMessage: String? = nil
    @Published public var isSaved: Bool = false
    @Published public var isLoading: Bool = false

    // MARK: - Canvas reference
    public weak var canvasView: NeonCanvasView?

    private var cancellables: Set<AnyCancellable> = []
    private var backgroundObserver: NSObjectProtocol?

    // MARK: - Init
    public init(artworkId: String? = nil, existing artwork: Artwork? = nil) {
        self.artworkId = artworkId ?? "artwork_\(UUID().uuidString.prefix(8))"

        if let artwork = artwork {
            self.artworkTitle = artwork.title
            self.templateId = artwork.templateId
            self.isBlankCanvas = artwork.isBlankCanvas
        }

        setupPlayer()
        subscribeHistory()
        setupBackgroundAutoSave()

        if let tId = templateId {
            if let template = TemplateRepository.shared.getTemplateById(tId) {
                loadTemplate(template)
            }
        }

        loadSavedActions()
    }

    private func loadSavedActions() {
        if let log = ArtworkRepository.shared.loadActionLog(artworkId: artworkId) {
            self.committedActions = log.actions
            self.historyManager.load(actions: log.actions)
            self.isSaved = true
        }
    }

    // Track whether saved actions have been loaded and rendered onto canvas
    private var hasRestoredCanvas: Bool = false
    private var pendingTemplate: Template? = nil
    private var templateLoadGeneration: Int = 0

    public func restoreCanvasIfNeeded() {
        guard !hasRestoredCanvas, let canvas = canvasView, canvas.bounds.width > 0, canvas.bounds.height > 0 else { return }
        hasRestoredCanvas = true

        // 0. Pending template queued before canvas had non-zero bounds
        if let pending = pendingTemplate {
            pendingTemplate = nil
            loadTemplate(pending)
            return
        }

        // 1. Line art
        if let template = templateUIImage {
            canvas.templateUIImage = template
        }

        // 2. Fill layer
        if !committedActions.isEmpty {
            updateFillLayerFromActions(committedActions)
        }

        // 3. Strokes
        let strokeActions = committedActions.filter {
            switch $0 { case .stroke, .erase: return true; case .fill: return false }
        }
        canvas.redrawFromActions(strokeActions)
    }

    deinit {
        if let obs = backgroundObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }

    private func setupBackgroundAutoSave() {
        backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self, !self.committedActions.isEmpty else { return }
            let log = self.exportActionLog()
            ArtworkRepository.shared.saveDraft(artworkId: self.artworkId, actionLog: log)
        }
    }

    private func setupPlayer() {
        player.onUpdate = { [weak self] completed, active in
            guard let self = self else { return }
            // Update fill layer if completed actions contain fill
            self.updateFillLayerFromActions(completed)
            self.canvasView?.setReplayState(completed: completed, active: active)
        }
        player.onPlaybackEnded = { [weak self] in
            self?.exitReplay()
        }
    }

    private func subscribeHistory() {
        historyManager.objectWillChange.sink { [weak self] in
            self?.canUndo = self?.historyManager.canUndo ?? false
            self?.canRedo = self?.historyManager.canRedo ?? false
        }.store(in: &cancellables)
    }

    // MARK: - Brush / Mode Settings

    public func selectBrush(_ brushId: String) {
        isEraser = false
        isColorFillMode = false
        editorMode = .draw
        currentBrushId = brushId
        canvasView?.currentBrushId = brushId
        canvasView?.isEraser = false
        canvasView?.isColorFillMode = false

        let brush = BrushRegistry.get(brushId)
        currentStrokeWidth = brush.defaultSize
        canvasView?.currentStrokeWidth = brush.defaultSize
    }

    public func toggleEraser() {
        showBrushPicker = false; showShareSubmenu = false
        isEraser.toggle()
        if isEraser {
            isColorFillMode = false
            editorMode = .draw
        }
        canvasView?.isEraser = isEraser
        canvasView?.isColorFillMode = false
    }

    public func setEditorMode(_ mode: EditorMode) {
        editorMode = mode
        isColorFillMode = (mode == .fill)
        canvasView?.isColorFillMode = isColorFillMode
        if mode == .fill {
            isEraser = false
            canvasView?.isEraser = false
        }
    }

    // MARK: - Template Handling

    public func loadTemplate(_ template: Template) {
        templateLoadGeneration += 1
        let currentGen = templateLoadGeneration

        isLoading = true
        templateId = template.id
        isBlankCanvas = false
        artworkTitle = template.displayTitleVi

        // If canvas has not laid out yet (zero size), hold as pendingTemplate
        if canvasView == nil || canvasView?.bounds.width == 0 || canvasView?.bounds.height == 0 {
            pendingTemplate = template
            drawLogger.info("Canvas not yet laid out; queued pending template: \(template.id)")
        }

        drawLogger.info("Starting loadTemplate [gen=\(currentGen)]: id=\(template.id)")

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let startTime = DispatchTime.now()
            let image = TemplateRepository.shared.loadTemplateImage(template)

            var filler: RegionFiller? = nil
            if let img = image {
                if let labelMap = LabelMapBuilder.buildFromImage(img, dilationPixels: 1) {
                    filler = RegionFiller(labelMapResult: labelMap)
                }
            }
            let endTime = DispatchTime.now()
            let elapsedMs = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000.0

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                guard self.templateLoadGeneration == currentGen else {
                    self.drawLogger.info("Discarded stale template load [gen=\(currentGen), current=\(self.templateLoadGeneration)]")
                    return
                }

                self.isLoading = false

                guard let img = image, let f = filler else {
                    self.drawLogger.error("Failed to load template or build labelMap for '\(template.id)'")
                    self.toastMessage = "Không thể tải hình mẫu. Vui lòng thử lại."
                    self.templateId = nil
                    self.isBlankCanvas = true
                    self.templateUIImage = nil
                    self.canvasView?.templateUIImage = nil
                    self.regionFiller = nil
                    return
                }

                self.drawLogger.info("Successfully applied template '\(template.id)' in \(String(format: "%.1f", elapsedMs))ms (\(f.regionCount) regions)")
                self.templateUIImage = img
                self.canvasView?.templateUIImage = img
                self.regionFiller = f
                self.editorMode = .fill
                self.isColorFillMode = true
                self.canvasView?.isColorFillMode = true

                if !self.committedActions.isEmpty {
                    self.updateFillLayerFromActions(self.committedActions)
                }
            }
        }
    }

    public func clearToBlankCanvas() {
        templateId = nil
        isBlankCanvas = true
        templateUIImage = nil
        canvasView?.templateUIImage = nil
        regionFiller = nil
        editorMode = .draw
        isColorFillMode = false
        canvasView?.isColorFillMode = false
        canvasView?.fillLayer = nil
        clearStrokes()
    }

    // MARK: - Fill Tap Handler (<300ms background queue, radial radius 24px)

    public func handleFillTap(at point: CGPoint) {
        guard let filler = regionFiller, let canvas = canvasView else { return }

        // Scale point from view bounds to labelMap coordinates
        let canvasW = canvas.bounds.width
        let canvasH = canvas.bounds.height
        guard canvasW > 0, canvasH > 0 else { return }

        let scaleX = CGFloat(filler.width) / canvasW
        let scaleY = CGFloat(filler.height) / canvasH

        let mapX = Int(point.x * scaleX)
        let mapY = Int(point.y * scaleY)

        let colorInt = UIColor(currentColor).argbInt

        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            // Radial search: finds nearest region within 24px
            let regionId = filler.labelMapResult.findNearestRegionId(x: mapX, y: mapY, maxRadius: 24)

            if regionId > 0 {
                let normX = Float(point.x / canvasW)
                let normY = Float(point.y / canvasH)

                if let action = filler.fill(regionId: Int(regionId), color: colorInt, normalizedX: normX, normalizedY: normY) {
                    let fillImage = filler.generateImage()
                    await MainActor.run {
                        HapticManager.shared.impact()
                        self.committedActions.append(action)
                        self.historyManager.recordAction(action)
                        self.canvasView?.fillLayer = fillImage
                        self.isSaved = false
                    }
                }
            }
        }
    }

    // MARK: - Commit Stroke

    public func commitAction(_ action: EditAction) {
        committedActions.append(action)
        historyManager.recordAction(action)
        isSaved = false
    }

    // MARK: - Undo / Redo

    public func undo() {
        guard let action = historyManager.undo() else { return }
        HapticManager.shared.impact()

        switch action {
        case .stroke, .erase:
            committedActions.removeAll { $0.timestampMs == action.timestampMs }
            let strokeActions = committedActions.filter {
                switch $0 { case .stroke, .erase: return true; case .fill: return false }
            }
            canvasView?.redrawFromActions(strokeActions)

        case .fill(let f):
            committedActions.removeAll { $0.timestampMs == action.timestampMs }
            regionFiller?.revertFill(f)
            let img = regionFiller?.generateImage()
            canvasView?.fillLayer = img
        }
        isSaved = false
    }

    public func redo() {
        guard let action = historyManager.redo() else { return }
        HapticManager.shared.impact()

        switch action {
        case .stroke, .erase:
            committedActions.append(action)
            canvasView?.appendCommittedAction(action)

        case .fill(let f):
            committedActions.append(action)
            regionFiller?.applyFill(f)
            let img = regionFiller?.generateImage()
            canvasView?.fillLayer = img
        }
        isSaved = false
    }

    private func updateFillLayerFromActions(_ actions: [EditAction]) {
        guard let filler = regionFiller else { return }
        filler.reset()
        for action in actions {
            if case .fill(let f) = action {
                filler.applyFill(f)
            }
        }
        canvasView?.fillLayer = filler.generateImage()
    }

    // MARK: - Clear (keep template frame)

    public func clearStrokes() {
        if isReplaying { exitReplay() }
        HapticManager.shared.impact()
        let fillActions = committedActions.filter { if case .fill = $0 { return true }; return false }
        committedActions = fillActions
        historyManager.reset()
        for fa in fillActions { historyManager.recordAction(fa) }
        canvasView?.redrawFromActions([])
        isSaved = false
    }

    // MARK: - Replay

    public func startReplay(speed: Double = 1.0) {
        guard !committedActions.isEmpty else {
            toastMessage = "Draw something first to play replay!"
            return
        }
        showBrushPicker = false; showShareSubmenu = false
        isReplaying = true
        replaySpeed = speed
        canvasView?.isReplaying = true
        let log = exportActionLog()
        player.load(actionLog: log)
        player.play(speed: speed)
    }

    public func exitReplay() {
        player.stop()
        isReplaying = false
        canvasView?.exitReplayMode()
        // Restore fill layer to latest
        let img = regionFiller?.generateImage()
        canvasView?.fillLayer = img
        let strokeActions = committedActions.filter {
            switch $0 { case .stroke, .erase: return true; case .fill: return false }
        }
        canvasView?.redrawFromActions(strokeActions)
    }

    // MARK: - Export / Save

    public func exportActionLog() -> ActionLog {
        let actions = historyManager.getActionLog()
        let duration: Int64
        if let first = actions.first?.timestampMs, let last = actions.last?.timestampMs, actions.count > 1 {
            duration = max(0, last - first)
        } else {
            duration = 0
        }
        let w = Int(canvasView?.bounds.width ?? 1024)
        let h = Int(canvasView?.bounds.height ?? 1024)
        return ActionLog(
            version: 1,
            artworkId: artworkId,
            templateId: templateId,
            isBlankCanvas: isBlankCanvas,
            canvasWidth: max(1, w),
            canvasHeight: max(1, h),
            backgroundColor: UIColor.black.argbInt,
            actions: actions,
            totalDurationMs: duration
        )
    }

    public func shareImage() {
        guard let canvas = canvasView else { return }
        let image = canvas.snapshot()
        shareItems = [image]
        showShareSheet = true
    }

    public func saveArtwork(onDone: @escaping (Bool) -> Void) {
        guard let canvas = canvasView else { onDone(false); return }
        isLoading = true
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            let (image, log, artwork) = await MainActor.run {
                let img = canvas.snapshot()
                let l = self.exportActionLog()
                let art = Artwork(
                    id: self.artworkId,
                    title: self.artworkTitle,
                    templateId: self.templateId,
                    isBlankCanvas: self.isBlankCanvas
                )
                return (img, l, art)
            }
            let success = ArtworkRepository.shared.save(artwork: artwork, actionLog: log, thumbnail: image)
            await MainActor.run {
                self.isLoading = false
                self.isSaved = success
                if success {
                    self.toastMessage = "Đã lưu tranh thành công!"
                } else {
                    self.toastMessage = "Không thể lưu tranh"
                }
                onDone(success)
            }
        }
    }

    public var hasContent: Bool {
        !committedActions.isEmpty
    }
}
