import UIKit
import Photos

public enum PNGExporter {

    /// Saves a UIImage to the user's Photos album
    public static func saveToPhotosAlbum(image: UIImage, completion: @escaping (Bool, Error?) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                let err = NSError(domain: "PNGExporter", code: 1, userInfo: [NSLocalizedDescriptionKey: "Photo library access denied"])
                DispatchQueue.main.async { completion(false, err) }
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
