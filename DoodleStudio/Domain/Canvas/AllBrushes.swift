import CoreGraphics
import UIKit

// MARK: - All 21 Brushes (port of Android's StrokeBrushes.kt + MoreBrushes.kt)
// Order matches Android's BrushRegistry exactly.

// ─────────────────────────────────────────────────────────────────────────────
// 1. Classic Neon Brush
// ─────────────────────────────────────────────────────────────────────────────
public final class ClassicNeonBrush: BrushEffect {
    public let id = "CLASSIC_NEON"
    public let displayNameEn = "Classic Neon"
    public let displayNameVi = "Neon cơ bản"
    public let defaultSize: CGFloat = 14

    public func drawLive(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        drawStroke(ctx: ctx, points: points, color: color, strokeWidth: strokeWidth, alpha: alpha, scaleX: scaleX, scaleY: scaleY)
    }
    public func drawCommitted(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        drawStroke(ctx: ctx, points: points, color: color, strokeWidth: strokeWidth, alpha: alpha, scaleX: scaleX, scaleY: scaleY)
    }

    private func drawStroke(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat) {
        guard !points.isEmpty else { return }
        if points.count == 1 {
            let p = points[0]
            drawNeonDot(ctx: ctx, x: CGFloat(p.x) * scaleX, y: CGFloat(p.y) * scaleY, color: color, strokeWidth: strokeWidth, alpha: alpha)
            return
        }
        guard let path = buildNeonPath(points: points, scaleX: scaleX, scaleY: scaleY) else { return }
        drawThreePassNeonPath(ctx: ctx, path: path, color: color, strokeWidth: strokeWidth, alpha: alpha)
    }

    public func drawPreview(ctx: CGContext, width: CGFloat, height: CGFloat) {
        drawSampleFlower(ctx: ctx, width: width, height: height, color: UIColor(hex: 0xFFFF2D95), strokeWidth: 5) { c, path, col, w in
            self.drawThreePassNeonPath(ctx: c, path: path, color: col, strokeWidth: w, alpha: 1)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Rainbow Glow Brush
// ─────────────────────────────────────────────────────────────────────────────
public final class RainbowGlowBrush: BrushEffect {
    public let id = "RAINBOW_GLOW"
    public let displayNameEn = "Rainbow Glow"
    public let displayNameVi = "Neon cầu vồng"
    public let defaultSize: CGFloat = 14

    public func drawLive(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        drawRainbow(ctx: ctx, points: points, strokeWidth: strokeWidth, alpha: alpha, scaleX: scaleX, scaleY: scaleY, seed: seed)
    }
    public func drawCommitted(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        drawRainbow(ctx: ctx, points: points, strokeWidth: strokeWidth, alpha: alpha, scaleX: scaleX, scaleY: scaleY, seed: seed)
    }

    private func drawRainbow(ctx: CGContext, points: [PointF], strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        guard !points.isEmpty else { return }
        if points.count == 1 {
            let hue = CGFloat(seed % 360) / 360.0
            let c = UIColor(hue: hue, saturation: 1, brightness: 1, alpha: 1)
            ClassicNeonBrush().drawLive(ctx: ctx, points: points, color: c, strokeWidth: strokeWidth, alpha: alpha, scaleX: scaleX, scaleY: scaleY, seed: seed)
            return
        }
        for i in 0..<points.count - 1 {
            let p1 = points[i]; let p2 = points[i + 1]
            let hue = CGFloat(((seed % 360) + Int64(i) * 14) % 360) / 360.0
            let segColor = UIColor(hue: hue, saturation: 1, brightness: 1, alpha: 1)
            let path = CGMutablePath()
            path.move(to: CGPoint(x: CGFloat(p1.x) * scaleX, y: CGFloat(p1.y) * scaleY))
            path.addLine(to: CGPoint(x: CGFloat(p2.x) * scaleX, y: CGFloat(p2.y) * scaleY))
            drawThreePassNeonPath(ctx: ctx, path: path, color: segColor, strokeWidth: strokeWidth, alpha: alpha)
        }
    }

    public func drawPreview(ctx: CGContext, width: CGFloat, height: CGFloat) {
        drawSampleFlowerRainbow(ctx: ctx, width: width, height: height, strokeWidth: 5)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. Calligraphy Ribbon Brush
// ─────────────────────────────────────────────────────────────────────────────
public final class CalligraphyRibbonBrush: BrushEffect {
    public let id = "CALLIGRAPHY_RIBBON"
    public let displayNameEn = "Ribbon"
    public let displayNameVi = "Thư pháp ruy băng"
    public let defaultSize: CGFloat = 16

    public func drawLive(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        drawRibbon(ctx: ctx, points: points, color: color, strokeWidth: strokeWidth, alpha: alpha, scaleX: scaleX, scaleY: scaleY)
    }
    public func drawCommitted(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        drawRibbon(ctx: ctx, points: points, color: color, strokeWidth: strokeWidth, alpha: alpha, scaleX: scaleX, scaleY: scaleY)
    }

    private func drawRibbon(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat) {
        guard !points.isEmpty else { return }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let baseAlpha = alpha.clamped(0, 1)

        if points.count == 1 {
            let p = points[0]
            ctx.setFillColor(color.cgColor)
            ctx.fillEllipse(in: CGRect(x: CGFloat(p.x) * scaleX - strokeWidth * 0.5,
                                       y: CGFloat(p.y) * scaleY - strokeWidth * 0.5,
                                       width: strokeWidth, height: strokeWidth))
            return
        }

        let total = points.count
        for i in 0..<total - 1 {
            let p1 = points[i]; let p2 = points[i + 1]
            let progress = Float(i) / Float(total)
            let taper: CGFloat
            if progress < 0.2 { taper = CGFloat(progress / 0.2).clamped(0.25, 1) }
            else if progress > 0.8 { taper = CGFloat((1 - progress) / 0.2).clamped(0.25, 1) }
            else { taper = 1 }
            let curWidth = strokeWidth * taper

            // Subtle glow
            ctx.saveGState()
            ctx.setShadow(offset: .zero, blur: (curWidth * 0.5).clamped(1, 999),
                          color: UIColor(red: r, green: g, blue: b, alpha: baseAlpha * 0.4).cgColor)
            ctx.setStrokeColor(UIColor(red: r, green: g, blue: b, alpha: baseAlpha * 0.4).cgColor)
            ctx.setLineWidth(curWidth * 1.6)
            ctx.setLineCap(.round)
            ctx.move(to: CGPoint(x: CGFloat(p1.x) * scaleX, y: CGFloat(p1.y) * scaleY))
            ctx.addLine(to: CGPoint(x: CGFloat(p2.x) * scaleX, y: CGFloat(p2.y) * scaleY))
            ctx.strokePath()
            ctx.restoreGState()

            // Sharp ribbon
            ctx.setStrokeColor(UIColor(red: r, green: g, blue: b, alpha: baseAlpha).cgColor)
            ctx.setLineWidth(curWidth)
            ctx.setLineCap(.round)
            ctx.move(to: CGPoint(x: CGFloat(p1.x) * scaleX, y: CGFloat(p1.y) * scaleY))
            ctx.addLine(to: CGPoint(x: CGFloat(p2.x) * scaleX, y: CGFloat(p2.y) * scaleY))
            ctx.strokePath()
        }
    }

    public func drawPreview(ctx: CGContext, width: CGFloat, height: CGFloat) {
        let cx = width * 0.5; let cy = height * 0.55
        func leaf(_ angleDeg: CGFloat, _ len: CGFloat, _ col: UIColor) {
            let rad = angleDeg * .pi / 180.0
            let ex = cx + len * CGFloat(cos(rad)); let ey = cy + len * CGFloat(sin(rad))
            let ctrlX = cx + len * 0.6 * CGFloat(cos(rad - 0.4))
            let ctrlY = cy + len * 0.6 * CGFloat(sin(rad - 0.4))
            let path = CGMutablePath()
            path.move(to: CGPoint(x: cx, y: cy))
            path.addQuadCurve(to: CGPoint(x: ex, y: ey), control: CGPoint(x: ctrlX, y: ctrlY))
            ctx.setStrokeColor(col.cgColor); ctx.setLineWidth(6); ctx.setLineCap(.round)
            ctx.addPath(path); ctx.strokePath()
        }
        leaf(-140, width * 0.35, UIColor(hex: 0xFF00E5FF))
        leaf(-90,  width * 0.4,  UIColor(hex: 0xFFFF2D95))
        leaf(-40,  width * 0.35, UIColor(hex: 0xFFFF9100))
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. Double Stroke Brush
// ─────────────────────────────────────────────────────────────────────────────
public final class DoubleStrokeBrush: BrushEffect {
    public let id = "DOUBLE_STROKE"
    public let displayNameEn = "Double Line"
    public let displayNameVi = "Nét đôi"
    public let defaultSize: CGFloat = 16

    public func drawLive(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        drawDouble(ctx: ctx, points: points, color: color, strokeWidth: strokeWidth, alpha: alpha, scaleX: scaleX, scaleY: scaleY)
    }
    public func drawCommitted(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        drawDouble(ctx: ctx, points: points, color: color, strokeWidth: strokeWidth, alpha: alpha, scaleX: scaleX, scaleY: scaleY)
    }

    private func drawDouble(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat) {
        guard !points.isEmpty else { return }
        if points.count == 1 {
            let p = points[0]
            ctx.setStrokeColor(color.cgColor); ctx.setLineWidth(3)
            ctx.addEllipse(in: CGRect(x: CGFloat(p.x)*scaleX - strokeWidth*0.6, y: CGFloat(p.y)*scaleY - strokeWidth*0.6, width: strokeWidth*1.2, height: strokeWidth*1.2))
            ctx.strokePath()
            return
        }

        let offsetDist = strokeWidth * 0.35
        let lineWidth = max(strokeWidth * 0.28, 2)

        // Outer glow
        if let cPath = buildNeonPath(points: points, scaleX: scaleX, scaleY: scaleY) {
            ctx.saveGState()
            ctx.setShadow(offset: .zero, blur: (strokeWidth * 0.6).clamped(1, 999), color: color.withAlphaComponent(alpha * 0.6).cgColor)
            ctx.setStrokeColor(color.withAlphaComponent(0).cgColor)
            ctx.setLineWidth(strokeWidth * 1.4)
            ctx.addPath(cPath); ctx.strokePath()
            ctx.restoreGState()
        }

        // 2 parallel lines
        for i in 0..<points.count - 1 {
            let p1 = points[i]; let p2 = points[i + 1]
            let dx = (CGFloat(p2.x) - CGFloat(p1.x)) * scaleX
            let dy = (CGFloat(p2.y) - CGFloat(p1.y)) * scaleY
            let len = sqrt(dx * dx + dy * dy)
            guard len > 0.1 else { continue }
            let nx = (-dy / len) * offsetDist; let ny = (dx / len) * offsetDist
            ctx.setStrokeColor(color.cgColor); ctx.setLineWidth(lineWidth); ctx.setLineCap(.round)
            ctx.move(to: CGPoint(x: CGFloat(p1.x)*scaleX + nx, y: CGFloat(p1.y)*scaleY + ny))
            ctx.addLine(to: CGPoint(x: CGFloat(p2.x)*scaleX + nx, y: CGFloat(p2.y)*scaleY + ny))
            ctx.strokePath()
            ctx.move(to: CGPoint(x: CGFloat(p1.x)*scaleX - nx, y: CGFloat(p1.y)*scaleY - ny))
            ctx.addLine(to: CGPoint(x: CGFloat(p2.x)*scaleX - nx, y: CGFloat(p2.y)*scaleY - ny))
            ctx.strokePath()
        }
    }

    public func drawPreview(ctx: CGContext, width: CGFloat, height: CGFloat) {
        drawSampleFlower(ctx: ctx, width: width, height: height, color: UIColor(hex: 0xFFFF5722), strokeWidth: 5) { c, path, col, w in
            c.setStrokeColor(col.cgColor); c.setLineWidth(3)
            c.addPath(path); c.strokePath()
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. Thin Neon Pen
// ─────────────────────────────────────────────────────────────────────────────
public final class ThinNeonPenBrush: BrushEffect {
    public let id = "THIN_NEON_PEN"
    public let displayNameEn = "Thin Neon"
    public let displayNameVi = "Neon mảnh"
    public let defaultSize: CGFloat = 6

    public func drawLive(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        drawThin(ctx: ctx, points: points, color: color, strokeWidth: min(strokeWidth, 8), alpha: alpha, scaleX: scaleX, scaleY: scaleY)
    }
    public func drawCommitted(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        drawThin(ctx: ctx, points: points, color: color, strokeWidth: min(strokeWidth, 8), alpha: alpha, scaleX: scaleX, scaleY: scaleY)
    }

    private func drawThin(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat) {
        guard !points.isEmpty else { return }
        if points.count == 1 {
            let p = points[0]
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.fillEllipse(in: CGRect(x: CGFloat(p.x)*scaleX - strokeWidth*0.6, y: CGFloat(p.y)*scaleY - strokeWidth*0.6, width: strokeWidth*1.2, height: strokeWidth*1.2))
            return
        }
        guard let path = buildNeonPath(points: points, scaleX: scaleX, scaleY: scaleY) else { return }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let ba = alpha.clamped(0, 1)

        // Halo
        ctx.saveGState()
        ctx.setShadow(offset: .zero, blur: (strokeWidth * 0.8).clamped(1, 999),
                      color: UIColor(red: r, green: g, blue: b, alpha: ba * 0.65).cgColor)
        ctx.setStrokeColor(UIColor(red: r, green: g, blue: b, alpha: ba * 0.65).cgColor)
        ctx.setLineWidth(strokeWidth * 2); ctx.setLineCap(.round)
        ctx.addPath(path); ctx.strokePath()
        ctx.restoreGState()

        // White core
        ctx.setStrokeColor(UIColor.white.cgColor)
        ctx.setLineWidth(strokeWidth * 0.7); ctx.setLineCap(.round)
        ctx.addPath(path); ctx.strokePath()
    }

    public func drawPreview(ctx: CGContext, width: CGFloat, height: CGFloat) {
        drawSampleFlower(ctx: ctx, width: width, height: height, color: UIColor(hex: 0xFF00E5FF), strokeWidth: 3) { c, path, col, w in
            c.setStrokeColor(col.cgColor); c.setLineWidth(w); c.setLineCap(.round)
            c.addPath(path); c.strokePath()
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. Crayon / Chalk Spray Brush
// ─────────────────────────────────────────────────────────────────────────────
public final class CrayonChalkBrush: BrushEffect {
    public let id = "CRAYON_CHALK"
    public let displayNameEn = "Crayon"
    public let displayNameVi = "Phấn sáp"
    public let defaultSize: CGFloat = 18

    public func drawLive(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        drawCrayon(ctx: ctx, points: points, color: color, strokeWidth: strokeWidth, alpha: alpha, scaleX: scaleX, scaleY: scaleY, seed: seed)
    }
    public func drawCommitted(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        drawCrayon(ctx: ctx, points: points, color: color, strokeWidth: strokeWidth, alpha: alpha, scaleX: scaleX, scaleY: scaleY, seed: seed)
    }

    private func drawCrayon(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        guard !points.isEmpty else { return }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let ba = alpha.clamped(0, 1)

        if points.count == 1 {
            let p = points[0]; let x = CGFloat(p.x) * scaleX; let y = CGFloat(p.y) * scaleY
            ctx.setFillColor(UIColor(red: r, green: g, blue: b, alpha: ba * 0.85).cgColor)
            ctx.fillEllipse(in: CGRect(x: x - strokeWidth*0.5, y: y - strokeWidth*0.5, width: strokeWidth, height: strokeWidth))
            var rnd = (seed ^ 0x5DEECE66D) & 0xFFFFFFFFFFFF
            ctx.setFillColor(UIColor(red: 1, green: 1, blue: 1, alpha: ba * 0.9).cgColor)
            for _ in 0..<6 {
                rnd = (rnd * 0x5DEECE66D + 0xB) & 0xFFFFFFFFFFFF
                let offAngle = CGFloat((rnd >> 16) % 360) * .pi / 180
                let offDist = CGFloat((rnd >> 32) % 100) / 100.0 * strokeWidth * 0.7
                let ox = x + cos(offAngle) * offDist; let oy = y + sin(offAngle) * offDist
                ctx.fillEllipse(in: CGRect(x: ox - 1.5, y: oy - 1.5, width: 3, height: 3))
            }
            return
        }

        guard let path = buildNeonPath(points: points, scaleX: scaleX, scaleY: scaleY) else { return }

        // Powder layer
        ctx.saveGState()
        ctx.setShadow(offset: .zero, blur: (strokeWidth * 0.45).clamped(1, 999),
                      color: UIColor(red: r, green: g, blue: b, alpha: ba * 0.35).cgColor)
        ctx.setStrokeColor(UIColor(red: r, green: g, blue: b, alpha: ba * 0.35).cgColor)
        ctx.setLineWidth(strokeWidth * 1.35); ctx.setLineCap(.round)
        ctx.addPath(path); ctx.strokePath()
        ctx.restoreGState()

        // Core stroke
        ctx.setStrokeColor(UIColor(red: r, green: g, blue: b, alpha: ba * 0.85).cgColor)
        ctx.setLineWidth(strokeWidth * 0.85); ctx.setLineCap(.round)
        ctx.addPath(path); ctx.strokePath()

        // Grain specks
        let segs = StrokeInterpolator.interpolateToSegments(points)
        var rnd = (seed ^ 0x5DEECE66D) & 0xFFFFFFFFFFFF
        ctx.setFillColor(UIColor(red: 1, green: 1, blue: 1, alpha: ba * 0.75).cgColor)
        for seg in segs {
            for step in 1...3 {
                let t = Float(step) / 4.0
                let pt = StrokeInterpolator.sampleQuad(seg, t: t)
                rnd = (rnd * 0x5DEECE66D + 0xB) & 0xFFFFFFFFFFFF
                let off = CGFloat(((rnd >> 16) % 100)) / 100.0 - 0.5
                let rad = CGFloat(max(1, (rnd >> 32) % 3)) * 0.8
                let ox = CGFloat(pt.x) * scaleX + off * strokeWidth * 0.8
                let oy = CGFloat(pt.y) * scaleY + off * strokeWidth * 0.8
                ctx.fillEllipse(in: CGRect(x: ox - rad, y: oy - rad, width: rad*2, height: rad*2))
            }
        }
    }

    public func drawPreview(ctx: CGContext, width: CGFloat, height: CGFloat) {
        let cx = width * 0.5; let cy = height * 0.45; let r = width * 0.22
        for i in 0..<5 {
            let angle = Double(i) * 72.0 * .pi / 180.0 - .pi / 2.0
            let px = cx + CGFloat(cos(angle)) * r; let py = cy + CGFloat(sin(angle)) * r
            let path = CGPath(ellipseIn: CGRect(x: px-width*0.12, y: py-width*0.12, width: width*0.24, height: width*0.24), transform: nil)
            ctx.saveGState()
            ctx.setShadow(offset: .zero, blur: 3.5, color: UIColor(hex: 0x66FFB300).cgColor)
            ctx.setStrokeColor(UIColor(hex: 0x66FFB300).cgColor); ctx.setLineWidth(8*1.3)
            ctx.addPath(path); ctx.strokePath()
            ctx.restoreGState()
            ctx.setStrokeColor(UIColor(hex: 0xFFFFB300).cgColor); ctx.setLineWidth(8*0.85)
            ctx.addPath(path); ctx.strokePath()
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// 7. Solid Marker Brush
// ─────────────────────────────────────────────────────────────────────────────
public final class SolidMarkerBrush: BrushEffect {
    public let id = "SOLID_MARKER"
    public let displayNameEn = "Solid Marker"
    public let displayNameVi = "Bút dạ khối"
    public let defaultSize: CGFloat = 22

    public func drawLive(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        drawSolid(ctx: ctx, points: points, color: color, strokeWidth: strokeWidth, alpha: alpha, scaleX: scaleX, scaleY: scaleY)
    }
    public func drawCommitted(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        drawSolid(ctx: ctx, points: points, color: color, strokeWidth: strokeWidth, alpha: alpha, scaleX: scaleX, scaleY: scaleY)
    }

    private func drawSolid(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat) {
        guard !points.isEmpty else { return }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let ba = alpha.clamped(0, 1)

        if points.count == 1 {
            let p = points[0]
            ctx.setFillColor(UIColor(red: r, green: g, blue: b, alpha: ba).cgColor)
            ctx.fillEllipse(in: CGRect(x: CGFloat(p.x)*scaleX - strokeWidth*0.5, y: CGFloat(p.y)*scaleY - strokeWidth*0.5, width: strokeWidth, height: strokeWidth))
            return
        }

        guard let path = buildNeonPath(points: points, scaleX: scaleX, scaleY: scaleY) else { return }

        // Solid stroke
        ctx.setStrokeColor(UIColor(red: r, green: g, blue: b, alpha: ba).cgColor)
        ctx.setLineWidth(strokeWidth); ctx.setLineCap(.round); ctx.setLineJoin(.round)
        ctx.addPath(path); ctx.strokePath()

        // Specular highlight
        ctx.setStrokeColor(UIColor(red: 1, green: 1, blue: 1, alpha: ba * 0.35).cgColor)
        ctx.setLineWidth(max(strokeWidth * 0.18, 1.5))
        ctx.addPath(path); ctx.strokePath()
    }

    public func drawPreview(ctx: CGContext, width: CGFloat, height: CGFloat) {
        let cx = width * 0.5; let cy = height * 0.45; let r = width * 0.24
        let colors: [UIColor] = [UIColor(hex: 0xFFFDD835), UIColor(hex: 0xFF43A047), UIColor(hex: 0xFF1E88E5), UIColor(hex: 0xFFE53935), UIColor(hex: 0xFFFB8C00)]
        for i in 0..<5 {
            let angle = Double(i) * 72.0 * .pi / 180.0 - .pi / 2.0
            let px = cx + CGFloat(cos(angle)) * r; let py = cy + CGFloat(sin(angle)) * r
            ctx.setFillColor(colors[i].cgColor)
            ctx.fillEllipse(in: CGRect(x: px-width*0.16, y: py-width*0.16, width: width*0.32, height: width*0.32))
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// 8. Dotted Pearl / Glow Beads Brush
// ─────────────────────────────────────────────────────────────────────────────
public final class DottedPearlBrush: BrushEffect {
    public let id = "DOTTED_PEARL"
    public let displayNameEn = "Dotted Pearl"
    public let displayNameVi = "Chuỗi hạt sáng"
    public let defaultSize: CGFloat = 14

    private let jewelColors: [UIColor] = [
        UIColor(hex: 0xFFFF1744), UIColor(hex: 0xFFFF9100), UIColor(hex: 0xFFFFEA00),
        UIColor(hex: 0xFF00E676), UIColor(hex: 0xFF00B0FF), UIColor(hex: 0xFFD500F9)
    ]

    public func drawLive(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        drawPearls(ctx: ctx, points: points, strokeWidth: strokeWidth, alpha: alpha, scaleX: scaleX, scaleY: scaleY, seed: seed)
    }
    public func drawCommitted(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        drawPearls(ctx: ctx, points: points, strokeWidth: strokeWidth, alpha: alpha, scaleX: scaleX, scaleY: scaleY, seed: seed)
    }

    private func drawPearls(ctx: CGContext, points: [PointF], strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        guard !points.isEmpty else { return }
        let radius = strokeWidth * 0.55
        let stepDist = max(radius * 2.1, 14)
        let ba = alpha.clamped(0, 1)

        func drawSinglePearl(_ x: CGFloat, _ y: CGFloat, _ idx: Int) {
            let pearlColor = jewelColors[abs(Int(seed) + idx) % jewelColors.count]
            var pr: CGFloat = 0, pg: CGFloat = 0, pb: CGFloat = 0, pa: CGFloat = 0
            pearlColor.getRed(&pr, green: &pg, blue: &pb, alpha: &pa)

            // Halo
            ctx.saveGState()
            ctx.setShadow(offset: .zero, blur: (radius * 0.8).clamped(1, 999),
                          color: UIColor(red: pr, green: pg, blue: pb, alpha: ba * 0.45).cgColor)
            ctx.setFillColor(UIColor(red: pr, green: pg, blue: pb, alpha: ba * 0.45).cgColor)
            ctx.fillEllipse(in: CGRect(x: x-radius*1.35, y: y-radius*1.35, width: radius*2.7, height: radius*2.7))
            ctx.restoreGState()

            // Body
            ctx.setFillColor(UIColor(red: pr, green: pg, blue: pb, alpha: ba).cgColor)
            ctx.fillEllipse(in: CGRect(x: x-radius, y: y-radius, width: radius*2, height: radius*2))

            // Specular
            let specR = radius * 0.32
            ctx.setFillColor(UIColor(red: 1, green: 1, blue: 1, alpha: ba * 0.95).cgColor)
            ctx.fillEllipse(in: CGRect(x: x-radius*0.28-specR, y: y-radius*0.28-specR, width: specR*2, height: specR*2))
        }

        if points.count == 1 {
            drawSinglePearl(CGFloat(points[0].x) * scaleX, CGFloat(points[0].y) * scaleY, 0); return
        }

        var beadIdx = 0
        var prevX = CGFloat(points[0].x) * scaleX; var prevY = CGFloat(points[0].y) * scaleY
        var distAcc: CGFloat = 0
        drawSinglePearl(prevX, prevY, beadIdx); beadIdx += 1

        for i in 1..<points.count {
            let curX = CGFloat(points[i].x) * scaleX; let curY = CGFloat(points[i].y) * scaleY
            let dx = curX - prevX; let dy = curY - prevY
            let segLen = sqrt(dx * dx + dy * dy)
            guard segLen > 0.001 else { continue }

            var segRemaining = segLen; var fromX = prevX; var fromY = prevY
            while distAcc + segRemaining >= stepDist {
                let need = stepDist - distAcc; let t = need / segRemaining
                let beadX = fromX + (curX - fromX) * t; let beadY = fromY + (curY - fromY) * t
                drawSinglePearl(beadX, beadY, beadIdx); beadIdx += 1
                fromX = beadX; fromY = beadY; segRemaining -= need; distAcc = 0
            }
            distAcc += segRemaining; prevX = curX; prevY = curY
        }
    }

    public func drawPreview(ctx: CGContext, width: CGFloat, height: CGFloat) {
        let cx = width * 0.5; let cy = height * 0.46; let r = width * 0.25
        for i in 0..<12 {
            let angle = Double(i) * (360.0 / 12.0) * .pi / 180.0 - .pi / 2.0
            let px = cx + CGFloat(cos(angle)) * r; let py = cy + CGFloat(sin(angle)) * r
            ctx.setFillColor(jewelColors[i % jewelColors.count].cgColor)
            ctx.fillEllipse(in: CGRect(x: px-5.5, y: py-5.5, width: 11, height: 11))
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.fillEllipse(in: CGRect(x: px-3, y: py-3, width: 4, height: 4))
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// 9. Soft Blur Shadow Brush
// ─────────────────────────────────────────────────────────────────────────────
public final class SoftBlurBrush: BrushEffect {
    public let id = "SOFT_BLUR"
    public let displayNameEn = "Soft Blur"
    public let displayNameVi = "Neon bóng mờ"
    public let defaultSize: CGFloat = 16

    public func drawLive(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        drawBlur(ctx: ctx, points: points, color: color, strokeWidth: strokeWidth, alpha: alpha, scaleX: scaleX, scaleY: scaleY)
    }
    public func drawCommitted(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        drawBlur(ctx: ctx, points: points, color: color, strokeWidth: strokeWidth, alpha: alpha, scaleX: scaleX, scaleY: scaleY)
    }

    private func drawBlur(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat) {
        guard !points.isEmpty else { return }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let ba = alpha.clamped(0, 1)

        if points.count == 1 {
            let p = points[0]; let x = CGFloat(p.x)*scaleX; let y = CGFloat(p.y)*scaleY
            ctx.saveGState()
            ctx.setShadow(offset: .zero, blur: (strokeWidth*1.5).clamped(1,999), color: UIColor(red:r,green:g,blue:b,alpha:ba*0.25).cgColor)
            ctx.setFillColor(UIColor(red:r,green:g,blue:b,alpha:ba*0.25).cgColor)
            ctx.fillEllipse(in: CGRect(x: x-strokeWidth*1.8, y: y-strokeWidth*1.8, width: strokeWidth*3.6, height: strokeWidth*3.6))
            ctx.restoreGState()
            ctx.saveGState()
            ctx.setShadow(offset: .zero, blur: (strokeWidth*0.5).clamped(1,999), color: UIColor(red:r,green:g,blue:b,alpha:ba*0.65).cgColor)
            ctx.setFillColor(UIColor(red:r,green:g,blue:b,alpha:ba*0.65).cgColor)
            ctx.fillEllipse(in: CGRect(x: x-strokeWidth*0.9, y: y-strokeWidth*0.9, width: strokeWidth*1.8, height: strokeWidth*1.8))
            ctx.restoreGState()
            return
        }

        guard let path = buildNeonPath(points: points, scaleX: scaleX, scaleY: scaleY) else { return }

        // Pass 1: outer
        ctx.saveGState()
        ctx.setShadow(offset: .zero, blur: (strokeWidth*1.4).clamped(1,999), color: UIColor(red:r,green:g,blue:b,alpha:ba*0.22).cgColor)
        ctx.setStrokeColor(UIColor(red:r,green:g,blue:b,alpha:ba*0.22).cgColor)
        ctx.setLineWidth(strokeWidth*3.2); ctx.setLineCap(.round)
        ctx.addPath(path); ctx.strokePath()
        ctx.restoreGState()

        // Pass 2: mid
        ctx.saveGState()
        ctx.setShadow(offset: .zero, blur: (strokeWidth*0.7).clamped(1,999), color: UIColor(red:r,green:g,blue:b,alpha:ba*0.5).cgColor)
        ctx.setStrokeColor(UIColor(red:r,green:g,blue:b,alpha:ba*0.5).cgColor)
        ctx.setLineWidth(strokeWidth*1.7); ctx.setLineCap(.round)
        ctx.addPath(path); ctx.strokePath()
        ctx.restoreGState()

        // Pass 3: core
        ctx.setStrokeColor(UIColor(red:r,green:g,blue:b,alpha:ba*0.85).cgColor)
        ctx.setLineWidth(strokeWidth*0.75); ctx.setLineCap(.round)
        ctx.addPath(path); ctx.strokePath()
    }

    public func drawPreview(ctx: CGContext, width: CGFloat, height: CGFloat) {
        drawSampleFlower(ctx: ctx, width: width, height: height, color: UIColor(hex: 0xFFE040FB), strokeWidth: 8) { c, path, col, w in
            c.saveGState()
            c.setShadow(offset: .zero, blur: 6, color: col.withAlphaComponent(0.8).cgColor)
            c.setStrokeColor(col.cgColor); c.setLineWidth(w)
            c.addPath(path); c.strokePath()
            c.restoreGState()
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// 10. Concentric Rings Brush
// ─────────────────────────────────────────────────────────────────────────────
public final class ConcentricRingsBrush: BrushEffect {
    public let id = "CONCENTRIC_RINGS"
    public let displayNameEn = "Rings"
    public let displayNameVi = "Vòng tròn đồng tâm"
    public let defaultSize: CGFloat = 20

    private let ringColors: [UIColor] = [
        UIColor(hex: 0xFFFFEA00), UIColor(hex: 0xFF00E5FF),
        UIColor(hex: 0xFFFF2D95), UIColor(hex: 0xFF7C4DFF)
    ]

    public func drawLive(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        drawRings(ctx: ctx, points: points, strokeWidth: strokeWidth, alpha: alpha, scaleX: scaleX, scaleY: scaleY, seed: seed)
    }
    public func drawCommitted(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        drawRings(ctx: ctx, points: points, strokeWidth: strokeWidth, alpha: alpha, scaleX: scaleX, scaleY: scaleY, seed: seed)
    }

    private func drawRings(ctx: CGContext, points: [PointF], strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        guard !points.isEmpty else { return }
        let stepDist = max(strokeWidth * 2.2, 28)
        let ba = alpha.clamped(0, 1)

        func drawRingSet(_ x: CGFloat, _ y: CGFloat, _ stampIdx: Int) {
            let shift = abs(Int(seed) + stampIdx) % ringColors.count
            func col(_ offset: Int) -> UIColor {
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                ringColors[(shift + offset) % ringColors.count].getRed(&r, green: &g, blue: &b, alpha: &a)
                return UIColor(red: r, green: g, blue: b, alpha: ba)
            }
            // Fill center
            ctx.setFillColor(col(0).cgColor)
            ctx.fillEllipse(in: CGRect(x: x-strokeWidth*0.22, y: y-strokeWidth*0.22, width: strokeWidth*0.44, height: strokeWidth*0.44))
            // 3 rings
            for ring in 1...3 {
                let radius = strokeWidth * [0.52, 0.86, 1.22][ring-1]
                let alpha2 = ring == 3 ? ba * 0.85 : ba
                ctx.setStrokeColor(col(ring).withAlphaComponent(alpha2).cgColor)
                ctx.setLineWidth(2.4)
                ctx.addEllipse(in: CGRect(x: x-radius, y: y-radius, width: radius*2, height: radius*2))
                ctx.strokePath()
            }
        }

        if points.count == 1 { drawRingSet(CGFloat(points[0].x)*scaleX, CGFloat(points[0].y)*scaleY, 0); return }

        var stampIdx = 0
        var prevX = CGFloat(points[0].x)*scaleX; var prevY = CGFloat(points[0].y)*scaleY
        var distAcc: CGFloat = 0
        drawRingSet(prevX, prevY, stampIdx); stampIdx += 1

        for i in 1..<points.count {
            let curX = CGFloat(points[i].x)*scaleX; let curY = CGFloat(points[i].y)*scaleY
            let dx = curX - prevX; let dy = curY - prevY; let segLen = sqrt(dx*dx+dy*dy)
            guard segLen > 0.001 else { continue }
            var segRemaining = segLen; var fromX = prevX; var fromY = prevY
            while distAcc + segRemaining >= stepDist {
                let need = stepDist - distAcc; let t = need / segRemaining
                let rx = fromX + (curX-fromX)*t; let ry = fromY + (curY-fromY)*t
                drawRingSet(rx, ry, stampIdx); stampIdx += 1
                fromX = rx; fromY = ry; segRemaining -= need; distAcc = 0
            }
            distAcc += segRemaining; prevX = curX; prevY = curY
        }
    }

    public func drawPreview(ctx: CGContext, width: CGFloat, height: CGFloat) {
        let cx = width*0.5; let cy = height*0.5
        ctx.setFillColor(ringColors[0].cgColor)
        ctx.fillEllipse(in: CGRect(x: cx-width*0.08, y: cy-width*0.08, width: width*0.16, height: width*0.16))
        for r in 1...3 {
            ctx.setStrokeColor(ringColors[r % ringColors.count].cgColor); ctx.setLineWidth(2.5)
            let rad = CGFloat(r) * (width*0.12) + width*0.08
            ctx.addEllipse(in: CGRect(x: cx-rad, y: cy-rad, width: rad*2, height: rad*2))
            ctx.strokePath()
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// 11. Sparkler
// ─────────────────────────────────────────────────────────────────────────────
public final class SparklerBrush: BrushEffect {
    public let id = "SPARKLER"
    public let displayNameEn = "Sparkler"
    public let displayNameVi = "Pháo bông que"
    public let defaultSize: CGFloat = 14

    public func drawLive(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        drawSparkler(ctx: ctx, points: points, strokeWidth: strokeWidth, scaleX: scaleX, scaleY: scaleY, seed: seed)
    }
    public func drawCommitted(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        drawSparkler(ctx: ctx, points: points, strokeWidth: strokeWidth, scaleX: scaleX, scaleY: scaleY, seed: seed)
    }

    private func drawSparkler(ctx: CGContext, points: [PointF], strokeWidth: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        ClassicNeonBrush().drawLive(ctx: ctx, points: points, color: UIColor(hex: 0xFFFF9100), strokeWidth: strokeWidth, alpha: 1, scaleX: scaleX, scaleY: scaleY, seed: seed)
        ctx.setStrokeColor(UIColor(hex: 0xFFFFF176).cgColor); ctx.setLineWidth(1.8)
        var i = 0
        while i < points.count {
            let p = points[i]; let x = CGFloat(p.x)*scaleX; let y = CGFloat(p.y)*scaleY
            let len = strokeWidth * 1.5
            ctx.move(to: CGPoint(x: x-len, y: y-len)); ctx.addLine(to: CGPoint(x: x+len, y: y+len)); ctx.strokePath()
            ctx.move(to: CGPoint(x: x-len, y: y+len)); ctx.addLine(to: CGPoint(x: x+len, y: y-len)); ctx.strokePath()
            i += 3
        }
    }

    public func drawPreview(ctx: CGContext, width: CGFloat, height: CGFloat) {
        let cx = width*0.5; let cy = height*0.45; let s = width*0.035
        let path = CGMutablePath()
        path.move(to: CGPoint(x: cx, y: cy+8*s))
        path.addCurve(to: CGPoint(x: cx, y: cy-10*s), control1: CGPoint(x: cx-15*s, y: cy-5*s), control2: CGPoint(x: cx-15*s, y: cy-18*s))
        path.addCurve(to: CGPoint(x: cx, y: cy+8*s), control1: CGPoint(x: cx+15*s, y: cy-18*s), control2: CGPoint(x: cx+15*s, y: cy-5*s))
        ctx.saveGState()
        ctx.setShadow(offset: .zero, blur: 4, color: UIColor(hex: 0xFFFF4081).withAlphaComponent(0.8).cgColor)
        ctx.setStrokeColor(UIColor(hex: 0xFFFF4081).cgColor); ctx.setLineWidth(4)
        ctx.addPath(path); ctx.strokePath()
        ctx.restoreGState()
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// 12. Fireworks Brush
// ─────────────────────────────────────────────────────────────────────────────
public final class FireworksBrush: BrushEffect {
    public let id = "FIREWORKS"
    public let displayNameEn = "Fireworks"
    public let displayNameVi = "Pháo hoa"
    public let defaultSize: CGFloat = 16

    public func drawLive(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        draw(ctx: ctx, points: points, strokeWidth: strokeWidth, scaleX: scaleX, scaleY: scaleY)
    }
    public func drawCommitted(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        draw(ctx: ctx, points: points, strokeWidth: strokeWidth, scaleX: scaleX, scaleY: scaleY)
    }
    private func draw(ctx: CGContext, points: [PointF], strokeWidth: CGFloat, scaleX: CGFloat, scaleY: CGFloat) {
        ctx.setStrokeColor(UIColor(hex: 0xFFFFD700).cgColor); ctx.setLineWidth(2)
        var i = 0
        while i < points.count {
            let p = points[i]; let x = CGFloat(p.x)*scaleX; let y = CGFloat(p.y)*scaleY
            for deg in stride(from: 0, to: 360, by: 45) {
                let rad = CGFloat(deg) * .pi / 180
                ctx.move(to: CGPoint(x: x, y: y))
                ctx.addLine(to: CGPoint(x: x + strokeWidth*1.8*cos(rad), y: y + strokeWidth*1.8*sin(rad)))
                ctx.strokePath()
            }
            i += 6
        }
    }
    public func drawPreview(ctx: CGContext, width: CGFloat, height: CGFloat) {
        let cx = width*0.5; let cy = height*0.5
        ctx.setStrokeColor(UIColor(hex: 0xFFFFD54F).cgColor); ctx.setLineWidth(2)
        for deg in stride(from: 0, to: 360, by: 30) {
            let rad = CGFloat(deg) * .pi / 180
            ctx.move(to: CGPoint(x: cx, y: cy))
            ctx.addLine(to: CGPoint(x: cx + width*0.35*cos(rad), y: cy + width*0.35*sin(rad)))
            ctx.strokePath()
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// 13. Neon Stars
// ─────────────────────────────────────────────────────────────────────────────
public final class NeonStarsBrush: BrushEffect {
    public let id = "NEON_STARS"
    public let displayNameEn = "Stars"
    public let displayNameVi = "Ngôi sao neon"
    public let defaultSize: CGFloat = 16

    public func drawLive(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        draw(ctx: ctx, points: points, strokeWidth: strokeWidth, scaleX: scaleX, scaleY: scaleY)
    }
    public func drawCommitted(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        draw(ctx: ctx, points: points, strokeWidth: strokeWidth, scaleX: scaleX, scaleY: scaleY)
    }
    private func draw(ctx: CGContext, points: [PointF], strokeWidth: CGFloat, scaleX: CGFloat, scaleY: CGFloat) {
        ctx.saveGState()
        ctx.setShadow(offset: .zero, blur: 3, color: UIColor(hex: 0xFFFF4081).cgColor)
        ctx.setStrokeColor(UIColor(hex: 0xFFFF4081).cgColor); ctx.setLineWidth(2.5)
        var i = 0
        while i < points.count {
            let p = points[i]
            ctx.addEllipse(in: CGRect(x: CGFloat(p.x)*scaleX - strokeWidth*0.8, y: CGFloat(p.y)*scaleY - strokeWidth*0.8, width: strokeWidth*1.6, height: strokeWidth*1.6))
            ctx.strokePath()
            i += 5
        }
        ctx.restoreGState()
    }
    public func drawPreview(ctx: CGContext, width: CGFloat, height: CGFloat) {
        ctx.setStrokeColor(UIColor(hex: 0xFFFF4081).cgColor); ctx.setLineWidth(3)
        ctx.addEllipse(in: CGRect(x: width*0.5-width*0.28, y: height*0.5-width*0.28, width: width*0.56, height: width*0.56))
        ctx.strokePath()
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// 14. Cross Sparkles
// ─────────────────────────────────────────────────────────────────────────────
public final class CrossSparklesBrush: BrushEffect {
    public let id = "CROSS_SPARKLES"
    public let displayNameEn = "Sparkles"
    public let displayNameVi = "Kim cương lấp lánh"
    public let defaultSize: CGFloat = 14

    public func drawLive(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        draw(ctx: ctx, points: points, strokeWidth: strokeWidth, scaleX: scaleX, scaleY: scaleY)
    }
    public func drawCommitted(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        draw(ctx: ctx, points: points, strokeWidth: strokeWidth, scaleX: scaleX, scaleY: scaleY)
    }
    private func draw(ctx: CGContext, points: [PointF], strokeWidth: CGFloat, scaleX: CGFloat, scaleY: CGFloat) {
        ctx.setStrokeColor(UIColor.white.cgColor); ctx.setLineWidth(2)
        var i = 0
        while i < points.count {
            let p = points[i]; let x = CGFloat(p.x)*scaleX; let y = CGFloat(p.y)*scaleY; let len = strokeWidth*1.2
            ctx.move(to: CGPoint(x: x-len, y: y)); ctx.addLine(to: CGPoint(x: x+len, y: y)); ctx.strokePath()
            ctx.move(to: CGPoint(x: x, y: y-len)); ctx.addLine(to: CGPoint(x: x, y: y+len)); ctx.strokePath()
            i += 4
        }
    }
    public func drawPreview(ctx: CGContext, width: CGFloat, height: CGFloat) {
        let cx = width*0.5; let cy = height*0.5; let len = width*0.35
        ctx.setStrokeColor(UIColor(hex: 0xFFE1BEE7).cgColor); ctx.setLineWidth(3)
        ctx.move(to: CGPoint(x: cx-len, y: cy)); ctx.addLine(to: CGPoint(x: cx+len, y: cy)); ctx.strokePath()
        ctx.move(to: CGPoint(x: cx, y: cy-len)); ctx.addLine(to: CGPoint(x: cx, y: cy+len)); ctx.strokePath()
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// 15. Bokeh Dots
// ─────────────────────────────────────────────────────────────────────────────
public final class BokehDotsBrush: BrushEffect {
    public let id = "BOKEH_DOTS"
    public let displayNameEn = "Bokeh"
    public let displayNameVi = "Đốm sáng bokeh"
    public let defaultSize: CGFloat = 18

    public func drawLive(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        draw(ctx: ctx, points: points, strokeWidth: strokeWidth, scaleX: scaleX, scaleY: scaleY)
    }
    public func drawCommitted(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        draw(ctx: ctx, points: points, strokeWidth: strokeWidth, scaleX: scaleX, scaleY: scaleY)
    }
    private func draw(ctx: CGContext, points: [PointF], strokeWidth: CGFloat, scaleX: CGFloat, scaleY: CGFloat) {
        ctx.saveGState()
        ctx.setShadow(offset: .zero, blur: strokeWidth*0.5, color: UIColor(hex: 0x88BA68C8).cgColor)
        ctx.setFillColor(UIColor(hex: 0x88BA68C8).cgColor)
        var i = 0
        while i < points.count {
            let p = points[i]; let r = strokeWidth*0.9
            ctx.fillEllipse(in: CGRect(x: CGFloat(p.x)*scaleX-r, y: CGFloat(p.y)*scaleY-r, width: r*2, height: r*2))
            i += 4
        }
        ctx.restoreGState()
    }
    public func drawPreview(ctx: CGContext, width: CGFloat, height: CGFloat) {
        ctx.saveGState()
        ctx.setShadow(offset: .zero, blur: 6, color: UIColor(hex: 0xAAAB47BC).cgColor)
        ctx.setFillColor(UIColor(hex: 0xAAAB47BC).cgColor)
        ctx.fillEllipse(in: CGRect(x: width*0.5-width*0.28, y: height*0.5-width*0.28, width: width*0.56, height: width*0.56))
        ctx.restoreGState()
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// 16. Big Cross Star
// ─────────────────────────────────────────────────────────────────────────────
public final class BigCrossStarBrush: BrushEffect {
    public let id = "BIG_CROSS_STAR"
    public let displayNameEn = "Cross Star"
    public let displayNameVi = "Sao chữ thập"
    public let defaultSize: CGFloat = 16

    public func drawLive(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        draw(ctx: ctx, points: points, strokeWidth: strokeWidth, scaleX: scaleX, scaleY: scaleY)
    }
    public func drawCommitted(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        draw(ctx: ctx, points: points, strokeWidth: strokeWidth, scaleX: scaleX, scaleY: scaleY)
    }
    private func draw(ctx: CGContext, points: [PointF], strokeWidth: CGFloat, scaleX: CGFloat, scaleY: CGFloat) {
        ctx.setStrokeColor(UIColor(hex: 0xFFFF1744).cgColor); ctx.setLineWidth(2.5)
        var i = 0
        while i < points.count {
            let p = points[i]; let x = CGFloat(p.x)*scaleX; let y = CGFloat(p.y)*scaleY; let len = strokeWidth*2
            ctx.move(to: CGPoint(x: x-len, y: y)); ctx.addLine(to: CGPoint(x: x+len, y: y)); ctx.strokePath()
            ctx.move(to: CGPoint(x: x, y: y-len)); ctx.addLine(to: CGPoint(x: x, y: y+len)); ctx.strokePath()
            i += 5
        }
    }
    public func drawPreview(ctx: CGContext, width: CGFloat, height: CGFloat) {
        let cx = width*0.5; let cy = height*0.5
        ctx.setStrokeColor(UIColor(hex: 0xFFFF5252).cgColor); ctx.setLineWidth(3)
        ctx.move(to: CGPoint(x: cx-width*0.35, y: cy)); ctx.addLine(to: CGPoint(x: cx+width*0.35, y: cy)); ctx.strokePath()
        ctx.move(to: CGPoint(x: cx, y: cy-height*0.35)); ctx.addLine(to: CGPoint(x: cx, y: cy+height*0.35)); ctx.strokePath()
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// 17. Purple Sparkles
// ─────────────────────────────────────────────────────────────────────────────
public final class PurpleSparklesBrush: BrushEffect {
    public let id = "PURPLE_SPARKLES"
    public let displayNameEn = "Purple Sparkle"
    public let displayNameVi = "Lấp lánh tím"
    public let defaultSize: CGFloat = 14

    public func drawLive(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        draw(ctx: ctx, points: points, strokeWidth: strokeWidth, scaleX: scaleX, scaleY: scaleY)
    }
    public func drawCommitted(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        draw(ctx: ctx, points: points, strokeWidth: strokeWidth, scaleX: scaleX, scaleY: scaleY)
    }
    private func draw(ctx: CGContext, points: [PointF], strokeWidth: CGFloat, scaleX: CGFloat, scaleY: CGFloat) {
        ctx.setFillColor(UIColor(hex: 0xFFE040FB).cgColor)
        var i = 0
        while i < points.count {
            let p = points[i]; let r = strokeWidth*0.4
            ctx.fillEllipse(in: CGRect(x: CGFloat(p.x)*scaleX-r, y: CGFloat(p.y)*scaleY-r, width: r*2, height: r*2))
            i += 3
        }
    }
    public func drawPreview(ctx: CGContext, width: CGFloat, height: CGFloat) {
        ctx.setFillColor(UIColor(hex: 0xFFEA80FC).cgColor)
        ctx.fillEllipse(in: CGRect(x: width*0.5-width*0.18, y: height*0.5-width*0.18, width: width*0.36, height: width*0.36))
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// 18. Fairy Dust
// ─────────────────────────────────────────────────────────────────────────────
public final class FairyDustBrush: BrushEffect {
    public let id = "FAIRY_DUST"
    public let displayNameEn = "Fairy Dust"
    public let displayNameVi = "Dải bụi tiên"
    public let defaultSize: CGFloat = 14

    public func drawLive(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        draw(ctx: ctx, points: points, strokeWidth: strokeWidth, scaleX: scaleX, scaleY: scaleY)
    }
    public func drawCommitted(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        draw(ctx: ctx, points: points, strokeWidth: strokeWidth, scaleX: scaleX, scaleY: scaleY)
    }
    private func draw(ctx: CGContext, points: [PointF], strokeWidth: CGFloat, scaleX: CGFloat, scaleY: CGFloat) {
        ctx.setFillColor(UIColor(hex: 0xFF40C4FF).cgColor)
        var i = 0
        while i < points.count {
            let p = points[i]; let r = strokeWidth*0.3
            ctx.fillEllipse(in: CGRect(x: CGFloat(p.x)*scaleX-r, y: CGFloat(p.y)*scaleY-r, width: r*2, height: r*2))
            i += 2
        }
    }
    public func drawPreview(ctx: CGContext, width: CGFloat, height: CGFloat) {
        ctx.setFillColor(UIColor(hex: 0xFF40C4FF).cgColor)
        ctx.fillEllipse(in: CGRect(x: width*0.5-width*0.15, y: height*0.5-width*0.15, width: width*0.3, height: width*0.3))
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// 19. Snowflakes
// ─────────────────────────────────────────────────────────────────────────────
public final class SnowflakesBrush: BrushEffect {
    public let id = "SNOWFLAKES"
    public let displayNameEn = "Snowflakes"
    public let displayNameVi = "Hoa tuyết"
    public let defaultSize: CGFloat = 20

    public func drawLive(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        draw(ctx: ctx, points: points, strokeWidth: strokeWidth, scaleX: scaleX, scaleY: scaleY)
    }
    public func drawCommitted(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        draw(ctx: ctx, points: points, strokeWidth: strokeWidth, scaleX: scaleX, scaleY: scaleY)
    }
    private func draw(ctx: CGContext, points: [PointF], strokeWidth: CGFloat, scaleX: CGFloat, scaleY: CGFloat) {
        ctx.setStrokeColor(UIColor(hex: 0xFFB3E5FC).cgColor); ctx.setLineWidth(2)
        var i = 0
        while i < points.count {
            let p = points[i]; let cx = CGFloat(p.x)*scaleX; let cy = CGFloat(p.y)*scaleY; let len = strokeWidth*0.9
            for deg in stride(from: 0, to: 360, by: 60) {
                let rad = CGFloat(deg) * .pi / 180
                ctx.move(to: CGPoint(x: cx, y: cy))
                ctx.addLine(to: CGPoint(x: cx + len*cos(rad), y: cy + len*sin(rad)))
                ctx.strokePath()
            }
            i += 6
        }
    }
    public func drawPreview(ctx: CGContext, width: CGFloat, height: CGFloat) {
        let cx = width*0.5; let cy = height*0.5; let len = width*0.32
        ctx.setStrokeColor(UIColor(hex: 0xFF81D4FA).cgColor); ctx.setLineWidth(2.5)
        for deg in stride(from: 0, to: 360, by: 60) {
            let rad = CGFloat(deg) * .pi / 180
            ctx.move(to: CGPoint(x: cx, y: cy))
            ctx.addLine(to: CGPoint(x: cx + len*cos(rad), y: cy + len*sin(rad)))
            ctx.strokePath()
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// 20. Heart Bubbles
// ─────────────────────────────────────────────────────────────────────────────
public final class HeartBubblesBrush: BrushEffect {
    public let id = "HEART_BUBBLES"
    public let displayNameEn = "Heart Bubbles"
    public let displayNameVi = "Bong bóng tim"
    public let defaultSize: CGFloat = 22

    public func drawLive(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        draw(ctx: ctx, points: points, strokeWidth: strokeWidth, scaleX: scaleX, scaleY: scaleY)
    }
    public func drawCommitted(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        draw(ctx: ctx, points: points, strokeWidth: strokeWidth, scaleX: scaleX, scaleY: scaleY)
    }
    private func draw(ctx: CGContext, points: [PointF], strokeWidth: CGFloat, scaleX: CGFloat, scaleY: CGFloat) {
        ctx.setStrokeColor(UIColor(hex: 0xFFFF5252).cgColor); ctx.setLineWidth(2.5)
        var i = 0
        while i < points.count {
            let p = points[i]; let r = strokeWidth*0.6
            ctx.addEllipse(in: CGRect(x: CGFloat(p.x)*scaleX-r, y: CGFloat(p.y)*scaleY-r, width: r*2, height: r*2))
            ctx.strokePath()
            i += 5
        }
    }
    public func drawPreview(ctx: CGContext, width: CGFloat, height: CGFloat) {
        ctx.setStrokeColor(UIColor(hex: 0xFFFF1744).cgColor); ctx.setLineWidth(3)
        ctx.addEllipse(in: CGRect(x: width*0.5-width*0.25, y: height*0.5-width*0.25, width: width*0.5, height: width*0.5))
        ctx.strokePath()
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// 21. Soap Bubbles
// ─────────────────────────────────────────────────────────────────────────────
public final class SoapBubblesBrush: BrushEffect {
    public let id = "SOAP_BUBBLES"
    public let displayNameEn = "Soap Bubbles"
    public let displayNameVi = "Bong bóng nước"
    public let defaultSize: CGFloat = 22

    public func drawLive(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        draw(ctx: ctx, points: points, strokeWidth: strokeWidth, scaleX: scaleX, scaleY: scaleY)
    }
    public func drawCommitted(ctx: CGContext, points: [PointF], color: UIColor, strokeWidth: CGFloat, alpha: CGFloat, scaleX: CGFloat, scaleY: CGFloat, seed: Int64) {
        draw(ctx: ctx, points: points, strokeWidth: strokeWidth, scaleX: scaleX, scaleY: scaleY)
    }
    private func draw(ctx: CGContext, points: [PointF], strokeWidth: CGFloat, scaleX: CGFloat, scaleY: CGFloat) {
        ctx.setStrokeColor(UIColor(hex: 0xFF80D8FF).cgColor); ctx.setLineWidth(2.5)
        var i = 0
        while i < points.count {
            let p = points[i]; let r = strokeWidth*0.7
            ctx.addEllipse(in: CGRect(x: CGFloat(p.x)*scaleX-r, y: CGFloat(p.y)*scaleY-r, width: r*2, height: r*2))
            ctx.strokePath()
            i += 5
        }
    }
    public func drawPreview(ctx: CGContext, width: CGFloat, height: CGFloat) {
        ctx.setStrokeColor(UIColor(hex: 0xFF40C4FF).cgColor); ctx.setLineWidth(3)
        ctx.addEllipse(in: CGRect(x: width*0.5-width*0.28, y: height*0.5-width*0.28, width: width*0.56, height: width*0.56))
        ctx.strokePath()
    }
}

