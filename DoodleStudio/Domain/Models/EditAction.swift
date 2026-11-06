import Foundation

// MARK: - EditAction (matches Android's sealed EditAction class)
// Same JSON field names as Android for cross-platform ActionLog compatibility.

public enum EditActionType: String, Codable {
    case stroke = "stroke"
    case erase  = "erase"
    case fill   = "fill"
}

/// Sealed-protocol-like enum matching Android's EditAction sealed class.
/// JSON keys match Android exactly: "type", "points", "color", "strokeWidth",
/// "alpha", "toolType", "seed", "timestampMs", "regionId", "normalizedX", "normalizedY"
public enum EditAction: Codable, Equatable {
    case stroke(StrokeEditAction)
    case erase(EraseEditAction)
    case fill(FillEditAction)

    // MARK: Codable
    private enum CodingKeys: String, CodingKey {
        case type
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(EditActionType.self, forKey: .type)
        switch type {
        case .stroke:
            self = .stroke(try StrokeEditAction(from: decoder))
        case .erase:
            self = .erase(try EraseEditAction(from: decoder))
        case .fill:
            self = .fill(try FillEditAction(from: decoder))
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .stroke(let s): try s.encode(to: encoder)
        case .erase(let e):  try e.encode(to: encoder)
        case .fill(let f):   try f.encode(to: encoder)
        }
    }

    public var timestampMs: Int64 {
        switch self {
        case .stroke(let s): return s.timestampMs
        case .erase(let e):  return e.timestampMs
        case .fill(let f):   return f.timestampMs
        }
    }
}

// MARK: - Stroke action (free-hand drawing)
public struct StrokeEditAction: Codable, Equatable {
    public let type: EditActionType
    public var points: [PointF]
    public var color: Int          // ARGB int (same as Android)
    public var strokeWidth: Float
    public var alpha: Float
    public var toolType: String    // brush id, e.g. "CLASSIC_NEON"
    public var seed: Int64
    public var timestampMs: Int64

    public init(
        points: [PointF],
        color: Int,
        strokeWidth: Float,
        alpha: Float = 1.0,
        toolType: String = "CLASSIC_NEON",
        seed: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        timestampMs: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.type = .stroke
        self.points = points
        self.color = color
        self.strokeWidth = strokeWidth
        self.alpha = alpha
        self.toolType = toolType
        self.seed = seed
        self.timestampMs = timestampMs
    }
}

// MARK: - Erase action
public struct EraseEditAction: Codable, Equatable {
    public let type: EditActionType
    public var points: [PointF]
    public var strokeWidth: Float
    public var timestampMs: Int64

    public init(
        points: [PointF],
        strokeWidth: Float,
        timestampMs: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.type = .erase
        self.points = points
        self.strokeWidth = strokeWidth
        self.timestampMs = timestampMs
    }
}

// MARK: - Fill action (coloring region)
public struct FillEditAction: Codable, Equatable {
    public let type: EditActionType
    public var regionId: Int
    public var color: Int          // ARGB int
    public var prevColor: Int      // For undo support (default 0)
    public var normalizedX: Float
    public var normalizedY: Float
    public var timestampMs: Int64

    public init(
        regionId: Int,
        color: Int,
        prevColor: Int = 0,
        normalizedX: Float = 0.0,
        normalizedY: Float = 0.0,
        timestampMs: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.type = .fill
        self.regionId = regionId
        self.color = color
        self.prevColor = prevColor
        self.normalizedX = normalizedX
        self.normalizedY = normalizedY
        self.timestampMs = timestampMs
    }

    private enum CodingKeys: String, CodingKey {
        case type, regionId, color, prevColor, normalizedX, normalizedY, timestampMs
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = .fill
        self.regionId = try container.decode(Int.self, forKey: .regionId)
        self.color = try container.decode(Int.self, forKey: .color)
        self.prevColor = try container.decodeIfPresent(Int.self, forKey: .prevColor) ?? 0
        self.normalizedX = try container.decodeIfPresent(Float.self, forKey: .normalizedX) ?? 0.0
        self.normalizedY = try container.decodeIfPresent(Float.self, forKey: .normalizedY) ?? 0.0
        self.timestampMs = try container.decodeIfPresent(Int64.self, forKey: .timestampMs) ?? 0
    }
}
