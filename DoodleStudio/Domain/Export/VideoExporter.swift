import AVFoundation
import CoreGraphics
import CoreVideo
import Photos
import UIKit

public enum VideoExporterError: LocalizedError {
    case emptyActions
    case writerInitFailed
    case pixelBufferCreationFailed
    case exportFailed(String)

    public var errorDescription: String? {
        switch self {
        case .emptyActions: return "Draw something first to export a video."
        case .writerInitFailed: return "Could not initialize video writer."
        case .pixelBufferCreationFailed: return "Could not allocate video frame buffer."
        case .exportFailed(let msg): return "Video export failed: \(msg)"
        }
    }
}

public enum VideoExporter {

    /// Renders the drawing action history as an animated MP4 video at the requested playback speed.
    public static func exportTimelapse(
        actions: [EditAction],
        canvasSize: CGSize,
        backgroundPhoto: UIImage?,
        fillLayer: UIImage?,
        templateImage: UIImage?,
        speed: Double = 1.0,
        fps: Int32 = 30,
        progress: @escaping (Double) -> Void,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        let drawableActions = actions.filter {
            switch $0 { case .stroke, .erase: return true; case .fill: return false }
        }
        guard !drawableActions.isEmpty else {
            DispatchQueue.main.async { completion(.failure(VideoExporterError.emptyActions)) }
            return
        }

        let safeWidth = max(1, canvasSize.width)
        let safeHeight = max(1, canvasSize.height)

        // Target 720px on the shorter side, rounded to even dimensions for H.264
        let scaleFactor = 720.0 / min(safeWidth, safeHeight)
        let outW = max(2, Int((safeWidth * scaleFactor).rounded()) & ~1)
        let outH = max(2, Int((safeHeight * scaleFactor).rounded()) & ~1)
        let outputSize = CGSize(width: outW, height: outH)
        let scaleX = outputSize.width / safeWidth
        let scaleY = outputSize.height / safeHeight

        DispatchQueue.global(qos: .userInitiated).async {
            let fileName = "JoyDoodle_\(Int(Date().timeIntervalSince1970)).mp4"
            let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            try? FileManager.default.removeItem(at: outputURL)

            do {
                let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
                let videoSettings: [String: Any] = [
                    AVVideoCodecKey: AVVideoCodecType.h264,
                    AVVideoWidthKey: outW,
                    AVVideoHeightKey: outH,
                    AVVideoCompressionPropertiesKey: [
                        AVVideoAverageBitRateKey: 4_000_000,
                        AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
                    ]
                ]
                let input = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
                input.expectsMediaDataInRealTime = false

                let attrs: [String: Any] = [
                    kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
                    kCVPixelBufferWidthKey as String: outW,
                    kCVPixelBufferHeightKey as String: outH
                ]
                let adaptor = AVAssetWriterInputPixelBufferAdaptor(
                    assetWriterInput: input,
                    sourcePixelBufferAttributes: attrs
                )

                guard writer.canAdd(input) else {
                    throw VideoExporterError.writerInitFailed
                }
                writer.add(input)
                writer.startWriting()
                writer.startSession(atSourceTime: .zero)

                // Build progressive animation steps
                struct FrameStep {
                    let completedCount: Int
                    let activePartial: EditAction?
                }
                var steps: [FrameStep] = []
                let clampedSpeed = max(0.5, min(speed, 4.0))
                let framesPerStroke = max(2, Int((12.0 / clampedSpeed).rounded()))

                for (idx, action) in drawableActions.enumerated() {
                    switch action {
                    case .stroke(let s):
                        let totalPts = max(1, s.points.count)
                        let subSteps = min(framesPerStroke, totalPts)
                        for step in 1...subSteps {
                            let endIdx = max(1, Int(Double(totalPts) * Double(step) / Double(subSteps)))
                            var partial = s
                            partial.points = Array(s.points.prefix(endIdx))
                            steps.append(FrameStep(completedCount: idx, activePartial: .stroke(partial)))
                        }
                    case .erase(let e):
                        let totalPts = max(1, e.points.count)
                        let subSteps = min(max(2, framesPerStroke / 2), totalPts)
                        for step in 1...subSteps {
                            let endIdx = max(1, Int(Double(totalPts) * Double(step) / Double(subSteps)))
                            var partial = e
                            partial.points = Array(e.points.prefix(endIdx))
                            steps.append(FrameStep(completedCount: idx, activePartial: .erase(partial)))
                        }
                    case .fill:
                        break
                    }
                }
                // Hold final frame for ~1 second
                let holdFrames = Int(fps)
                for _ in 0..<holdFrames {
                    steps.append(FrameStep(completedCount: drawableActions.count, activePartial: nil))
                }

                // Maintain an incremental stroke layer so we don't redraw all previous strokes from scratch
                UIGraphicsBeginImageContextWithOptions(outputSize, false, 1.0)
                guard let strokeLayerCtx = UIGraphicsGetCurrentContext() else {
                    UIGraphicsEndImageContext()
                    throw VideoExporterError.pixelBufferCreationFailed
                }
                strokeLayerCtx.clear(CGRect(origin: .zero, size: outputSize))
                var drawnCompletedCount = 0

                let totalFrames = steps.count
                for frameIndex in 0..<totalFrames {
                    let step = steps[frameIndex]

                    while drawnCompletedCount < step.completedCount {
                        drawAction(
                            drawableActions[drawnCompletedCount],
                            ctx: strokeLayerCtx,
                            scaleX: scaleX,
                            scaleY: scaleY
                        )
                        drawnCompletedCount += 1
                    }
                    let committedSnapshot = UIGraphicsGetImageFromCurrentImageContext()

                    while !input.isReadyForMoreMediaData {
                        Thread.sleep(forTimeInterval: 0.005)
                    }

                    guard let pool = adaptor.pixelBufferPool else {
                        UIGraphicsEndImageContext()
                        throw VideoExporterError.pixelBufferCreationFailed
                    }
                    var pixelBufferOut: CVPixelBuffer?
                    let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &pixelBufferOut)
                    guard status == kCVReturnSuccess, let pixelBuffer = pixelBufferOut else {
                        UIGraphicsEndImageContext()
                        throw VideoExporterError.pixelBufferCreationFailed
                    }

                    CVPixelBufferLockBaseAddress(pixelBuffer, [])
                    if let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) {
                        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
                        let colorSpace = CGColorSpaceCreateDeviceRGB()
                        let bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
                        if let frameCtx = CGContext(
                            data: baseAddress,
                            width: outW,
                            height: outH,
                            bitsPerComponent: 8,
                            bytesPerRow: bytesPerRow,
                            space: colorSpace,
                            bitmapInfo: bitmapInfo
                        ) {
                            // Flip to UIKit top-left coordinate system
                            frameCtx.translateBy(x: 0, y: outputSize.height)
                            frameCtx.scaleBy(x: 1, y: -1)

                            let rect = CGRect(origin: .zero, size: outputSize)
                            frameCtx.setFillColor(UIColor.black.cgColor)
                            frameCtx.fill(rect)

                            UIGraphicsPushContext(frameCtx)
                            if let photo = backgroundPhoto {
                                drawAspectFill(photo, in: rect)
                            }
                            if let fill = fillLayer {
                                fill.draw(in: rect)
                            }
                            if let strokes = committedSnapshot {
                                strokes.draw(in: rect)
                            }
                            if let active = step.activePartial {
                                drawAction(active, ctx: frameCtx, scaleX: scaleX, scaleY: scaleY)
                            }
                            if let template = templateImage {
                                template.draw(in: rect)
                            }
                            UIGraphicsPopContext()
                        }
                    }
                    CVPixelBufferUnlockBaseAddress(pixelBuffer, [])

                    let presentationTime = CMTime(value: CMTimeValue(frameIndex), timescale: fps)
                    adaptor.append(pixelBuffer, withPresentationTime: presentationTime)

                    if frameIndex % 5 == 0 || frameIndex == totalFrames - 1 {
                        let pct = Double(frameIndex + 1) / Double(totalFrames)
                        DispatchQueue.main.async { progress(pct) }
                    }
                }

                UIGraphicsEndImageContext()
                input.markAsFinished()

                let semaphore = DispatchSemaphore(value: 0)
                writer.finishWriting {
                    semaphore.signal()
                }
                semaphore.wait()

                if writer.status == .completed {
                    DispatchQueue.main.async { completion(.success(outputURL)) }
                } else {
                    let msg = writer.error?.localizedDescription ?? "Unknown writer error"
                    DispatchQueue.main.async { completion(.failure(VideoExporterError.exportFailed(msg))) }
                }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }

    public static func saveVideoToPhotosAlbum(url: URL, completion: @escaping (Bool, Error?) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                let err = NSError(
                    domain: "VideoExporter",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Photo library access denied"]
                )
                DispatchQueue.main.async { completion(false, err) }
                return
            }

            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }) { success, error in
                DispatchQueue.main.async { completion(success, error) }
            }
        }
    }

    private static func drawAction(_ action: EditAction, ctx: CGContext, scaleX: CGFloat, scaleY: CGFloat) {
        switch action {
        case .stroke(let s):
            guard !s.points.isEmpty else { return }
            let brush = BrushRegistry.get(s.toolType)
            let color = UIColor(androidArgb: s.color)
            brush.drawCommitted(
                ctx: ctx,
                points: s.points,
                color: color,
                strokeWidth: CGFloat(s.strokeWidth),
                alpha: CGFloat(s.alpha),
                scaleX: scaleX,
                scaleY: scaleY,
                seed: s.seed
            )
        case .erase(let e):
            guard !e.points.isEmpty else { return }
            ctx.saveGState()
            ctx.setBlendMode(.clear)
            ctx.setStrokeColor(UIColor.clear.cgColor)
            let w = CGFloat(e.strokeWidth) * min(scaleX, scaleY)
            ctx.setLineWidth(w)
            ctx.setLineCap(.round)
            ctx.setLineJoin(.round)
            if e.points.count == 1 {
                let p = CGPoint(x: CGFloat(e.points[0].x) * scaleX, y: CGFloat(e.points[0].y) * scaleY)
                ctx.addEllipse(in: CGRect(x: p.x - w * 0.5, y: p.y - w * 0.5, width: w, height: w))
                ctx.fillPath()
            } else {
                let path = CGMutablePath()
                path.move(to: CGPoint(x: CGFloat(e.points[0].x) * scaleX, y: CGFloat(e.points[0].y) * scaleY))
                for i in 1..<e.points.count {
                    path.addLine(to: CGPoint(x: CGFloat(e.points[i].x) * scaleX, y: CGFloat(e.points[i].y) * scaleY))
                }
                ctx.addPath(path)
                ctx.strokePath()
            }
            ctx.restoreGState()
        case .fill:
            break
        }
    }

    private static func drawAspectFill(_ image: UIImage, in rect: CGRect) {
        let imgSize = image.size
        guard imgSize.width > 0, imgSize.height > 0 else { return }
        let scale = max(rect.width / imgSize.width, rect.height / imgSize.height)
        let drawW = imgSize.width * scale
        let drawH = imgSize.height * scale
        let drawRect = CGRect(
            x: rect.midX - drawW / 2.0,
            y: rect.midY - drawH / 2.0,
            width: drawW,
            height: drawH
        )
        image.draw(in: drawRect)
    }
}
