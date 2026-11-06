import Foundation
import UIKit

public final class FileStore {
    public static let shared = FileStore()
    
    private let fileManager = FileManager.default
    
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var artworksDirectory: URL {
        let dir = documentsDirectory.appendingPathComponent("artworks", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    public func artworkDirectory(for id: UUID) -> URL {
        let dir = artworksDirectory.appendingPathComponent(id.uuidString, isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    public func saveActionLog(_ actionLog: ActionLog, for id: UUID) throws -> String {
        let dir = artworkDirectory(for: id)
        let fileUrl = dir.appendingPathComponent("state.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(actionLog)
        try data.write(to: fileUrl, options: .atomic)
        return fileUrl.path
    }
    
    public func loadActionLog(from path: String) throws -> ActionLog {
        let fileUrl = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: fileUrl)
        let decoder = JSONDecoder()
        return try decoder.decode(ActionLog.self, from: data)
    }
    
    public func saveThumbnail(_ image: UIImage, for id: UUID) throws -> String {
        let dir = artworkDirectory(for: id)
        let fileUrl = dir.appendingPathComponent("thumbnail.png")
        if let pngData = image.pngData() {
            try pngData.write(to: fileUrl, options: .atomic)
        }
        return fileUrl.path
    }
    
    public func loadThumbnail(from path: String) -> UIImage? {
        let fileUrl = URL(fileURLWithPath: path)
        guard let data = try? Data(contentsOf: fileUrl) else { return nil }
        return UIImage(data: data)
    }
    
    public func deleteArtworkDirectory(for id: UUID) {
        let dir = artworkDirectory(for: id)
        try? fileManager.removeItem(at: dir)
    }
}
