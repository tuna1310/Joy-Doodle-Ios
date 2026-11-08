import XCTest
@testable import DoodleStudio

final class TemplateCatalogTests: XCTestCase {

    func testAllTemplatesExistAndAreValid() {
        let templates = TemplateRepository.shared.getTemplates()
        XCTAssertEqual(templates.count, 40, "Expected exactly 40 templates in catalog")

        for (index, template) in templates.enumerated() {
            XCTAssertFalse(template.id.isEmpty, "Template at index \(index) has empty ID")
            XCTAssertFalse(template.imagePath.isEmpty, "Template \(template.id) has empty imagePath")

            // Load template image
            let image = TemplateRepository.shared.loadTemplateImage(template)
            XCTAssertNotNil(image, "Failed to load template image for '\(template.id)' (path: \(template.imagePath))")

            if let img = image {
                XCTAssertGreaterThan(img.size.width, 0, "Image width must be > 0 for \(template.id)")
                XCTAssertGreaterThan(img.size.height, 0, "Image height must be > 0 for \(template.id)")

                // Build LabelMap for each image: must not crash and must have >= 3 regions
                let labelMap = LabelMapBuilder.buildFromImage(img, dilationPixels: 1)
                XCTAssertNotNil(labelMap, "LabelMapBuilder failed for \(template.id)")
                if let lm = labelMap {
                    XCTAssertGreaterThanOrEqual(
                        lm.regionCount,
                        3,
                        "Template \(template.id) should have at least 3 regions, got \(lm.regionCount)"
                    )
                }
            }
        }
    }
}

