import SwiftUI
import UIKit

// MARK: - NeonCanvasRepresentable
// UIViewRepresentable wrapper connecting NeonCanvasView to SwiftUI.

public struct NeonCanvasRepresentable: UIViewRepresentable {
    @ObservedObject var viewModel: DrawViewModel

    public func makeUIView(context: Context) -> NeonCanvasView {
        let canvasView = NeonCanvasView()
        canvasView.delegate = context.coordinator
        viewModel.canvasView = canvasView
        applySettings(canvasView)
        return canvasView
    }

    public func updateUIView(_ uiView: NeonCanvasView, context: Context) {
        applySettings(uiView)
        if uiView.templateUIImage !== viewModel.templateUIImage {
            uiView.templateUIImage = viewModel.templateUIImage
        }
    }

    private func applySettings(_ view: NeonCanvasView) {
        view.currentBrushId = viewModel.currentBrushId
        view.currentColor = UIColor(viewModel.currentColor)
        view.currentStrokeWidth = viewModel.currentStrokeWidth
        view.currentAlpha = viewModel.currentAlpha
        view.isEraser = viewModel.isEraser
        view.isColorFillMode = viewModel.isColorFillMode
    }

    public func makeCoordinator() -> Coordinator { Coordinator(viewModel: viewModel) }

    @MainActor
    public final class Coordinator: NSObject, NeonCanvasViewDelegate {
        public let viewModel: DrawViewModel

        public init(viewModel: DrawViewModel) { self.viewModel = viewModel }

        public func canvasDidBeginDrawing() {
            viewModel.showBrushPicker = false
            viewModel.showShareSubmenu = false
        }

        public func canvasDidCommitStroke(_ action: EditAction) {
            viewModel.commitAction(action)
        }

        public func canvasDidTapToFill(at point: CGPoint) {
            viewModel.handleFillTap(at: point)
        }

        public func canvasDidLayoutSubviews() {
            viewModel.restoreCanvasIfNeeded()
        }
    }
}
