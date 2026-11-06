import Foundation

// MARK: - ActionLog (matches Android schema exactly)
// Field names are identical to Android's ActionLog data class.
// This ensures JSON files created on Android can be read on iOS and vice-versa.
public struct ActionLog: Codable, Equatable {
    public var version: Int
    public var artworkId: String
    public var templateId: String?
    public var isBlankCanvas: Bool
    public var canvasWidth: Int
    public var canvasHeight: Int
    public var backgroundColor: Int   // ARGB int, e.g. 0xFF000000.toInt() = -16777216
    public var actions: [EditAction]
    public var totalDurationMs: Int64
    public var createdAt: Int64

    public init(
        version: Int = 1,
        artworkId: String = UUID().uuidString,
        templateId: String? = nil,
        isBlankCanvas: Bool = true,
        canvasWidth: Int = 1024,
        canvasHeight: Int = 1024,
        backgroundColor: Int = Int(bitPattern: 0xFF000000),  // opaque black
        actions: [EditAction] = [],
        totalDurationMs: Int64 = 0,
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.version = version
        self.artworkId = artworkId
        self.templateId = templateId
        self.isBlankCanvas = isBlankCanvas
        self.canvasWidth = canvasWidth
        self.canvasHeight = canvasHeight
        self.backgroundColor = backgroundColor
        self.actions = actions
        self.totalDurationMs = totalDurationMs
        self.createdAt = createdAt
    }
}

// MARK: - JSON serialization helpers
public extension ActionLog {

    static let jsonDecoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    static let jsonEncoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = []  // compact, no pretty-print
        return e
    }()

    static func deserialize(from jsonString: String) throws -> ActionLog {
        guard let data = jsonString.data(using: .utf8) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: [], debugDescription: "Invalid UTF-8 string")
            )
        }
        return try jsonDecoder.decode(ActionLog.self, from: data)
    }

    func serialize() throws -> String {
        let data = try ActionLog.jsonEncoder.encode(self)
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    /// Estimated byte size of serialized JSON
    var estimatedByteSize: Int {
        (try? serialize().utf8.count) ?? 0
    }
}
