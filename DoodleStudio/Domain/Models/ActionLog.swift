import Foundation

public struct ActionLog: Codable, Equatable {
    public var version: Int
    public var artworkId: String
    public var canvasWidth: Double
    public var canvasHeight: Double
    public var backgroundColor: String
    public var actions: [StrokeAction]
    public var totalDurationMs: Int64
    
    public init(
        version: Int = 1,
        artworkId: String = UUID().uuidString,
        canvasWidth: Double = 1080,
        canvasHeight: Double = 1920,
        backgroundColor: String = "#000000",
        actions: [StrokeAction] = [],
        totalDurationMs: Int64 = 0
    ) {
        self.version = version
        self.artworkId = artworkId
        self.canvasWidth = canvasWidth
        self.canvasHeight = canvasHeight
        self.backgroundColor = backgroundColor
        self.actions = actions
        self.totalDurationMs = totalDurationMs
    }
}
