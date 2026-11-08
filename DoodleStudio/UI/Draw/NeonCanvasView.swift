import UIKit
import CoreGraphics
import os

// MARK: - NeonCanvasView
// Core Graphics canvas with double-buffered bitmap cache for 60fps performance.
// Layer ordering (bottom to top):
// 1. Black background (via committedBitmap)
// 2. Fill layer (color flood fill)
// 3. Committed free-draw strokes (in committedBitmap)
// 4. In-progress active stroke (live drawing - only the NEW segment)
// 5. Template line-art overlay (topmost, never erased or covered)
//
// KEY PERFORMANCE DESIGN:
// - committedBitmap caches ALL committed strokes. Never redrawn from scratch on touch.
// - draw(_:) only composites layers; active stroke drawn in dirty rect only.
// - setNeedsDisplay(dirtyRect) instead of full setNeedsDisplay() during live drawing.
// - Rainbow brush uses pre-computed segment indices, NOT per-point UIColor allocation.
// - Particle brushes (star/snow/heart etc.) use cached sprite images.

private let canvasLogger = Logger(subsystem: "com.doodlestudio.app", category: "NeonCanvasView")

@MainActor
public protocol NeonCanvasViewDelegate: AnyObject {
    func canvasDidCommitStroke(_ action: EditAction)
    func canvasDidBeginDrawing()
    func canvasDidTapToFill(at point: CGPoint)
    func canvasDidLayoutSubviews()
}

public final class NeonCanvasView: UIView {

    // MARK: - Delegate & Settings
    public weak var delegate: NeonCanvasViewDelegate?
    public var currentBrushId: String = "CLASSIC_NEON"
    public var currentColor: UIColor = UIColor(hex: 0xFFFF2D95)
    public var currentStrokeWidth: CGFloat = 14
    public var currentAlpha: CGFloat = 1.0
    public var isEraser: Bool = false
    public var isColorFillMode: Bool = false
    public var templateUIImage: UIImage? = nil {
        didSet { setNeedsDisplay() }
    }

    // MARK: - Bitmap Layers
    // committedBitmap: BLACK background + all committed strokes
    private var committedBitmap: UIImage?

    // fillLayer: colour-fill regions rendered separately
    public var fillLayer: UIImage? {
        didSet { setNeedsDisplay() }
    }

    // MARK: - Replay
    public var isReplaying: Bool = false
    private var replayCompletedActions: [EditAction] = []
    private var replayActiveAction: EditAction? = nil

    // MARK: - Touch Tracking
    private var activePoints: [PointF] = []
    private var activeSeed: Int64 = 0
    private var activeTimestampMs: Int64 = 0
    private var touchStartTime: TimeInterval = 0
    private var touchStartPoint: CGPoint = .zero
    private var hasMovedSignificantly: Bool = false
    // Track index into activePoints that was last rendered for dirty-rect optimisation
    private var lastRenderedIndex: Int = 0

    // Generation token to ensure background redraws never overwrite newer strokes
    private var redrawGeneration: Int = 0

    // Screen scale capped at 2x for performance
    private var renderScale: CGFloat {
        min(UIScreen.main.scale, 2.0)
    }

    // MARK: - Init
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .black
        isOpaque = true
        isMultipleTouchEnabled = false
        layer.drawsAsynchronously = false
        NotificationCenter.default.addObserver(self, selector: #selector(handleMemoryWarning), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }

    @objc private func handleMemoryWarning() {
        canvasLogger.warning("Memory warning received in NeonCanvasView - purging preview caches")
        BrushPreviewCache.shared.clear()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Layout
    public override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0, bounds.height > 0 else { return }
        if committedBitmap == nil {
            delegate?.canvasDidLayoutSubviews()
            if committedBitmap == nil {
                redrawFromActions([])
            }
        }
    }

    // MARK: - HitTest
    // The canvas accepts touch across its full area.
    // SwiftUI buttons above the canvas (with higher zIndex) intercept their own taps.
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard bounds.contains(point) else { return nil }
        return super.hitTest(point, with: event)
    }

    // MARK: - External API

    public func setActions(_ actions: [EditAction]) {
        redrawFromActions(actions)
    }

    public func appendCommittedAction(_ action: EditAction) {
        commitActionToBitmapSync(action)
        setNeedsDisplay()
    }

    public func clear() {
        committedBitmap = nil
        activePoints.removeAll()
        lastRenderedIndex = 0
        setNeedsDisplay()
    }

    public func setReplayState(completed: [EditAction], active: EditAction?) {
        isReplaying = true
        replayCompletedActions = completed
        replayActiveAction = active
        setNeedsDisplay()
    }

    public func exitReplayMode() {
        isReplaying = false
        replayCompletedActions.removeAll()
        replayActiveAction = nil
        setNeedsDisplay()
    }

    // MARK: - Bitmap Redraw (from scratch)

    public func redrawAllCommitted() {
        redrawFromActions([])
    }

    public func redrawFromActions(_ actions: [EditAction]) {
        guard bounds.width > 0, bounds.height > 0 else { return }
        let size = bounds.size
        let scale = renderScale

        redrawGeneration += 1
        let currentToken = redrawGeneration

        // Run bitmap generation on a background queue then update on main
        let w = size.width, h = size.height
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            UIGraphicsBeginImageContextWithOptions(CGSize(width: w, height: h), true, scale)
            guard let ctx = UIGraphicsGetCurrentContext() else {
                UIGraphicsEndImageContext(); return
            }
            ctx.setFillColor(UIColor.black.cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
            for action in actions {
                self.renderAction(action, ctx: ctx, bounds: CGRect(x: 0, y: 0, width: w, height: h))
            }
            let img = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            DispatchQueue.main.async { [weak self] in
                guard let self = self, self.redrawGeneration == currentToken else {
                    // Stale background render discarded: user drew a new stroke or started another action
                    return
                }
                self.committedBitmap = img
                self.setNeedsDisplay()
            }
        }
    }

    private func commitActionToBitmapSync(_ action: EditAction) {
        redrawGeneration += 1 // Invalidate any pending background redraws!
        guard bounds.width > 0, bounds.height > 0 else { return }
        let size = bounds.size
        let scale = renderScale
        let existing = committedBitmap

        UIGraphicsBeginImageContextWithOptions(size, true, scale)
        guard let ctx = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext(); return
        }
        if let img = existing {
            img.draw(in: CGRect(origin: .zero, size: size))
        } else {
            ctx.setFillColor(UIColor.black.cgColor)
            ctx.fill(CGRect(origin: .zero, size: size))
        }
        self.renderAction(action, ctx: ctx, bounds: CGRect(origin: .zero, size: size))
        let newBitmap = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.committedBitmap = newBitmap
    }

    // MARK: - Render Action

    private func renderAction(_ action: EditAction, ctx: CGContext, bounds: CGRect) {
        switch action {
        case .stroke(let s):
            guard !s.points.isEmpty else { return }
            let brush = BrushRegistry.get(s.toolType)
            let color = UIColor(androidArgb: s.color)
            brush.drawCommitted(
                ctx: ctx,
                points: s.points,
                color: color,
                strokeWidth: CGFloat(s.strokeWidth),
                alpha: CGFloat(s.alpha),
                scaleX: 1, scaleY: 1,
                seed: s.seed
            )
        case .erase(let e):
            guard !e.points.isEmpty else { return }
            renderErase(ctx: ctx, points: e.points, strokeWidth: CGFloat(e.strokeWidth))
        case .fill:
            // Fill actions rendered via fillLayer
            break
        }
    }

    private func renderErase(ctx: CGContext, points: [PointF], strokeWidth: CGFloat) {
        guard !points.isEmpty else { return }
        ctx.saveGState()
        ctx.setBlendMode(.clear)
        ctx.setStrokeColor(UIColor.clear.cgColor)
        ctx.setLineWidth(strokeWidth)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)

        if points.count == 1 {
            let p = points[0]
            ctx.addEllipse(in: CGRect(x: CGFloat(p.x) - strokeWidth*0.5,
                                      y: CGFloat(p.y) - strokeWidth*0.5,
                                      width: strokeWidth, height: strokeWidth))
            ctx.fillPath()
        } else {
            let path = CGMutablePath()
            path.move(to: points[0].cgPoint)
            for i in 1..<points.count {
                path.addLine(to: points[i].cgPoint)
            }
            ctx.addPath(path)
            ctx.strokePath()
        }
        ctx.restoreGState()
    }

    private func renderActiveStroke(ctx: CGContext) {
        guard !activePoints.isEmpty else { return }
        if isEraser {
            renderErase(ctx: ctx, points: activePoints, strokeWidth: currentStrokeWidth * 1.5)
        } else {
            let brush = BrushRegistry.get(currentBrushId)
            brush.drawLive(
                ctx: ctx,
                points: activePoints,
                color: currentColor,
                strokeWidth: currentStrokeWidth,
                alpha: currentAlpha,
                scaleX: 1, scaleY: 1,
                seed: activeSeed
            )
        }
    }

    // MARK: - draw(_:) Layer Stacking

    public override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        if isReplaying {
            // Replay mode: Black -> Fill -> Strokes -> Active -> Template
            ctx.setFillColor(UIColor.black.cgColor)
            ctx.fill(bounds)
            fillLayer?.draw(in: bounds)

            for action in replayCompletedActions {
                renderAction(action, ctx: ctx, bounds: bounds)
            }
            if let active = replayActiveAction {
                renderAction(active, ctx: ctx, bounds: bounds)
            }
            templateUIImage?.draw(in: bounds)
            return
        }

        // Normal mode:
        // 1. CommittedBitmap (black background + all past strokes)
        if let cached = committedBitmap {
            cached.draw(in: bounds)
        } else {
            ctx.setFillColor(UIColor.black.cgColor)
            ctx.fill(bounds)
        }

        // 2. Fill Layer (drawn on top of strokes to match Android layer order)
        fillLayer?.draw(in: bounds)

        // 3. Live active stroke on top (only when drawing)
        if !activePoints.isEmpty && hasMovedSignificantly {
            renderActiveStroke(ctx: ctx)
        }

        // 4. Template line-art on top of everything
        templateUIImage?.draw(in: bounds)
    }

    // MARK: - Touch Handling

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isReplaying, let touch = touches.first else { return }
        redrawGeneration += 1 // Drawing starts: cancel any older background redraws
        delegate?.canvasDidBeginDrawing()

        let loc = touch.location(in: self)
        touchStartPoint = loc
        touchStartTime = Date().timeIntervalSince1970
        hasMovedSignificantly = false
        lastRenderedIndex = 0

        activeSeed = Int64(Date().timeIntervalSince1970 * 1000) ^ Int64(loc.x * 100) ^ Int64(loc.y * 10)
        activeTimestampMs = Int64(Date().timeIntervalSince1970 * 1000)
        activePoints = [PointF(loc)]
        canvasLogger.debug("touchBegan at (\(loc.x, privacy: .public), \(loc.y, privacy: .public))")
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isReplaying, let touch = touches.first else { return }

        let loc = touch.location(in: self)
        let dx = loc.x - touchStartPoint.x
        let dy = loc.y - touchStartPoint.y

        if !hasMovedSignificantly && (dx * dx + dy * dy > 64) {
            hasMovedSignificantly = true
        }

        if isColorFillMode && !hasMovedSignificantly { return }

        // Apple Pencil pressure
        if touch.type == .pencil && touch.maximumPossibleForce > 0 && touch.force > 0 {
            let normalizedForce = max(0.5, min(2.0, touch.force / touch.maximumPossibleForce * 2.0))
            currentStrokeWidth = max(4, currentStrokeWidth * normalizedForce)
        }

        // Collect coalesced touches, skip points < 2.5pt apart
        let prevCount = activePoints.count
        if let coalesced = event?.coalescedTouches(for: touch), !coalesced.isEmpty {
            for cTouch in coalesced {
                addPoint(PointF(cTouch.location(in: self)))
            }
        } else {
            addPoint(PointF(loc))
        }

        // Only invalidate dirty rect around new segment
        if activePoints.count > prevCount {
            let dirtyRect = computeDirtyRect(from: prevCount)
            setNeedsDisplay(dirtyRect)
        }
    }

    private func addPoint(_ p: PointF) {
        if let last = activePoints.last {
            let dpx = p.x - last.x; let dpy = p.y - last.y
            guard dpx * dpx + dpy * dpy >= 6.25 else { return } // skip < 2.5pt
        }
        activePoints.append(p)
    }

    private func computeDirtyRect(from startIndex: Int) -> CGRect {
        let radius = currentStrokeWidth * 3.0 // includes glow halo
        guard startIndex > 0, activePoints.count > startIndex else {
            return bounds
        }
        let slice = activePoints[max(0, startIndex - 1)...]
        guard let first = slice.first else { return bounds }
        var minX = CGFloat(first.x), maxX = minX
        var minY = CGFloat(first.y), maxY = minY
        for p in slice {
            minX = min(minX, CGFloat(p.x)); maxX = max(maxX, CGFloat(p.x))
            minY = min(minY, CGFloat(p.y)); maxY = max(maxY, CGFloat(p.y))
        }
        return CGRect(
            x: minX - radius, y: minY - radius,
            width: maxX - minX + radius * 2,
            height: maxY - minY + radius * 2
        ).intersection(bounds)
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isReplaying, let touch = touches.first else { return }

        let loc = touch.location(in: self)
        let duration = Date().timeIntervalSince1970 - touchStartTime
        let dx = loc.x - touchStartPoint.x
        let dy = loc.y - touchStartPoint.y
        let isTap = !hasMovedSignificantly && (dx * dx + dy * dy < 64) && (duration < 0.4)

        if isColorFillMode && isTap {
            activePoints.removeAll()
            lastRenderedIndex = 0
            delegate?.canvasDidTapToFill(at: loc)
            return
        }

        if let coalesced = event?.coalescedTouches(for: touch), !coalesced.isEmpty {
            for cTouch in coalesced { addPoint(PointF(cTouch.location(in: self))) }
        } else {
            addPoint(PointF(loc))
        }
        canvasLogger.debug("touchEnded, \(self.activePoints.count) points")
        finishActiveStroke()
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        activePoints.removeAll()
        lastRenderedIndex = 0
        setNeedsDisplay()
    }

    private func finishActiveStroke() {
        guard !activePoints.isEmpty else { return }

        let smoothed: [PointF]
        if activePoints.count <= 2 {
            smoothed = activePoints
        } else {
            smoothed = StrokeInterpolator.downsamplePoints(activePoints, minDistance: 2.0)
        }
        guard !smoothed.isEmpty else {
            activePoints.removeAll()
            lastRenderedIndex = 0
            setNeedsDisplay()
            return
        }

        let action: EditAction
        if isEraser {
            let erase = EraseEditAction(
                points: smoothed,
                strokeWidth: Float(currentStrokeWidth * 1.5),
                timestampMs: activeTimestampMs
            )
            action = .erase(erase)
        } else {
            let stroke = StrokeEditAction(
                points: smoothed,
                color: currentColor.argbInt,
                strokeWidth: Float(currentStrokeWidth),
                alpha: Float(currentAlpha),
                toolType: currentBrushId,
                seed: activeSeed,
                timestampMs: activeTimestampMs
            )
            action = .stroke(stroke)
        }

        // Commit stroke to bitmap synchronously into cache, THEN clear live stroke.
        // This guarantees the canvas never has a blank gap/flash!
        commitActionToBitmapSync(action)
        activePoints.removeAll()
        lastRenderedIndex = 0
        setNeedsDisplay()

        // Notify delegate
        delegate?.canvasDidCommitStroke(action)
    }

    // MARK: - Snapshot & PNG Export

    public func snapshot() -> UIImage {
        let size = bounds.size
        guard size.width > 0, size.height > 0 else { return UIImage() }
        let scale = renderScale
        UIGraphicsBeginImageContextWithOptions(size, true, scale)
        defer { UIGraphicsEndImageContext() }
        if let ctx = UIGraphicsGetCurrentContext() {
            ctx.setFillColor(UIColor.black.cgColor)
            ctx.fill(CGRect(origin: .zero, size: size))
            fillLayer?.draw(in: CGRect(origin: .zero, size: size))
            committedBitmap?.draw(in: CGRect(origin: .zero, size: size))
            templateUIImage?.draw(in: CGRect(origin: .zero, size: size))
        }
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }

    public func exportCompositePNG() -> UIImage {
        let size = bounds.size
        guard size.width > 0, size.height > 0 else { return UIImage() }
        let scale = renderScale
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        fillLayer?.draw(in: CGRect(origin: .zero, size: size))
        committedBitmap?.draw(in: CGRect(origin: .zero, size: size))
        templateUIImage?.draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }
}
