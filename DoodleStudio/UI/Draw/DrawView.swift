import SwiftUI
import UIKit

// MARK: - DrawView
// Drawing & Coloring screen:
// - Top: denim banner (real AdMob adaptive banner, #1E5068 texture)
// - Top-left: Back button (coral circle)
// - Top-right: Template button (🎨) + Trash button (coral circle)
// - Center: Black canvas (UIViewRepresentable with Core Graphics)
// - Bottom: Color palette + Mode toggle (Fill / Draw) + 5 circular tool buttons:
//   Brush, Eraser, Undo (long press = Redo), Play (Replay speed x1/x2/x4), Share.

public struct DrawView: View {
    @StateObject var viewModel: DrawViewModel
    @Environment(\.dismiss) var dismiss

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Top Ad Banner (Denim textured, fixed height) ──
                BannerAdView(adUnitID: AdConfig.bannerDrawScreen, height: 85)

                // ── Canvas Area with Top Buttons ──
                ZStack(alignment: .top) {
                    NeonCanvasRepresentable(viewModel: viewModel)
                        .ignoresSafeArea(edges: .bottom)

                    // Top navigation & actions overlay
                    HStack {
                        // Back Button
                        Button(action: { handleBack() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 46, height: 46)
                                .background(AppColors.coralButton)
                                .clipShape(Circle())
                                .shadow(color: AppColors.coralButton.opacity(0.6), radius: 6)
                        }

                        Spacer()

                        // Template Picker Button (🎨)
                        Button(action: {
                            HapticManager.shared.impact()
                            viewModel.showTemplatePicker = true
                        }) {
                            Text("🎨")
                                .font(.system(size: 20))
                                .frame(width: 46, height: 46)
                                .background(Color(UIColor(hex: 0xFF1E293B)))
                                .clipShape(Circle())
                                .overlay(
                                    Circle().stroke(AppColors.neonCyan.opacity(0.8), lineWidth: 1.5)
                                )
                                .shadow(color: AppColors.neonCyan.opacity(0.4), radius: 6)
                        }

                        // Trash Button
                        Button(action: {
                            HapticManager.shared.impact()
                            viewModel.showClearAlert = true
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 46, height: 46)
                                .background(AppColors.coralButton)
                                .clipShape(Circle())
                                .shadow(color: AppColors.coralButton.opacity(0.6), radius: 6)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                }

                // ── Bottom Drawing Toolbar ──
                DrawingToolbarView(viewModel: viewModel)
                    .padding(.bottom, 8)
            }

            // Brush picker horizontal sheet
            if viewModel.showBrushPicker {
                BrushPickerSheet(viewModel: viewModel)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(10)
            }

            // Share submenu overlay
            if viewModel.showShareSubmenu {
                ShareMenuOverlay(viewModel: viewModel)
                    .transition(.opacity)
                    .zIndex(10)
            }

            // Replay playback controls bar
            if viewModel.isReplaying {
                VStack {
                    Spacer()
                    MoviePlaybackBar(viewModel: viewModel)
                        .padding()
                }
                .zIndex(20)
            }

            // Toast feedback
            if let msg = viewModel.toastMessage {
                VStack {
                    Spacer()
                    Text(msg)
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Color.black.opacity(0.85))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.bottom, 100)
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        viewModel.toastMessage = nil
                    }
                }
                .zIndex(30)
            }
        }
        .navigationBarHidden(true)
        .alert("Xóa nét vẽ", isPresented: $viewModel.showClearAlert) {
            Button("Xóa nét", role: .destructive) { viewModel.clearStrokes() }
            Button("Hủy", role: .cancel) {}
        } message: {
            Text("Xóa toàn bộ nét vẽ và màu tô? Khung hình mẫu sẽ được giữ nguyên.")
        }
        .alert("Bạn muốn làm gì với bức tranh?", isPresented: $viewModel.showExitDialog) {
            Button("Lưu lại") {
                viewModel.saveArtwork { _ in dismiss() }
            }
            Button("Xóa đi", role: .destructive) { dismiss() }
            Button("Vẽ tiếp", role: .cancel) {}
        } message: {
            Text("Bức tranh của bạn có nét vẽ chưa lưu.")
        }
        .sheet(isPresented: $viewModel.showTemplatePicker) {
            TemplatePickerSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showShareSheet) {
            ShareSheet(items: viewModel.shareItems)
        }
        .interactiveDismissDisabled(true)
    }

    private func handleBack() {
        if viewModel.hasContent && !viewModel.isSaved {
            viewModel.showExitDialog = true
        } else {
            dismiss()
        }
    }
}

// MARK: - Drawing Toolbar
struct DrawingToolbarView: View {
    @ObservedObject var viewModel: DrawViewModel

    var body: some View {
        VStack(spacing: 8) {
            // Mode toggle (Fill / Draw)
            if viewModel.templateId != nil {
                ModeToggle(viewModel: viewModel)
            }

            // Color palette bar
            ColorPaletteBar(selectedColor: Binding(
                get: { viewModel.currentColor },
                set: {
                    viewModel.currentColor = $0
                    viewModel.canvasView?.currentColor = UIColor($0)
                }
            ))

            // 5 circular tool buttons
            HStack(spacing: 20) {
                // 1. Brush button
                ToolButton(
                    systemImage: "paintbrush.fill",
                    color: .white,
                    bgColor: Color(UIColor(hex: 0xFF4FC3F7)),
                    isActive: !viewModel.isEraser && !viewModel.isColorFillMode,
                    action: { viewModel.showBrushPicker.toggle() }
                )

                // 2. Eraser button
                ToolButton(
                    systemImage: "eraser.fill",
                    color: .white,
                    bgColor: Color(UIColor(hex: 0xFF90A4AE)),
                    isActive: viewModel.isEraser,
                    action: { viewModel.toggleEraser() }
                )

                // 3. Undo button (press = undo, hold = redo)
                ToolButton(
                    systemImage: "arrow.uturn.backward.circle.fill",
                    color: .white,
                    bgColor: Color(UIColor(hex: 0xFF26C6DA)),
                    isActive: false,
                    action: { viewModel.undo() }
                )
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                        viewModel.redo()
                    }
                )
                .disabled(!viewModel.canUndo && !viewModel.canRedo)
                .opacity(viewModel.canUndo || viewModel.canRedo ? 1 : 0.5)

                // 4. Play / Replay button
                ToolButton(
                    systemImage: viewModel.isReplaying ? "stop.fill" : "play.fill",
                    color: .white,
                    bgColor: Color(UIColor(hex: 0xFF29B6F6)),
                    isActive: viewModel.isReplaying,
                    action: {
                        if viewModel.isReplaying { viewModel.exitReplay() }
                        else { viewModel.startReplay() }
                    }
                )

                // 5. Send / Share button
                ToolButton(
                    systemImage: "paperplane.fill",
                    color: .white,
                    bgColor: AppColors.coralButton,
                    isActive: false,
                    action: { viewModel.shareImage() }
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
        }
        .background(Color.black.opacity(0.85))
    }
}

// MARK: - ToolButton
struct ToolButton: View {
    let systemImage: String
    let color: Color
    let bgColor: Color
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.impact()
            action()
        }) {
            Image(systemName: systemImage)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(bgColor.opacity(isActive ? 1 : 0.85))
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(Color.white.opacity(isActive ? 0.9 : 0), lineWidth: 2)
                )
                .shadow(color: bgColor.opacity(0.5), radius: 6)
        }
        .buttonStyle(PressAnimButtonStyle())
    }
}

// MARK: - Color Palette Bar
struct ColorPaletteBar: View {
    @Binding var selectedColor: Color

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(AppColors.palette.enumerated()), id: \.offset) { _, color in
                    Circle()
                        .fill(color)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle().stroke(
                                selectedColor == color ? Color.white : Color.clear,
                                lineWidth: 2.5
                            )
                        )
                        .shadow(color: color.opacity(0.7), radius: selectedColor == color ? 6 : 2)
                        .onTapGesture {
                            HapticManager.shared.selectionChanged()
                            selectedColor = color
                        }
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 44)
    }
}

// MARK: - Mode Toggle (Fill / Draw)
struct ModeToggle: View {
    @ObservedObject var viewModel: DrawViewModel

    var body: some View {
        HStack(spacing: 0) {
            ModeButton(title: "🎨 Tô màu", isActive: viewModel.editorMode == .fill) {
                viewModel.setEditorMode(.fill)
            }
            ModeButton(title: "✏️ Vẽ cọ", isActive: viewModel.editorMode == .draw) {
                viewModel.setEditorMode(.draw)
            }
        }
        .background(Color(UIColor(hex: 0xFF1E293B)))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
    }
}

struct ModeButton: View {
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.selectionChanged()
            action()
        }) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isActive ? .white : Color(UIColor(hex: 0xFF94A3B8)))
                .padding(.horizontal, 16).padding(.vertical, 6)
                .background(isActive ? AppColors.tealButton : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Movie Playback Bar
struct MoviePlaybackBar: View {
    @ObservedObject var viewModel: DrawViewModel

    var body: some View {
        HStack(spacing: 12) {
            Button("×1") { viewModel.startReplay(speed: 1) }
                .replaySpeedButton(isActive: viewModel.replaySpeed == 1)
            Button("×2") { viewModel.startReplay(speed: 2) }
                .replaySpeedButton(isActive: viewModel.replaySpeed == 2)
            Button("×4") { viewModel.startReplay(speed: 4) }
                .replaySpeedButton(isActive: viewModel.replaySpeed == 4)

            Spacer()

            Button(action: { viewModel.exitReplay() }) {
                Text("Dừng")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(AppColors.coralButton)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Color.black.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

extension View {
    func replaySpeedButton(isActive: Bool) -> some View {
        self
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(isActive ? .black : .white)
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(isActive ? Color.yellow : Color.white.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - BrushPickerSheet
struct BrushPickerSheet: View {
    @ObservedObject var viewModel: DrawViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Chọn cọ vẽ")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(BrushRegistry.allBrushes, id: \.id) { brush in
                        BrushCard(
                            brush: brush,
                            isSelected: viewModel.currentBrushId == brush.id,
                            action: {
                                viewModel.selectBrush(brush.id)
                                withAnimation { viewModel.showBrushPicker = false }
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 14)
        .background(Color(UIColor(hex: 0xFF1E293B)).opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .frame(maxWidth: .infinity)
        .vGravityBottom()
    }
}

struct BrushCard: View {
    let brush: any BrushEffect
    let isSelected: Bool
    let action: () -> Void
    @State private var preview: UIImage? = nil

    var body: some View {
        Button(action: {
            HapticManager.shared.selectionChanged()
            action()
        }) {
            VStack(spacing: 5) {
                ZStack {
                    Color.black
                    if let img = preview {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                    }
                }
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? AppColors.neonCyan : Color.white.opacity(0.2), lineWidth: isSelected ? 2.5 : 1)
                )
                .shadow(color: isSelected ? AppColors.neonCyan.opacity(0.6) : .clear, radius: 6)

                Text(brush.displayNameVi)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(isSelected ? .white : Color(UIColor(hex: 0xFF94A3B8)))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 64)
            }
        }
        .onAppear {
            generatePreview()
        }
    }

    private func generatePreview() {
        let size = CGSize(width: 64, height: 64)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { format in
            let ctx = format.cgContext
            ctx.setFillColor(UIColor.black.cgColor)
            ctx.fill(CGRect(origin: .zero, size: size))
            brush.drawPreview(ctx: ctx, width: size.width, height: size.height)
        }
        self.preview = img
    }
}

extension View {
    func vGravityBottom() -> some View {
        VStack { Spacer(); self }
    }
}

// MARK: - ShareMenuOverlay
struct ShareMenuOverlay: View {
    @ObservedObject var viewModel: DrawViewModel

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 10) {
                    ShareMenuButton(icon: "square.and.arrow.up", label: "Chia sẻ ảnh") {
                        viewModel.shareImage()
                        viewModel.showShareSubmenu = false
                    }
                }
                .padding(.trailing, 24)
                .padding(.bottom, 90)
            }
        }
    }
}

struct ShareMenuButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .semibold))
                Image(systemName: icon)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(Color.black.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.3), lineWidth: 1))
        }
    }
}
