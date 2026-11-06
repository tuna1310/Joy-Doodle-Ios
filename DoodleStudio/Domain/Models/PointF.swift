import Foundation

// MARK: - PointF (matches Android's PointF data class)
// JSON keys: "x", "y"
public struct PointF: Codable, Equatable {
    public var x: Float
    public var y: Float

    public init(_ x: Float, _ y: Float) {
        self.x = x
        self.y = y
    }

    public init(_ point: CGPoint) {
        self.x = Float(point.x)
        self.y = Float(point.y)
    }

    public var cgPoint: CGPoint { CGPoint(x: CGFloat(x), y: CGFloat(y)) }
}

