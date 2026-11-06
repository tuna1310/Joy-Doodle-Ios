import UIKit
import CoreGraphics

public protocol NeonCanvasViewDelegate: AnyObject {
    func canvasDidAddStroke(_ stroke: StrokeAction)
    func canvasDidBeginDrawing()
}

public final class NeonCanvasView: UIView {
    public weak var delegate: NeonCanvasViewDelegate?
    
    // Drawing settings
    public var currentTool: BrushTool = .neon
    public var currentStyle: BrushStyle = .neonGlow
    public var currentColor: UIColor = UIColor(AppColors.neonYellow)
    public var currentStrokeWidth: CGFloat = 10.0
    public var currentAlpha: CGFloat = 1.0
    
    // Internal touch tracking
    private var activePoints: [CGPoint] = []
    private var activeStrokeTimestamp: Int64 = 0
    
    // Double-buffered rendering:
    // 1. committedImage: holds all committed strokes rendered so far
    private var committedImage: UIImage?
    // 2. allStrokes: complete history of strokes
    private var strokes: [StrokeAction] = []
    
    // Replay mode state
    public var isReplaying: Bool = false
    private var replayCompletedStrokes: [StrokeAction] = []
    private var replayActiveStroke: StrokeAction? = nil
    
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
        layer.drawsAsynchronously = true
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        if committedImage == nil && bounds.width > 0 && bounds.height > 0 {
            redrawAllCommittedStrokes()
        }
    }
    
    // MARK: - External API
    
    public func setStrokes(_ newStrokes: [StrokeAction]) {
        self.strokes = newStrokes
        redrawAllCommittedStrokes()
    }
    
    public func clear() {
        strokes.removeAll()
        committedImage = nil
        activePoints.removeAll()
        setNeedsDisplay()
    }
    
    public func setReplayState(completed: [StrokeAction], active: StrokeAction?) {
        self.isReplaying = true
        self.replayCompletedStrokes = completed
        self.replayActiveStroke = active
        setNeedsDisplay()
    }
    
    public func exitReplayMode() {
        self.isReplaying = false
        self.replayCompletedStrokes.removeAll()
        self.replayActiveStroke = nil
        redrawAllCommittedStrokes()
    }
    
    // MARK: - Redraw Cache
    
    public func redrawAllCommittedStrokes() {
        guard bounds.width > 0 && bounds.height > 0 else { return }
        
        let size = bounds.size
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = true
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let img = renderer.image { ctx in
            let cg = ctx.cgContext
            cg.setFillColor(UIColor.black.cgColor)
            cg.fill(CGRect(origin: .zero, size: size))
            
            for stroke in strokes {
                NeonStrokeRenderer.render(stroke: stroke, in: cg, bounds: CGRect(origin: .zero, size: size))
            }
        }
        self.committedImage = img
        setNeedsDisplay()
    }
    
    private func commitStrokeToCache(_ stroke: StrokeAction) {
        guard bounds.width > 0 && bounds.height > 0 else { return }
        
        let size = bounds.size
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = true
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let img = renderer.image { ctx in
            let cg = ctx.cgContext
            
            if let existing = committedImage {
                existing.draw(in: CGRect(origin: .zero, size: size))
            } else {
                cg.setFillColor(UIColor.black.cgColor)
                cg.fill(CGRect(origin: .zero, size: size))
            }
            
            NeonStrokeRenderer.render(stroke: stroke, in: cg, bounds: CGRect(origin: .zero, size: size))
        }
        self.committedImage = img
        setNeedsDisplay()
    }
    
    // MARK: - Touch Handling
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isReplaying, let touch = touches.first else { return }
        delegate?.canvasDidBeginDrawing()
        
        let point = touch.location(in: self)
        activePoints = [point]
        activeStrokeTimestamp = Int64(Date().timeIntervalSince1970 * 1000)
        setNeedsDisplay()
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isReplaying, let touch = touches.first else { return }
        
        // Use coalesced touches for highest fidelity and smoothness
        if let coalesced = event?.coalescedTouches(for: touch), !coalesced.isEmpty {
            for cTouch in coalesced {
                activePoints.append(cTouch.location(in: self))
            }
        } else {
            activePoints.append(touch.location(in: self))
        }
        
        setNeedsDisplay()
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isReplaying, let touch = touches.first else { return }
        
        if let coalesced = event?.coalescedTouches(for: touch), !coalesced.isEmpty {
            for cTouch in coalesced {
                activePoints.append(cTouch.location(in: self))
            }
        } else {
            activePoints.append(touch.location(in: self))
        }
        
        finishActiveStroke()
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        activePoints.removeAll()
        setNeedsDisplay()
    }
    
    private func finishActiveStroke() {
        guard activePoints.count >= 1 else {
            activePoints.removeAll()
            return
        }
        
        let stroke = StrokeAction(
            id: UUID(),
            points: activePoints.map { Point($0) },
            color: CodableColor(uiColor: currentColor),
            strokeWidth: Double(currentStrokeWidth),
            alpha: Double(currentAlpha),
            toolType: currentTool,
            style: currentStyle,
            timestampMs: activeStrokeTimestamp
        )
        
        strokes.append(stroke)
        activePoints.removeAll()
        
        commitStrokeToCache(stroke)
        delegate?.canvasDidAddStroke(stroke)
    }
    
    // MARK: - Drawing Pass
    
    public override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        if isReplaying {
            // Replay mode: render completed replay strokes and partial active stroke
            context.setFillColor(UIColor.black.cgColor)
            context.fill(rect)
            
            for stroke in replayCompletedStrokes {
                NeonStrokeRenderer.render(stroke: stroke, in: context, bounds: bounds)
            }
            if let partial = replayActiveStroke {
                NeonStrokeRenderer.render(stroke: partial, in: context, bounds: bounds)
            }
            return
        }
        
        // Normal mode: 
        // 1. Draw cached image of all committed strokes
        if let cached = committedImage {
            cached.draw(in: bounds)
        } else {
            context.setFillColor(UIColor.black.cgColor)
            context.fill(bounds)
        }
        
        // 2. Draw live active stroke on top
        if !activePoints.isEmpty {
            let activeStroke = StrokeAction(
                points: activePoints.map { Point($0) },
                color: CodableColor(uiColor: currentColor),
                strokeWidth: Double(currentStrokeWidth),
                alpha: Double(currentAlpha),
                toolType: currentTool,
                style: currentStyle,
                timestampMs: activeStrokeTimestamp
            )
            NeonStrokeRenderer.render(stroke: activeStroke, in: context, bounds: bounds)
        }
    }
    
    public func snapshot() -> UIImage {
        if let committed = committedImage {
            return committed
        }
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { ctx in
            self.layer.render(in: ctx.cgContext)
        }
    }
}
