import Foundation

// MARK: - Template (matches Android's Template data class)
public struct Template: Codable, Equatable, Identifiable {
    public var id: String
    public var stt: Int
    public var openclipartId: String
    public var titleEn: String
    public var titleVi: String
    public var category: String
    public var categoryId: String
    public var artist: String
    public var license: String
    public var imagePath: String       // e.g. "templates/images/template_01_330237.png"
    public var fillableAreaPct: String
    public var significantRegions: Int
    public var description: String
    public var nameEn: String
    public var nameVi: String
    public var difficulty: String
    public var regionCountHint: Int

    // Convenience
    public var displayTitleEn: String { nameEn.isEmpty ? titleEn : nameEn }
    public var displayTitleVi: String { nameVi.isEmpty ? titleVi : nameVi }
}

// MARK: - Template Index
public struct TemplateIndex: Codable {
    public var templates: [Template]

    public init(templates: [Template]) {
        self.templates = templates
    }

    // Decode from a bare JSON array (the index.json is a top-level array)
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var items: [Template] = []
        while !container.isAtEnd {
            let t = try container.decode(Template.self)
            items.append(t)
        }
        self.templates = items
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        for t in templates {
            try container.encode(t)
        }
    }
}

// MARK: - Category grouping
public struct TemplateCategory: Equatable, Identifiable {
    public var id: String     // categoryId
    public var name: String   // localized display name
    public var templates: [Template]

    public static func groupByCategory(_ templates: [Template], locale: String = "vi") -> [TemplateCategory] {
        var seen: [String: Int] = [:]
        var categories: [TemplateCategory] = []
        for t in templates {
            if let idx = seen[t.categoryId] {
                categories[idx].templates.append(t)
            } else {
                seen[t.categoryId] = categories.count
                let displayName = locale == "vi" ? t.category : t.categoryId
                categories.append(TemplateCategory(id: t.categoryId, name: displayName, templates: [t]))
            }
        }
        return categories
    }
}

