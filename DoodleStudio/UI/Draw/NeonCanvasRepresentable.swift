import SwiftUI
import UIKit

struct NeonCanvasRepresentable: UIViewRepresentable {
    @Binding var currentTool: BrushTool
    @Binding var currentStyle: BrushStyle
    @Binding var currentColor: Color
    @Binding var currentStrokeWidth: CGFloat
    @Binding var currentAlpha: CGFloat
    
    var strokes: [StrokeAction]
    var isReplaying: Bool
    var replayCompletedStrokes: [StrokeAction]
    var replayActiveStroke: StrokeAction?
    
    var onStrokeAdded: (StrokeAction) -> Void
    var onBeginDrawing: (() -> Void)?
    var onCanvasReady: ((NeonCanvasView) -> Void)?
    
    func makeUIView(context: Context) -> NeonCanvasView {
        let canvas = NeonCanvasView()
        canvas.delegate = context.coordinator
        context.coordinator.canvas = canvas
        onCanvasReady?(canvas)
        return canvas
    }
    
    func updateUIView(_ canvas: NeonCanvasView, context: Context) {
        canvas.currentTool = currentTool
        canvas.currentStyle = currentStyle
        canvas.currentColor = UIColor(currentColor)
        canvas.currentStrokeWidth = currentStrokeWidth
        canvas.currentAlpha = currentAlpha
        
        if isReplaying {
            canvas.setReplayState(completed: replayCompletedStrokes, active: replayActiveStroke)
        } else {
            if canvas.isReplaying {
                canvas.exitReplayMode()
            }
            // Update strokes if history changed (e.g. undo, redo, clear, load)
            if context.coordinator.lastStrokesCount != strokes.count || context.coordinator.lastStrokesId != strokes.last?.id {
                context.coordinator.lastStrokesCount = strokes.count
                context.coordinator.lastStrokesId = strokes.last?.id
                canvas.setStrokes(strokes)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, NeonCanvasViewDelegate {
        var parent: NeonCanvasRepresentable
        weak var canvas: NeonCanvasView?
        var lastStrokesCount: Int = 0
        var lastStrokesId: UUID?
        
        init(_ parent: NeonCanvasRepresentable) {
            self.parent = parent
        }
        
        func canvasDidAddStroke(_ stroke: StrokeAction) {
            lastStrokesCount += 1
            lastStrokesId = stroke.id
            parent.onStrokeAdded(stroke)
        }
        
        func canvasDidBeginDrawing() {
            parent.onBeginDrawing?()
        }
    }
}
