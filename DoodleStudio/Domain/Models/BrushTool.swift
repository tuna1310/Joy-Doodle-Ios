import Foundation

public enum BrushTool: String, Codable, CaseIterable {
    case pen = "PEN"
    case marker = "MARKER"
    case neon = "NEON"
    case eraser = "ERASER"
    case rainbow = "RAINBOW"
}

public enum BrushStyle: String, Codable, CaseIterable {
    case neonGlow = "neonGlow"
    case rainbow = "rainbow"
    case solid = "solid"
    case thinGlow = "thinGlow"
    case stars = "stars"
    case sparkles = "sparkles"
    case snowflakes = "snowflakes"
    case hearts = "hearts"
    case bubbles = "bubbles"
    case fireworks = "fireworks"
    
    public var displayName: String {
        switch self {
        case .neonGlow: return "Neon"
        case .rainbow: return "Rainbow"
        case .solid: return "Solid"
        case .thinGlow: return "Thin"
        case .stars: return "Stars"
        case .sparkles: return "Sparkles"
        case .snowflakes: return "Snow"
        case .hearts: return "Hearts"
        case .bubbles: return "Bubbles"
        case .fireworks: return "Fireworks"
        }
    }
}
