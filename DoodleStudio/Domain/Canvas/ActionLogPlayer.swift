import Foundation
import QuartzCore
import Combine

public final class ActionLogPlayer: ObservableObject {
    @Published public private(set) var isPlaying: Bool = false
    @Published public private(set) var progress: Double = 0.0 // 0.0 ... 1.0
    @Published public private(set) var currentTimeMs: Int64 = 0
    @Published public private(set) var totalDurationMs: Int64 = 0
    @Published public var speedMultiplier: Double = 1.0 // 1x, 2x, 4x
    
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var strokes: [StrokeAction] = []
    
    // Callback delivering rendered strokes: (completedStrokes, inProgressStrokePartial)
    public var onUpdate: (([StrokeAction], StrokeAction?) -> Void)?
    public var onPlaybackEnded: (() -> Void)?
    
    public init() {}
    
    deinit {
        stop()
    }
    
    public func load(actions: [StrokeAction]) {
        stop()
        self.strokes = actions.sorted { $0.timestampMs < $1.timestampMs }
        
        guard let first = strokes.first, let last = strokes.last else {
            self.totalDurationMs = 0
            self.currentTimeMs = 0
            self.progress = 0.0
            return
        }
        
        // Calculate duration based on stroke timestamps or synthesize duration if all at 0
        let rawDuration = last.timestampMs - first.timestampMs
        if rawDuration > 500 {
            self.totalDurationMs = rawDuration + 800 // add trailing pause
        } else {
            // Synthesize realistic ~300ms per stroke for smooth playback
            self.totalDurationMs = Int64(max(1000, strokes.count * 400))
        }
        self.currentTimeMs = 0
        self.progress = 0.0
    }
    
    public func play() {
        guard !strokes.isEmpty else { return }
        if progress >= 1.0 {
            seek(progress: 0.0)
        }
        
        isPlaying = true
        lastTimestamp = CACurrentMediaTime()
        startDisplayLink()
    }
    
    public func pause() {
        isPlaying = false
        stopDisplayLink()
    }
    
    public func stop() {
        isPlaying = false
        stopDisplayLink()
        currentTimeMs = 0
        progress = 0.0
        renderCurrentFrame()
    }
    
    public func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    public func cycleSpeed() {
        if speedMultiplier == 1.0 {
            speedMultiplier = 2.0
        } else if speedMultiplier == 2.0 {
            speedMultiplier = 4.0
        } else {
            speedMultiplier = 1.0
        }
    }
    
    public func seek(progress target: Double) {
        let clamped = max(0.0, min(1.0, target))
        self.progress = clamped
        self.currentTimeMs = Int64(Double(totalDurationMs) * clamped)
        renderCurrentFrame()
    }
    
    private func startDisplayLink() {
        stopDisplayLink()
        let link = CADisplayLink(target: self, selector: #selector(handleTick))
        link.add(to: .main, forMode: .common)
        self.displayLink = link
    }
    
    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func handleTick(link: CADisplayLink) {
        let current = link.timestamp
        if lastTimestamp == 0 {
            lastTimestamp = current
            return
        }
        
        let delta = current - lastTimestamp
        lastTimestamp = current
        
        let deltaMs = Int64(delta * 1000.0 * speedMultiplier)
        currentTimeMs += deltaMs
        
        if totalDurationMs > 0 {
            progress = min(1.0, Double(currentTimeMs) / Double(totalDurationMs))
        } else {
            progress = 1.0
        }
        
        renderCurrentFrame()
        
        if currentTimeMs >= totalDurationMs {
            pause()
            progress = 1.0
            onPlaybackEnded?()
        }
    }
    
    public func renderCurrentFrame() {
        guard !strokes.isEmpty else {
            onUpdate?([], nil)
            return
        }
        
        guard let first = strokes.first else { return }
        let baseTime = first.timestampMs
        let isSynthesized = (strokes.last!.timestampMs - first.timestampMs) <= 500
        
        var completed: [StrokeAction] = []
        var activePartial: StrokeAction? = nil
        
        let totalCount = strokes.count
        
        if isSynthesized {
            let strokeDurationMs: Double = Double(totalDurationMs) / Double(totalCount)
            let currentIndexExact = Double(currentTimeMs) / strokeDurationMs
            let fullStrokeCount = Int(floor(currentIndexExact))
            
            for i in 0..<min(fullStrokeCount, totalCount) {
                completed.append(strokes[i])
            }
            
            if fullStrokeCount < totalCount {
                let stroke = strokes[fullStrokeCount]
                let fraction = currentIndexExact - floor(currentIndexExact)
                let pointCount = max(1, Int(Double(stroke.points.count) * fraction))
                let slicedPoints = Array(stroke.points.prefix(pointCount))
                
                var partial = stroke
                partial.points = slicedPoints
                activePartial = partial
            }
        } else {
            let targetAbsoluteTime = baseTime + currentTimeMs
            
            for i in 0..<totalCount {
                let stroke = strokes[i]
                if stroke.timestampMs <= targetAbsoluteTime {
                    // Check if next stroke has started or if this stroke is still unfolding
                    let nextTime = (i + 1 < totalCount) ? strokes[i + 1].timestampMs : (stroke.timestampMs + 600)
                    if targetAbsoluteTime >= nextTime {
                        completed.append(stroke)
                    } else {
                        let duration = max(50, nextTime - stroke.timestampMs)
                        let elapsedInStroke = targetAbsoluteTime - stroke.timestampMs
                        let fraction = min(1.0, max(0.0, Double(elapsedInStroke) / Double(duration)))
                        let pointCount = max(1, Int(Double(stroke.points.count) * fraction))
                        
                        var partial = stroke
                        partial.points = Array(stroke.points.prefix(pointCount))
                        activePartial = partial
                    }
                }
            }
        }
        
        onUpdate?(completed, activePartial)
    }
}
