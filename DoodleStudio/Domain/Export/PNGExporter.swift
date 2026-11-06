import UIKit
import Photos

public final class PNGExporter {
    
    public static func renderImage(
        strokes: [StrokeAction],
        size: CGSize,
        backgroundColor: UIColor = .black
    ) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2.0
        format.opaque = true
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            let cg = context.cgContext
            
            // Fill background
            cg.setFillColor(backgroundColor.cgColor)
            cg.fill(CGRect(origin: .zero, size: size))
            
            // Render strokes
            for stroke in strokes {
                NeonStrokeRenderer.render(stroke: stroke, in: cg, bounds: CGRect(origin: .zero, size: size))
            }
        }
    }
    
    public static func saveToPhotosAlbum(image: UIImage, completion: @escaping (Bool, Error?) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                completion(false, NSError(domain: "PNGExporter", code: 1, userInfo: [NSLocalizedDescriptionKey: "Photo library access denied"]))
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, error in
                DispatchQueue.main.async {
                    completion(success, error)
                }
            }
        }
    }
}
