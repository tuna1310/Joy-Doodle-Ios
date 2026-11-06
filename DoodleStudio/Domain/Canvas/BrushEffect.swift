import CoreGraphics
import UIKit

// MARK: - BrushEffect (port of Android's abstract BrushEffect class)
// All brushes draw into a CGContext and use Core Graphics instead of Android Canvas.

public protocol BrushEffect {
    var id: String { get }
    var displayNameEn: String { get }
    var displayNameVi: String { get }
    var defaultSize: CGFloat { get }

    /// Draw live stroke while finger is on screen (called on every touch move).
    func drawLive(
        ctx: CGContext,
        points: [PointF],
        color: UIColor,
        strokeWidth: CGFloat,
        alpha: CGFloat,
        scaleX: CGFloat,
        scaleY: CGFloat,
        seed: Int64
    )

    /// Draw committed stroke into the persistent bitmap cache.
    /// Must be deterministic for given (points, color, strokeWidth, seed).
    func drawCommitted(
        ctx: CGContext,
        points: [PointF],
        color: UIColor,
        strokeWidth: CGFloat,
        alpha: CGFloat,
        scaleX: CGFloat,
        scaleY: CGFloat,
        seed: Int64
    )

    /// Draw preview icon onto a thumbnail context of given size.
    func drawPreview(ctx: CGContext, width: CGFloat, height: CGFloat)
}

// MARK: - Shared helpers (ported from Android's StrokeBrushes.kt top-level functions)

extension BrushEffect {

    // MARK: Three-pass neon path (outer glow + inner glow + white-hot core)
    func drawThreePassNeonPath(
        ctx: CGContext,
        path: CGPath,
        color: UIColor,
        strokeWidth: CGFloat,
        alpha: CGFloat
    ) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let baseAlpha = alpha.clamped(0, 1)

        // Pass 1: Diffused outer glow
        ctx.saveGState()
        ctx.addPath(path)
        ctx.setLineWidth(strokeWidth * 2.5)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.setShadow(offset: .zero, blur: (strokeWidth * 1.2).clamped(1, 999),
                      color: UIColor(red: r, green: g, blue: b, alpha: baseAlpha * 0.35).cgColor)
        ctx.setStrokeColor(UIColor(red: r, green: g, blue: b, alpha: baseAlpha * 0.35).cgColor)
        ctx.strokePath()
        ctx.restoreGState()

        // Pass 2: Vivid inner glow
        ctx.saveGState()
        ctx.addPath(path)
        ctx.setLineWidth(strokeWidth * 1.4)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.setShadow(offset: .zero, blur: (strokeWidth * 0.5).clamped(1, 999),
                      color: UIColor(red: r, green: g, blue: b, alpha: baseAlpha * 0.75).cgColor)
        ctx.setStrokeColor(UIColor(red: r, green: g, blue: b, alpha: baseAlpha * 0.75).cgColor)
        ctx.strokePath()
        ctx.restoreGState()

        // Pass 3: Electric white-hot core
        let coreR = (r * 0.25 + 1.0 * 0.75).clamped(0, 1)
        let coreG = (g * 0.25 + 1.0 * 0.75).clamped(0, 1)
        let coreB = (b * 0.25 + 1.0 * 0.75).clamped(0, 1)
        ctx.saveGState()
        ctx.addPath(path)
        ctx.setLineWidth(strokeWidth * 0.55)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.setStrokeColor(UIColor(red: coreR, green: coreG, blue: coreB, alpha: baseAlpha * 0.95).cgColor)
        ctx.strokePath()
        ctx.restoreGState()
    }

    // MARK: Build CGPath from points using quadratic Bézier interpolation
    func buildNeonPath(points: [PointF], scaleX: CGFloat, scaleY: CGFloat) -> CGPath? {
        guard points.count >= 2 else { return nil }
        let segments = StrokeInterpolator.interpolateToSegments(points)
        guard !segments.isEmpty else { return nil }

        let path = CGMutablePath()
        path.move(to: CGPoint(x: CGFloat(segments[0].startX) * scaleX,
                              y: CGFloat(segments[0].startY) * scaleY))
        for seg in segments {
            path.addQuadCurve(
                to: CGPoint(x: CGFloat(seg.endX) * scaleX, y: CGFloat(seg.endY) * scaleY),
                control: CGPoint(x: CGFloat(seg.controlX) * scaleX, y: CGFloat(seg.controlY) * scaleY)
            )
        }
        return path
    }

    // MARK: Draw single dot (for single-tap strokes)
    func drawNeonDot(ctx: CGContext, x: CGFloat, y: CGFloat, color: UIColor, strokeWidth: CGFloat, alpha: CGFloat) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let baseAlpha = alpha.clamped(0, 1)

        // Outer glow
        ctx.saveGState()
        ctx.setShadow(offset: .zero, blur: (strokeWidth * 1.2).clamped(1, 999),
                      color: UIColor(red: r, green: g, blue: b, alpha: baseAlpha * 0.35).cgColor)
        ctx.setFillColor(UIColor(red: r, green: g, blue: b, alpha: baseAlpha * 0.35).cgColor)
        ctx.fillEllipse(in: CGRect(x: x - strokeWidth * 1.25, y: y - strokeWidth * 1.25,
                                   width: strokeWidth * 2.5, height: strokeWidth * 2.5))
        ctx.restoreGState()

        // Inner glow
        ctx.saveGState()
        ctx.setShadow(offset: .zero, blur: (strokeWidth * 0.5).clamped(1, 999),
                      color: UIColor(red: r, green: g, blue: b, alpha: baseAlpha * 0.75).cgColor)
        ctx.setFillColor(UIColor(red: r, green: g, blue: b, alpha: baseAlpha * 0.75).cgColor)
        ctx.fillEllipse(in: CGRect(x: x - strokeWidth * 0.7, y: y - strokeWidth * 0.7,
                                   width: strokeWidth * 1.4, height: strokeWidth * 1.4))
        ctx.restoreGState()

        // White core
        ctx.setFillColor(UIColor(red: 1, green: 1, blue: 1, alpha: baseAlpha * 0.95).cgColor)
        ctx.fillEllipse(in: CGRect(x: x - strokeWidth * 0.35, y: y - strokeWidth * 0.35,
                                   width: strokeWidth * 0.7, height: strokeWidth * 0.7))
    }

    // MARK: 5-petal sample flower for previews
    func drawSampleFlower(
        ctx: CGContext,
        width: CGFloat,
        height: CGFloat,
        color: UIColor,
        strokeWidth: CGFloat,
        drawOp: (CGContext, CGPath, UIColor, CGFloat) -> Void
    ) {
        let cx = width * 0.5
        let cy = height * 0.42
        let r = width * 0.22

        for i in 0..<5 {
            let angle = Double(i) * 72.0 * .pi / 180.0 - .pi / 2.0
            let px = cx + CGFloat(cos(angle)) * r
            let py = cy + CGFloat(sin(angle)) * r
            let path = CGPath(ellipseIn: CGRect(x: px - width * 0.12, y: py - width * 0.12,
                                                width: width * 0.24, height: width * 0.24),
                              transform: nil)
            drawOp(ctx, path, color, strokeWidth)
        }
        // Stem
        let stemPath = CGMutablePath()
        stemPath.move(to: CGPoint(x: cx, y: cy + r))
        stemPath.addLine(to: CGPoint(x: cx, y: height * 0.85))
        drawOp(ctx, stemPath, UIColor(red: 0.298, green: 0.686, blue: 0.314, alpha: 1), strokeWidth * 0.9)
    }

    func drawSampleFlowerRainbow(ctx: CGContext, width: CGFloat, height: CGFloat, strokeWidth: CGFloat) {
        let cx = width * 0.5
        let cy = height * 0.42
        let r = width * 0.22
        let colors: [UIColor] = [
            UIColor(hex: 0xFFFF1744), UIColor(hex: 0xFFFF9100), UIColor(hex: 0xFFFFEA00),
            UIColor(hex: 0xFF00E676), UIColor(hex: 0xFF00B0FF)
        ]
        for i in 0..<5 {
            let angle = Double(i) * 72.0 * .pi / 180.0 - .pi / 2.0
            let px = cx + CGFloat(cos(angle)) * r
            let py = cy + CGFloat(sin(angle)) * r
            let path = CGPath(ellipseIn: CGRect(x: px - width * 0.12, y: py - width * 0.12,
                                                width: width * 0.24, height: width * 0.24),
                              transform: nil)
            drawThreePassNeonPath(ctx: ctx, path: path, color: colors[i], strokeWidth: strokeWidth, alpha: 1)
        }
        let stemPath = CGMutablePath()
        stemPath.move(to: CGPoint(x: cx, y: cy + r))
        stemPath.addLine(to: CGPoint(x: cx, y: height * 0.85))
        drawThreePassNeonPath(ctx: ctx, path: stemPath, color: UIColor(hex: 0xFF7C4DFF), strokeWidth: strokeWidth * 0.9, alpha: 1)
    }
}

// MARK: - CGFloat clamp helper
extension CGFloat {
    func clamped(_ lo: CGFloat, _ hi: CGFloat) -> CGFloat {
        Swift.min(Swift.max(self, lo), hi)
    }
}

// MARK: - UIColor from ARGB Int (Android compat)
extension UIColor {
    convenience init(hex argb: UInt32) {
        let a = CGFloat((argb >> 24) & 0xFF) / 255.0
        let r = CGFloat((argb >> 16) & 0xFF) / 255.0
        let g = CGFloat((argb >> 8)  & 0xFF) / 255.0
        let b = CGFloat( argb        & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: a)
    }

    /// From Android's color Int (signed, two's complement 0xFF... values become negative)
    convenience init(androidArgb: Int) {
        let u = UInt32(bitPattern: Int32(truncatingIfNeeded: androidArgb))
        self.init(hex: u)
    }

    var argbInt: Int {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        let ar = Int(a * 255) << 24
        let rr = Int(r * 255) << 16
        let gr = Int(g * 255) << 8
        let br = Int(b * 255)
        return ar | rr | gr | br
    }
}

