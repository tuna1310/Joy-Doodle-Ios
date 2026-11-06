import UIKit
import AVFoundation
import CoreGraphics

public final class TimelapseExporter {
    
    public static func exportVideo(
        strokes: [StrokeAction],
        outputSize: CGSize = CGSize(width: 720, height: 1280),
        fps: Int32 = 30,
        targetDurationSeconds: Double = 5.0,
        progressHandler: ((Double) -> Void)? = nil,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        guard !strokes.isEmpty else {
            completion(.failure(NSError(domain: "TimelapseExporter", code: 2, userInfo: [NSLocalizedDescriptionKey: "No strokes to export"])))
            return
        }
        
        let tempUrl = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
        
        if FileManager.default.fileExists(atPath: tempUrl.path) {
            try? FileManager.default.removeItem(at: tempUrl)
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let videoWriter = try AVAssetWriter(outputURL: tempUrl, fileType: .mp4)
                
                let videoSettings: [String: Any] = [
                    AVVideoCodecKey: AVVideoCodecType.h264,
                    AVVideoWidthKey: Int(outputSize.width),
                    AVVideoHeightKey: Int(outputSize.height),
                    AVVideoCompressionPropertiesKey: [
                        AVVideoAverageBitRateKey: 4_000_000,
                        AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
                    ]
                ]
                
                let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
                writerInput.expectsMediaDataInRealTime = false
                
                let pixelBufferAttributes: [String: Any] = [
                    kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
                    kCVPixelBufferWidthKey as String: Int(outputSize.width),
                    kCVPixelBufferHeightKey as String: Int(outputSize.height),
                    kCVPixelBufferCGImageCompatibilityKey as String: true,
                    kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
                ]
                
                let adaptor = AVAssetWriterInputPixelBufferAdaptor(
                    assetWriterInput: writerInput,
                    sourcePixelBufferAttributes: pixelBufferAttributes
                )
                
                videoWriter.add(writerInput)
                videoWriter.startWriting()
                videoWriter.startSession(atSourceTime: .zero)
                
                let totalFrames = Int(Double(fps) * targetDurationSeconds)
                let frameDuration = CMTime(value: 1, timescale: fps)
                
                let sortedStrokes = strokes.sorted { $0.timestampMs < $1.timestampMs }
                let totalStrokes = sortedStrokes.count
                
                for frameIndex in 0..<totalFrames {
                    while !writerInput.isReadyForMoreMediaData {
                        Thread.sleep(forTimeInterval: 0.005)
                    }
                    
                    let frameProgress = Double(frameIndex) / Double(max(1, totalFrames - 1))
                    let strokeLimit = max(1, Int(ceil(Double(totalStrokes) * frameProgress)))
                    let currentStrokes = Array(sortedStrokes.prefix(strokeLimit))
                    
                    let image = PNGExporter.renderImage(
                        strokes: currentStrokes,
                        size: outputSize,
                        backgroundColor: .black
                    )
                    
                    if let pixelBuffer = pixelBufferFromImage(image: image, size: outputSize) {
                        let presentTime = CMTimeMultiply(frameDuration, multiplier: Int32(frameIndex))
                        adaptor.append(pixelBuffer, withPresentationTime: presentTime)
                    }
                    
                    let progress = Double(frameIndex + 1) / Double(totalFrames)
                    DispatchQueue.main.async {
                        progressHandler?(progress)
                    }
                }
                
                writerInput.markAsFinished()
                videoWriter.finishWriting {
                    DispatchQueue.main.async {
                        if videoWriter.status == .completed {
                            completion(.success(tempUrl))
                        } else {
                            completion(.failure(videoWriter.error ?? NSError(domain: "TimelapseExporter", code: 3, userInfo: [NSLocalizedDescriptionKey: "Video writer failed"])))
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    private static func pixelBufferFromImage(image: UIImage, size: CGSize) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary
        
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width),
            Int(size.height),
            kCVPixelFormatType_32ARGB,
            attrs,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        let pixelData = CVPixelBufferGetBaseAddress(buffer)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: pixelData,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        )
        
        if let cgImage = image.cgImage {
            context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
        
        CVPixelBufferUnlockBaseAddress(buffer, [])
        return buffer
    }
}
