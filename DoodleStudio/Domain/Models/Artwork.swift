import Foundation

public struct Artwork: Identifiable, Codable, Equatable {
    public var id: UUID
    public var title: String
    public var createdAt: Date
    public var updatedAt: Date
    public var thumbnailPath: String?
    public var statePath: String?
    
    public init(
        id: UUID = UUID(),
        title: String = "Untitled",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        thumbnailPath: String? = nil,
        statePath: String? = nil
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.thumbnailPath = thumbnailPath
        self.statePath = statePath
    }
}
