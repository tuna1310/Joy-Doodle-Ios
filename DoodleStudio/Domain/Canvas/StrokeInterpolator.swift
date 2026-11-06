import CoreGraphics
import UIKit

public struct StrokeInterpolator {
    
    public static func smoothedPath(from points: [CGPoint]) -> UIBezierPath {
        let path = UIBezierPath()
        guard let first = points.first else { return path }
        
        if points.count == 1 {
            path.move(to: first)
            path.addLine(to: CGPoint(x: first.x + 0.1, y: first.y + 0.1))
            return path
        }
        
        if points.count == 2 {
            path.move(to: first)
            path.addLine(to: points[1])
            return path
        }
        
        path.move(to: first)
        for i in 1..<(points.count - 1) {
            let current = points[i]
            let next = points[i + 1]
            let midPoint = CGPoint(
                x: (current.x + next.x) * 0.5,
                y: (current.y + next.y) * 0.5
            )
            path.addQuadCurve(to: midPoint, controlPoint: current)
        }
        
        if let last = points.last {
            path.addLine(to: last)
        }
        
        return path
    }
    
    public static func distance(between p1: CGPoint, and p2: CGPoint) -> CGFloat {
        hypot(p2.x - p1.x, p2.y - p1.y)
    }
    
    public static func totalLength(of points: [CGPoint]) -> CGFloat {
        guard points.count >= 2 else { return 0 }
        var length: CGFloat = 0
        for i in 0..<(points.count - 1) {
            length += distance(between: points[i], and: points[i + 1])
        }
        return length
    }
}
