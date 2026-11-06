import Foundation
import UIKit

// MARK: - TemplateRepository
// Loads templates from `templates/index.json` in the app bundle.

public protocol TemplateRepositoryProtocol {
    func getTemplates() -> [Template]
    func getTemplateById(_ id: String) -> Template?
    func loadTemplateImage(_ template: Template) -> UIImage?
}

public final class TemplateRepository: TemplateRepositoryProtocol {
    public static let shared = TemplateRepository()

    private var cachedTemplates: [Template] = []

    public init() {
        loadTemplates()
    }

    private func loadTemplates() {
        // Look for index.json in Bundle
        var url: URL? = Bundle.main.url(forResource: "index", withExtension: "json", subdirectory: "templates")
        if url == nil {
            url = Bundle.main.url(forResource: "index", withExtension: "json")
        }
        if url == nil {
            // Check direct resource path (for tests or SPM)
            if let path = Bundle.main.path(forResource: "templates/index", ofType: "json") {
                url = URL(fileURLWithPath: path)
            }
        }

        guard let jsonURL = url, let data = try? Data(contentsOf: jsonURL) else {
            // Fallback: search anywhere in bundle
            if let fallbackURL = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil)?.first(where: { $0.lastPathComponent == "index.json" }),
               let data = try? Data(contentsOf: fallbackURL) {
                if let decoded = try? JSONDecoder().decode([Template].self, from: data) {
                    self.cachedTemplates = decoded
                    return
                }
            }
            return
        }

        if let decoded = try? JSONDecoder().decode([Template].self, from: data) {
            self.cachedTemplates = decoded
        }
    }

    public func getTemplates() -> [Template] {
        return cachedTemplates
    }

    public func getTemplateById(_ id: String) -> Template? {
        return cachedTemplates.first { $0.id == id }
    }

    public func loadTemplateImage(_ template: Template) -> UIImage? {
        // 1. Try direct file path in bundle
        let baseName = (template.imagePath as NSString).lastPathComponent
        let nameWithoutExt = (baseName as NSString).deletingPathExtension
        
        if let imgURL = Bundle.main.url(forResource: nameWithoutExt, withExtension: "png", subdirectory: "templates/images"),
           let img = UIImage(contentsOfFile: imgURL.path) {
            return img
        }
        if let imgURL = Bundle.main.url(forResource: nameWithoutExt, withExtension: "png"),
           let img = UIImage(contentsOfFile: imgURL.path) {
            return img
        }
        if let path = Bundle.main.path(forResource: template.imagePath, ofType: nil),
           let img = UIImage(contentsOfFile: path) {
            return img
        }
        return UIImage(named: nameWithoutExt)
    }
}

