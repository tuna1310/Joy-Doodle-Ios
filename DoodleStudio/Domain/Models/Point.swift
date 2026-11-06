import CoreGraphics
import Foundation

public struct Point: Codable, Equatable {
    public var x: Double
    public var y: Double
    
    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
    
    public init(_ cgPoint: CGPoint) {
        self.x = Double(cgPoint.x)
        self.y = Double(cgPoint.y)
    }
    
    public var cgPoint: CGPoint {
        CGPoint(x: x, y: y)
    }
}
