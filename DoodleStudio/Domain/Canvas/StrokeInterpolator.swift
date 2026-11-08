import CoreGraphics
import UIKit

// MARK: - StrokeInterpolator (port of Android's StrokeInterpolator.kt)
// Converts raw touch points into quadratic Bézier segments for smooth strokes.

public struct QuadSegment {
    public let startX, startY: Float
    public let controlX, controlY: Float
    public let endX, endY: Float
}

public enum StrokeInterpolator {

    public static func interpolateToSegments(_ points: [PointF]) -> [QuadSegment] {
        guard points.count >= 2 else { return [] }

        if points.count == 2 {
            let p0 = points[0]; let p1 = points[1]
            return [QuadSegment(
                startX: p0.x, startY: p0.y,
                controlX: (p0.x + p1.x) / 2, controlY: (p0.y + p1.y) / 2,
                endX: p1.x, endY: p1.y
            )]
        }

        var segments: [QuadSegment] = []
        var prevX = points[0].x
        var prevY = points[0].y

        for i in 1..<points.count {
            let curX = points[i].x; let curY = points[i].y
            let midX = (prevX + curX) / 2; let midY = (prevY + curY) / 2

            let startX = i == 1 ? prevX : (points[i - 2].x + prevX) / 2
            let startY = i == 1 ? prevY : (points[i - 2].y + prevY) / 2

            segments.append(QuadSegment(
                startX: startX, startY: startY,
                controlX: prevX, controlY: prevY,
                endX: midX, endY: midY
            ))
            prevX = curX; prevY = curY
        }

        let lastIdx = points.count - 1
        let lastMidX = (points[lastIdx - 1].x + points[lastIdx].x) / 2
        let lastMidY = (points[lastIdx - 1].y + points[lastIdx].y) / 2
        segments.append(QuadSegment(
            startX: lastMidX, startY: lastMidY,
            controlX: points[lastIdx].x, controlY: points[lastIdx].y,
            endX: points[lastIdx].x, endY: points[lastIdx].y
        ))
        return segments
    }

    /// Sample a point on a quadratic Bézier at parameter t ∈ [0, 1]
    public static func sampleQuad(_ seg: QuadSegment, t: Float) -> PointF {
        let tc = max(0, min(1, t))
        let omt = 1 - tc
        let x = omt * omt * seg.startX + 2 * omt * tc * seg.controlX + tc * tc * seg.endX
        let y = omt * omt * seg.startY + 2 * omt * tc * seg.controlY + tc * tc * seg.endY
        return PointF(x, y)
    }

    /// Downsample points that are closer than minDistance to reduce data size
    public static func downsamplePoints(_ points: [PointF], minDistance: Float = 1.5) -> [PointF] {
        guard points.count > 2 else { return points }
        var result: [PointF] = [points[0]]
        var last = points[0]
        let minDistSq = minDistance * minDistance
        for i in 1..<points.count - 1 {
            let p = points[i]
            let dx = p.x - last.x; let dy = p.y - last.y
            if dx * dx + dy * dy >= minDistSq {
                result.append(p); last = p
            }
        }
        if let last = points.last {
            result.append(last)
        }
        return result
    }
}
