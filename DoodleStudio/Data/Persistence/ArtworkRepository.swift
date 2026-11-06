import Foundation
import UIKit

// MARK: - ArtworkRepository
// File-based storage: JSON index + per-artwork ActionLog JSON + thumbnail PNG.
// No Core Data dependency; simple and portable.

public final class ArtworkRepository {
    public static let shared = ArtworkRepository()
    private init() { createDirectoriesIfNeeded() }

    // MARK: - Directories
    private var artworksDir: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("artworks", isDirectory: true)
    }
    private var thumbsDir: URL {
        artworksDir.appendingPathComponent("thumbs", isDirectory: true)
    }

    private func createDirectoriesIfNeeded() {
        try? FileManager.default.createDirectory(at: artworksDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: thumbsDir, withIntermediateDirectories: true)
    }

    // MARK: - Index

    private var indexURL: URL {
        artworksDir.appendingPathComponent("index.json")
    }

    private func loadIndex() -> [Artwork] {
        guard let data = try? Data(contentsOf: indexURL),
              let list = try? JSONDecoder().decode([Artwork].self, from: data) else {
            return []
        }
        return list
    }

    private func saveIndex(_ artworks: [Artwork]) {
        let data = try? JSONEncoder().encode(artworks)
        try? data?.write(to: indexURL, options: .atomic)
    }

    // MARK: - Save

    @discardableResult
    public func save(artwork: Artwork, actionLog: ActionLog, thumbnail: UIImage) -> Bool {
        do {
            // Save ActionLog JSON
            let logURL = artworksDir.appendingPathComponent("\(artwork.id)_log.json")
            let jsonString = try actionLog.serialize()
            try jsonString.data(using: .utf8)?.write(to: logURL, options: .atomic)

            // Save thumbnail
            let thumbURL = thumbsDir.appendingPathComponent(artwork.thumbnailFileName)
            if let pngData = thumbnail.pngData() {
                try pngData.write(to: thumbURL, options: .atomic)
            }

            // Update index
            var list = loadIndex()
            if let idx = list.firstIndex(where: { $0.id == artwork.id }) {
                list[idx] = artwork
            } else {
                list.insert(artwork, at: 0)
            }
            saveIndex(list)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Load

    public func loadAllArtworks() -> [Artwork] {
        loadIndex()
    }

    public func loadActionLog(artworkId: String) -> ActionLog? {
        let logURL = artworksDir.appendingPathComponent("\(artworkId)_log.json")
        guard let data = try? Data(contentsOf: logURL),
              let jsonString = String(data: data, encoding: .utf8),
              let log = try? ActionLog.deserialize(from: jsonString) else {
            return nil
        }
        return log
    }

    public func loadThumbnail(artwork: Artwork) -> UIImage? {
        let thumbURL = thumbsDir.appendingPathComponent(artwork.thumbnailFileName)
        return UIImage(contentsOfFile: thumbURL.path)
    }

    public func getArtworkById(_ id: String) -> Artwork? {
        loadIndex().first { $0.id == id }
    }

    // MARK: - Delete

    public func deleteArtwork(id: String) {
        let logURL = artworksDir.appendingPathComponent("\(id)_log.json")
        try? FileManager.default.removeItem(at: logURL)

        var list = loadIndex()
        if let idx = list.firstIndex(where: { $0.id == id }) {
            let thumbFile = list[idx].thumbnailFileName
            let thumbURL = thumbsDir.appendingPathComponent(thumbFile)
            try? FileManager.default.removeItem(at: thumbURL)
            list.remove(at: idx)
        }
        saveIndex(list)
    }

    // MARK: - Draft (auto-save on background)

    public func saveDraft(artworkId: String, actionLog: ActionLog) {
        let draftURL = artworksDir.appendingPathComponent("\(artworkId)_draft.json")
        if let jsonString = try? actionLog.serialize(),
           let data = jsonString.data(using: .utf8) {
            try? data.write(to: draftURL, options: .atomic)
        }
    }

    public func loadDraft(artworkId: String) -> ActionLog? {
        let draftURL = artworksDir.appendingPathComponent("\(artworkId)_draft.json")
        guard let data = try? Data(contentsOf: draftURL),
              let jsonString = String(data: data, encoding: .utf8),
              let log = try? ActionLog.deserialize(from: jsonString) else {
            return nil
        }
        return log
    }

    public func deleteDraft(artworkId: String) {
        let draftURL = artworksDir.appendingPathComponent("\(artworkId)_draft.json")
        try? FileManager.default.removeItem(at: draftURL)
    }
}
