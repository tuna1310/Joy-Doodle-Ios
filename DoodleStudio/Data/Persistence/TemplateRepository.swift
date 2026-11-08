import Foundation
import UIKit
import os

// MARK: - TemplateRepository
// Loads templates from `index.json` and line-art PNGs from the app bundle.
// Supports both flattened bundle resources and folder references (templates/images/).

private let repoLogger = Logger(subsystem: "com.doodlestudio.app", category: "TemplateRepository")

public protocol TemplateRepositoryProtocol {
    func getTemplates() -> [Template]
    func getTemplateById(_ id: String) -> Template?
    func loadTemplateImage(_ template: Template) -> UIImage?
    func clearCache()
}

public final class TemplateRepository: TemplateRepositoryProtocol {
    public static let shared = TemplateRepository()

    private var cachedTemplates: [Template] = []
    private let imageCache = NSCache<NSString, UIImage>()

    public init() {
        imageCache.countLimit = 40
        loadTemplates()
    }

    private var candidateBundles: [Bundle] {
        var bundles = [Bundle.main]
        let classBundle = Bundle(for: TemplateRepository.self)
        if !bundles.contains(classBundle) {
            bundles.append(classBundle)
        }
        return bundles
    }

    public func clearCache() {
        imageCache.removeAllObjects()
    }

    private func loadTemplates() {
        var data: Data? = nil
        var resolvedURL: URL? = nil

        for bundle in candidateBundles {
            let possibleURLs = [
                bundle.url(forResource: "index", withExtension: "json", subdirectory: "templates"),
                bundle.url(forResource: "index", withExtension: "json"),
                bundle.bundleURL.appendingPathComponent("templates/index.json"),
                bundle.bundleURL.appendingPathComponent("index.json")
            ]

            for url in possibleURLs {
                if let u = url, let d = try? Data(contentsOf: u) {
                    data = d
                    resolvedURL = u
                    break
                }
            }
            if data != nil { break }
        }

        // Fallback: search anywhere in bundle
        if data == nil {
            for bundle in candidateBundles {
                if let fallback = bundle.urls(forResourcesWithExtension: "json", subdirectory: nil)?.first(where: { $0.lastPathComponent == "index.json" }),
                   let d = try? Data(contentsOf: fallback) {
                    data = d
                    resolvedURL = fallback
                    break
                }
            }
        }

        guard let jsonData = data else {
            repoLogger.error("Failed to find index.json in any bundle")
            return
        }

        do {
            let decoded = try JSONDecoder().decode([Template].self, from: jsonData)
            self.cachedTemplates = decoded
            repoLogger.info("Loaded \(decoded.count) templates successfully from: \(resolvedURL?.path ?? "unknown")")
        } catch {
            repoLogger.error("Failed to decode index.json: \(error.localizedDescription)")
        }
    }

    public func getTemplates() -> [Template] {
        if cachedTemplates.isEmpty {
            loadTemplates()
        }
        return cachedTemplates
    }

    public func getTemplateById(_ id: String) -> Template? {
        return getTemplates().first { $0.id == id }
    }

    public func loadTemplateImage(_ template: Template) -> UIImage? {
        let cacheKey = template.id as NSString
        if let cached = imageCache.object(forKey: cacheKey) {
            return cached
        }

        let baseName = (template.imagePath as NSString).lastPathComponent
        let nameWithoutExt = (baseName as NSString).deletingPathExtension

        var foundImage: UIImage? = nil
        var resolvedPath: String? = nil

        for bundle in candidateBundles {
            // 1. Direct path inside bundle directory
            let directPaths = [
                bundle.bundlePath + "/templates/images/" + baseName,
                bundle.bundlePath + "/images/" + baseName,
                bundle.bundlePath + "/" + baseName,
                bundle.bundlePath + "/" + template.imagePath
            ]
            for p in directPaths {
                if FileManager.default.fileExists(atPath: p),
                   let img = UIImage(contentsOfFile: p) {
                    foundImage = img
                    resolvedPath = p
                    break
                }
            }
            if foundImage != nil { break }

            // 2. Bundle URL lookup with subdirectories
            let subdirs = ["templates/images", "images", "templates", nil]
            for sub in subdirs {
                if let url = bundle.url(forResource: nameWithoutExt, withExtension: "png", subdirectory: sub),
                   let img = UIImage(contentsOfFile: url.path) {
                    foundImage = img
                    resolvedPath = url.path
                    break
                }
            }
            if foundImage != nil { break }

            // 3. Bundle.main.path
            if let p = bundle.path(forResource: template.imagePath, ofType: nil) ??
                       bundle.path(forResource: nameWithoutExt, ofType: "png") {
                if let img = UIImage(contentsOfFile: p) {
                    foundImage = img
                    resolvedPath = p
                    break
                }
            }

            // 4. Asset catalog or loose named image
            if let img = UIImage(named: nameWithoutExt, in: bundle, with: nil) ??
                         UIImage(named: baseName, in: bundle, with: nil) {
                foundImage = img
                resolvedPath = "named:\(nameWithoutExt)"
                break
            }
        }

        if let img = foundImage {
            imageCache.setObject(img, forKey: cacheKey)
            repoLogger.info("Loaded template image for '\(template.id)' from \(resolvedPath ?? "unknown"), size=\(img.size.width)x\(img.size.height)")
            return img
        } else {
            repoLogger.error("Could NOT find template image for '\(template.id)' (path: \(template.imagePath), name: \(nameWithoutExt))")
            return nil
        }
    }
}
