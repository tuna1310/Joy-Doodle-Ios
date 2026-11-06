import Foundation

// MARK: - Artwork (metadata stored alongside ActionLog)
public struct Artwork: Codable, Equatable, Identifiable {
    public var id: String
    public var title: String
    public var templateId: String?
    public var isBlankCanvas: Bool
    public var thumbnailFileName: String   // e.g. "artwork_abc123_thumb.png"
    public var createdAt: Int64
    public var updatedAt: Int64

    public init(
        id: String = "artwork_\(UUID().uuidString.prefix(8))",
        title: String = "Neon Doodle",
        templateId: String? = nil,
        isBlankCanvas: Bool = true,
        thumbnailFileName: String = "",
        createdAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        updatedAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.title = title
        self.templateId = templateId
        self.isBlankCanvas = isBlankCanvas
        self.thumbnailFileName = thumbnailFileName.isEmpty ? "\(id)_thumb.png" : thumbnailFileName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
