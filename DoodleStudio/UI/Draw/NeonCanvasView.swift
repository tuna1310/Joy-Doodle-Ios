import UIKit
import CoreGraphics

// MARK: - NeonCanvasView
// Core Graphics canvas with double-buffered bitmap cache for 60fps performance.
// Layer ordering (bottom to top):
// 1. Black background
// 2. Fill layer (color flood fill)
// 3. Committed free-draw strokes
// 4. In-progress active stroke (live drawing)
// 5. Template line-art overlay (topmost, never erased or covered)

@MainActor
public protocol NeonCanvasViewDelegate: AnyObject {
    func canvasDidCommitStroke(_ action: EditAction)
    func canvasDidBeginDrawing()
    func canvasDidTapToFill(at point: CGPoint)
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
    private var committedBitmap: UIImage?
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
    }

    // MARK: - Layout
    public override func layoutSubviews() {
        super.layoutSubviews()
        if committedBitmap == nil && bounds.width > 0 && bounds.height > 0 {
            redrawAllCommitted()
        }
    }

    // MARK: - External API

    public func setActions(_ actions: [EditAction]) {
        redrawFromActions(actions)
    }

    public func appendCommittedAction(_ action: EditAction) {
        commitActionToBitmap(action)
    }

    public func clear() {
        committedBitmap = nil
        fillLayer = nil
        activePoints.removeAll()
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

    // MARK: - Bitmap Redraw

    public func redrawAllCommitted() {
        redrawFromActions([])
    }

    public func redrawFromActions(_ actions: [EditAction]) {
        guard bounds.width > 0, bounds.height > 0 else { return }
        let size = bounds.size
        UIGraphicsBeginImageContextWithOptions(size, true, UIScreen.main.scale)
        guard let ctx = UIGraphicsGetCurrentContext() else { UIGraphicsEndImageContext(); return }

        // Black background
        ctx.setFillColor(UIColor.black.cgColor)
        ctx.fill(CGRect(origin: .zero, size: size))

        // All stroke and erase actions
        for action in actions {
            renderAction(action, ctx: ctx, bounds: CGRect(origin: .zero, size: size))
        }

        committedBitmap = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        setNeedsDisplay()
    }

    private func commitActionToBitmap(_ action: EditAction) {
        guard bounds.width > 0, bounds.height > 0 else { return }
        let size = bounds.size
        UIGraphicsBeginImageContextWithOptions(size, true, UIScreen.main.scale)
        guard let ctx = UIGraphicsGetCurrentContext() else { UIGraphicsEndImageContext(); return }

        if let existing = committedBitmap {
            existing.draw(in: CGRect(origin: .zero, size: size))
        } else {
            ctx.setFillColor(UIColor.black.cgColor)
            ctx.fill(CGRect(origin: .zero, size: size))
        }

        renderAction(action, ctx: ctx, bounds: CGRect(origin: .zero, size: size))

        committedBitmap = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        setNeedsDisplay()
    }

    // MARK: - Render Action

    private func renderAction(_ action: EditAction, ctx: CGContext, bounds: CGRect) {
        switch action {
        case .stroke(let s):
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
        } else if let path = buildErasePath(points: points) {
            ctx.addPath(path)
            ctx.strokePath()
        }
        ctx.restoreGState()
    }

    private func buildErasePath(points: [PointF]) -> CGPath? {
        guard points.count >= 2 else { return nil }
        let path = CGMutablePath()
        path.move(to: points[0].cgPoint)
        for i in 1..<points.count {
            path.addLine(to: points[i].cgPoint)
        }
        return path
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
            // Replay mode: 1. Black -> 2. Fill -> 3. Strokes -> 4. Active -> 5. Template
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
        // 1. Black background
        if let cached = committedBitmap {
            cached.draw(in: bounds)
        } else {
            ctx.setFillColor(UIColor.black.cgColor)
            ctx.fill(bounds)
        }

        // 2. Fill Layer (drawn under strokes)
        fillLayer?.draw(in: bounds)

        // 3. Committed bitmap (if exists and redraw needed)
        committedBitmap?.draw(in: bounds)

        // 4. Live active stroke on top
        if !activePoints.isEmpty && hasMovedSignificantly {
            renderActiveStroke(ctx: ctx)
        }

        // 5. Template line-art on top of everything
        templateUIImage?.draw(in: bounds)
    }

    // MARK: - Touch Handling

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isReplaying, let touch = touches.first else { return }
        delegate?.canvasDidBeginDrawing()

        let loc = touch.location(in: self)
        touchStartPoint = loc
        touchStartTime = Date().timeIntervalSince1970
        hasMovedSignificantly = false

        activeSeed = Int64(Date().timeIntervalSince1970 * 1000) ^ Int64(loc.x * 100) ^ Int64(loc.y * 10)
        activeTimestampMs = Int64(Date().timeIntervalSince1970 * 1000)
        activePoints = [PointF(loc)]
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isReplaying, let touch = touches.first else { return }

        let loc = touch.location(in: self)
        let dx = loc.x - touchStartPoint.x
        let dy = loc.y - touchStartPoint.y

        // Check if movement exceeds tap threshold (8pt)
        if !hasMovedSignificantly && (dx * dx + dy * dy > 64) {
            hasMovedSignificantly = true
        }

        // If in fill mode and hasn't moved significantly, don't draw stroke yet
        if isColorFillMode && !hasMovedSignificantly {
            return
        }

        // Apple Pencil pressure support
        if touch.type == .pencil && touch.force > 0 {
            let normalizedForce = max(0.5, min(2.0, touch.force / touch.maximumPossibleForce * 2.0))
            currentStrokeWidth = max(4, currentStrokeWidth * normalizedForce)
        }

        if let coalesced = event?.coalescedTouches(for: touch), !coalesced.isEmpty {
            for cTouch in coalesced {
                let p = PointF(cTouch.location(in: self))
                if let last = activePoints.last {
                    let dpx = p.x - last.x; let dpy = p.y - last.y
                    if dpx * dpx + dpy * dpy >= 1.0 { activePoints.append(p) }
                } else {
                    activePoints.append(p)
                }
            }
        } else {
            let p = PointF(loc)
            activePoints.append(p)
        }
        setNeedsDisplay()
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isReplaying, let touch = touches.first else { return }

        let loc = touch.location(in: self)
        let duration = Date().timeIntervalSince1970 - touchStartTime
        let dx = loc.x - touchStartPoint.x
        let dy = loc.y - touchStartPoint.y
        let isTap = !hasMovedSignificantly && (dx * dx + dy * dy < 64) && (duration < 0.4)

        if isColorFillMode && isTap {
            // TAP TO FILL REGION
            activePoints.removeAll()
            delegate?.canvasDidTapToFill(at: loc)
            return
        }

        // Otherwise commit as drawing stroke
        if let coalesced = event?.coalescedTouches(for: touch), !coalesced.isEmpty {
            for cTouch in coalesced {
                activePoints.append(PointF(cTouch.location(in: self)))
            }
        } else {
            activePoints.append(PointF(loc))
        }
        finishActiveStroke()
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        activePoints.removeAll()
        setNeedsDisplay()
    }

    private func finishActiveStroke() {
        guard !activePoints.isEmpty else { return }

        let smoothed: [PointF]
        if activePoints.count <= 2 {
            smoothed = activePoints
        } else {
            smoothed = StrokeInterpolator.downsamplePoints(activePoints, minDistance: 1.5)
        }
        activePoints.removeAll()

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

        commitActionToBitmap(action)
        delegate?.canvasDidCommitStroke(action)
    }

    // MARK: - Snapshot & PNG Export

    public func snapshot() -> UIImage {
        let size = bounds.size
        guard size.width > 0, size.height > 0 else { return UIImage() }
        UIGraphicsBeginImageContextWithOptions(size, true, UIScreen.main.scale)
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
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }

        fillLayer?.draw(in: CGRect(origin: .zero, size: size))
        committedBitmap?.draw(in: CGRect(origin: .zero, size: size))
        templateUIImage?.draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }
}
