import Foundation
import UIKit
import Combine

public final class ArtworkRepository: ObservableObject {
    public static let shared = ArtworkRepository()
    
    @Published public private(set) var artworks: [Artwork] = []
    
    private let fileStore = FileStore.shared
    private let fileManager = FileManager.default
    
    private var indexUrl: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("artworks_index.json")
    }
    
    public init() {
        loadIndex()
    }
    
    public func loadIndex() {
        guard fileManager.fileExists(atPath: indexUrl.path),
              let data = try? Data(contentsOf: indexUrl),
              let items = try? JSONDecoder().decode([Artwork].self, from: data) else {
            self.artworks = []
            return
        }
        self.artworks = items.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    private func saveIndex() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        if let data = try? encoder.encode(artworks) {
            try? data.write(to: indexUrl, options: .atomic)
        }
    }
    
    public func save(
        id: UUID,
        title: String,
        strokes: [StrokeAction],
        thumbnail: UIImage,
        canvasSize: CGSize
    ) {
        do {
            let thumbPath = try fileStore.saveThumbnail(thumbnail, for: id)
            
            let actionLog = ActionLog(
                version: 1,
                artworkId: id.uuidString,
                canvasWidth: Double(canvasSize.width),
                canvasHeight: Double(canvasSize.height),
                backgroundColor: "#000000",
                actions: strokes,
                totalDurationMs: Int64((strokes.last?.timestampMs ?? 0) - (strokes.first?.timestampMs ?? 0))
            )
            let statePath = try fileStore.saveActionLog(actionLog, for: id)
            
            if let index = artworks.firstIndex(where: { $0.id == id }) {
                artworks[index].updatedAt = Date()
                artworks[index].thumbnailPath = thumbPath
                artworks[index].statePath = statePath
            } else {
                let artwork = Artwork(
                    id: id,
                    title: title,
                    createdAt: Date(),
                    updatedAt: Date(),
                    thumbnailPath: thumbPath,
                    statePath: statePath
                )
                artworks.insert(artwork, at: 0)
            }
            saveIndex()
        } catch {
            print("Failed to save artwork: \(error)")
        }
    }
    
    public func loadStrokes(for id: UUID) -> [StrokeAction]? {
        guard let artwork = artworks.first(where: { $0.id == id }),
              let statePath = artwork.statePath,
              let actionLog = try? fileStore.loadActionLog(from: statePath) else {
            return nil
        }
        return actionLog.actions
    }
    
    public func delete(id: UUID) {
        artworks.removeAll { $0.id == id }
        fileStore.deleteArtworkDirectory(for: id)
        saveIndex()
    }
}
