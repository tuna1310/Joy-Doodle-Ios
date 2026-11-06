import UIKit
import CoreGraphics

public struct NeonStrokeRenderer {
    
    public static func render(
        stroke: StrokeAction,
        in context: CGContext,
        bounds: CGRect
    ) {
        guard !stroke.points.isEmpty else { return }
        let cgPoints = stroke.points.map { $0.cgPoint }
        
        context.saveGState()
        defer { context.restoreGState() }
        
        // Handle eraser tool
        if stroke.toolType == .eraser {
            context.setBlendMode(.clear)
            let path = StrokeInterpolator.smoothedPath(from: cgPoints)
            context.addPath(path.cgPath)
            context.setLineCap(.round)
            context.setLineJoin(.round)
            context.setLineWidth(CGFloat(stroke.strokeWidth))
            context.strokePath()
            return
        }
        
        // Handle decorative stamp brushes (Stars, Sparkles, Snowflakes, Hearts, Bubbles, Fireworks)
        switch stroke.style {
        case .stars, .sparkles, .snowflakes, .hearts, .bubbles, .fireworks:
            renderStampStyle(stroke: stroke, points: cgPoints, in: context)
            return
        case .rainbow:
            renderRainbowStroke(stroke: stroke, points: cgPoints, in: context)
            return
        case .solid:
            renderSolidStroke(stroke: stroke, points: cgPoints, in: context)
            return
        case .thinGlow:
            renderNeonPasses(stroke: stroke, points: cgPoints, in: context, glowScale: 0.5)
            return
        case .neonGlow:
            renderNeonPasses(stroke: stroke, points: cgPoints, in: context, glowScale: 1.0)
            return
        }
    }
    
    // Standard 3-pass Neon Glow: Outer Glow -> Inner Glow -> Core
    private static func renderNeonPasses(
        stroke: StrokeAction,
        points: [CGPoint],
        in context: CGContext,
        glowScale: CGFloat
    ) {
        let baseColor = stroke.color.uiColor
        let width = CGFloat(stroke.strokeWidth)
        let path = StrokeInterpolator.smoothedPath(from: points).cgPath
        
        context.setLineCap(.round)
        context.setLineJoin(.round)
        
        // Pass 1: Outer glow (wide, soft blur, low alpha)
        context.saveGState()
        let outerColor = baseColor.withAlphaComponent(0.28 * CGFloat(stroke.alpha))
        context.setShadow(offset: .zero, blur: width * 1.3 * glowScale, color: outerColor.cgColor)
        context.setStrokeColor(outerColor.cgColor)
        context.setLineWidth(width * 2.5 * glowScale)
        context.addPath(path)
        context.strokePath()
        context.restoreGState()
        
        // Pass 2: Inner glow (medium width, medium alpha)
        context.saveGState()
        let innerColor = baseColor.withAlphaComponent(0.60 * CGFloat(stroke.alpha))
        context.setShadow(offset: .zero, blur: width * 0.6 * glowScale, color: innerColor.cgColor)
        context.setStrokeColor(innerColor.cgColor)
        context.setLineWidth(width * 1.5 * glowScale)
        context.addPath(path)
        context.strokePath()
        context.restoreGState()
        
        // Pass 3: Core (thin, bright, blended 70% toward white)
        context.saveGState()
        let coreColor = blendTowardWhite(color: baseColor, fraction: 0.75).withAlphaComponent(CGFloat(stroke.alpha))
        context.setShadow(offset: .zero, blur: width * 0.25 * glowScale, color: baseColor.cgColor)
        context.setStrokeColor(coreColor.cgColor)
        context.setLineWidth(max(2.0, width * 0.6))
        context.addPath(path)
        context.strokePath()
        context.restoreGState()
    }
    
    // Rainbow stroke: Hue cycles smoothly along stroke segments
    private static func renderRainbowStroke(
        stroke: StrokeAction,
        points: [CGPoint],
        in context: CGContext
    ) {
        guard points.count >= 2 else {
            if let single = points.first {
                let color = UIColor(hue: 0.0, saturation: 1.0, brightness: 1.0, alpha: CGFloat(stroke.alpha))
                drawDot(at: single, radius: CGFloat(stroke.strokeWidth) / 2, color: color, in: context)
            }
            return
        }
        
        let totalLength = StrokeInterpolator.totalLength(of: points)
        var accumulatedLength: CGFloat = 0
        let width = CGFloat(stroke.strokeWidth)
        
        context.setLineCap(.round)
        context.setLineJoin(.round)
        
        for i in 0..<(points.count - 1) {
            let p1 = points[i]
            let p2 = points[i + 1]
            let segDist = StrokeInterpolator.distance(between: p1, and: p2)
            accumulatedLength += segDist
            
            let hue = (totalLength > 0) ? (accumulatedLength / totalLength).truncatingRemainder(dividingBy: 1.0) : 0.0
            let segColor = UIColor(hue: hue, saturation: 1.0, brightness: 1.0, alpha: CGFloat(stroke.alpha))
            
            // Outer glow
            context.saveGState()
            context.setShadow(offset: .zero, blur: width * 1.0, color: segColor.withAlphaComponent(0.35).cgColor)
            context.setStrokeColor(segColor.withAlphaComponent(0.4).cgColor)
            context.setLineWidth(width * 2.2)
            context.move(to: p1)
            context.addLine(to: p2)
            context.strokePath()
            context.restoreGState()
            
            // Core
            context.saveGState()
            let coreColor = blendTowardWhite(color: segColor, fraction: 0.65)
            context.setStrokeColor(coreColor.cgColor)
            context.setLineWidth(max(2.0, width * 0.7))
            context.move(to: p1)
            context.addLine(to: p2)
            context.strokePath()
            context.restoreGState()
        }
    }
    
    // Flat / Solid Marker stroke
    private static func renderSolidStroke(
        stroke: StrokeAction,
        points: [CGPoint],
        in context: CGContext
    ) {
        let color = stroke.color.uiColor.withAlphaComponent(CGFloat(stroke.alpha))
        let path = StrokeInterpolator.smoothedPath(from: points).cgPath
        
        context.saveGState()
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(CGFloat(stroke.strokeWidth))
        context.addPath(path)
        context.strokePath()
        context.restoreGState()
    }
    
    // Stamp-based decorative brushes: stars, hearts, snowflakes, bubbles, etc.
    private static func renderStampStyle(
        stroke: StrokeAction,
        points: [CGPoint],
        in context: CGContext
    ) {
        guard !points.isEmpty else { return }
        let baseColor = stroke.color.uiColor
        let size = CGFloat(stroke.strokeWidth) * 2.0
        let spacing = max(18.0, size * 0.75)
        
        var lastStampPoint: CGPoint? = nil
        var index = 0
        
        for pt in points {
            let shouldStamp: Bool
            if let last = lastStampPoint {
                let dist = StrokeInterpolator.distance(between: last, and: pt)
                shouldStamp = dist >= spacing
            } else {
                shouldStamp = true
            }
            
            if shouldStamp {
                lastStampPoint = pt
                let stampColor = (stroke.toolType == .rainbow)
                    ? UIColor(hue: CGFloat(index % 12) / 12.0, saturation: 1.0, brightness: 1.0, alpha: CGFloat(stroke.alpha))
                    : baseColor.withAlphaComponent(CGFloat(stroke.alpha))
                
                context.saveGState()
                context.setShadow(offset: .zero, blur: size * 0.4, color: stampColor.cgColor)
                
                switch stroke.style {
                case .stars, .sparkles:
                    drawStar(at: pt, radius: size / 2, color: stampColor, in: context)
                case .hearts:
                    drawHeart(at: pt, size: size, color: stampColor, in: context)
                case .snowflakes:
                    drawSnowflake(at: pt, radius: size / 2, color: stampColor, in: context)
                case .bubbles:
                    drawBubble(at: pt, radius: size / 2, color: stampColor, in: context)
                case .fireworks:
                    drawStarburst(at: pt, radius: size / 2, color: stampColor, in: context)
                default:
                    drawStar(at: pt, radius: size / 2, color: stampColor, in: context)
                }
                
                context.restoreGState()
                index += 1
            }
        }
    }
    
    // Helper shapes
    private static func drawDot(at point: CGPoint, radius: CGFloat, color: UIColor, in context: CGContext) {
        context.setFillColor(color.cgColor)
        context.fillEllipse(in: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2))
    }
    
    private static func drawStar(at center: CGPoint, radius: CGFloat, color: UIColor, in context: CGContext) {
        let path = UIBezierPath()
        let pointsOnStar = 5
        let innerRadius = radius * 0.45
        var angle = -CGFloat.pi / 2
        let step = CGFloat.pi / CGFloat(pointsOnStar)
        
        for i in 0..<(pointsOnStar * 2) {
            let r = (i % 2 == 0) ? radius : innerRadius
            let x = center.x + r * cos(angle)
            let y = center.y + r * sin(angle)
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
            angle += step
        }
        path.close()
        
        context.setFillColor(color.cgColor)
        context.addPath(path.cgPath)
        context.fillPath()
    }
    
    private static func drawHeart(at center: CGPoint, size: CGFloat, color: UIColor, in context: CGContext) {
        let path = UIBezierPath()
        let s = size * 0.6
        let topY = center.y - s * 0.5
        
        path.move(to: CGPoint(x: center.x, y: topY + s * 0.3))
        path.addCurve(
            to: CGPoint(x: center.x, y: center.y + s * 0.6),
            controlPoint1: CGPoint(x: center.x - s * 0.8, y: topY - s * 0.2),
            controlPoint2: CGPoint(x: center.x - s * 0.5, y: center.y + s * 0.2)
        )
        path.addCurve(
            to: CGPoint(x: center.x, y: topY + s * 0.3),
            controlPoint1: CGPoint(x: center.x + s * 0.5, y: center.y + s * 0.2),
            controlPoint2: CGPoint(x: center.x + s * 0.8, y: topY - s * 0.2)
        )
        path.close()
        
        context.setFillColor(color.cgColor)
        context.addPath(path.cgPath)
        context.fillPath()
    }
    
    private static func drawSnowflake(at center: CGPoint, radius: CGFloat, color: UIColor, in context: CGContext) {
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(2.0)
        context.setLineCap(.round)
        
        let arms = 6
        let angleStep = (2.0 * CGFloat.pi) / CGFloat(arms)
        for i in 0..<arms {
            let angle = CGFloat(i) * angleStep
            let endX = center.x + radius * cos(angle)
            let endY = center.y + radius * sin(angle)
            context.move(to: center)
            context.addLine(to: CGPoint(x: endX, y: endY))
            
            // Sub-branches
            let branchPos = 0.6 * radius
            let bx = center.x + branchPos * cos(angle)
            let by = center.y + branchPos * sin(angle)
            let branchLen = radius * 0.3
            let bAngle1 = angle + CGFloat.pi / 4
            let bAngle2 = angle - CGFloat.pi / 4
            context.move(to: CGPoint(x: bx, y: by))
            context.addLine(to: CGPoint(x: bx + branchLen * cos(bAngle1), y: by + branchLen * sin(bAngle1)))
            context.move(to: CGPoint(x: bx, y: by))
            context.addLine(to: CGPoint(x: bx + branchLen * cos(bAngle2), y: by + branchLen * sin(bAngle2)))
        }
        context.strokePath()
    }
    
    private static func drawBubble(at center: CGPoint, radius: CGFloat, color: UIColor, in context: CGContext) {
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(2.0)
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        context.strokeEllipse(in: rect)
        
        // Highlight reflection arc
        context.saveGState()
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(1.5)
        let highlightRect = CGRect(x: center.x - radius * 0.7, y: center.y - radius * 0.7, width: radius * 1.4, height: radius * 1.4)
        context.addArc(center: center, radius: radius * 0.7, startAngle: -CGFloat.pi * 0.7, endAngle: -CGFloat.pi * 0.3, clockwise: false)
        context.strokePath()
        context.restoreGState()
    }
    
    private static func drawStarburst(at center: CGPoint, radius: CGFloat, color: UIColor, in context: CGContext) {
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(1.8)
        let rays = 8
        let angleStep = (2.0 * CGFloat.pi) / CGFloat(rays)
        for i in 0..<rays {
            let angle = CGFloat(i) * angleStep
            let r = (i % 2 == 0) ? radius : radius * 0.5
            context.move(to: center)
            context.addLine(to: CGPoint(x: center.x + r * cos(angle), y: center.y + r * sin(angle)))
        }
        context.strokePath()
    }
    
    private static func blendTowardWhite(color: UIColor, fraction: CGFloat) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let newR = r + (1.0 - r) * fraction
        let newG = g + (1.0 - g) * fraction
        let newB = b + (1.0 - b) * fraction
        return UIColor(red: newR, green: newG, blue: newB, alpha: a)
    }
}
