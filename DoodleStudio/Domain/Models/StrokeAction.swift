import Foundation
import CoreGraphics

public struct StrokeAction: Codable, Equatable, Identifiable {
    public var id: UUID
    public var points: [Point]
    public var color: CodableColor
    public var strokeWidth: Double
    public var alpha: Double
    public var toolType: BrushTool
    public var style: BrushStyle
    public var timestampMs: Int64
    
    public init(
        id: UUID = UUID(),
        points: [Point],
        color: CodableColor,
        strokeWidth: Double,
        alpha: Double = 1.0,
        toolType: BrushTool = .neon,
        style: BrushStyle = .neonGlow,
        timestampMs: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.points = points
        self.color = color
        self.strokeWidth = strokeWidth
        self.alpha = alpha
        self.toolType = toolType
        self.style = style
        self.timestampMs = timestampMs
    }
}
