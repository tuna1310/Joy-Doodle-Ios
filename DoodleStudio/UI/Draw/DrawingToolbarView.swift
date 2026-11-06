import SwiftUI

struct DrawingToolbarView: View {
    @Binding var currentTool: BrushTool
    var onBrushTap: () -> Void
    var onEraserTap: () -> Void
    var onUndoTap: () -> Void
    var onRedoTap: () -> Void
    var onPlayTap: () -> Void
    var onShareTap: () -> Void
    
    var isEraserActive: Bool {
        currentTool == .eraser
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Spacer()
            
            // 1. Brush Button
            ToolbarCircleButton(
                iconName: "paintbrush.fill",
                backgroundColor: AppColors.toolButtonBg,
                iconColor: Color(hex: "#FF2D95"),
                isSelected: currentTool != .eraser,
                action: onBrushTap
            )
            
            Spacer()
            
            // 2. Eraser Button
            ToolbarCircleButton(
                iconName: "eraser.fill",
                backgroundColor: AppColors.toolButtonBg,
                iconColor: Color(hex: "#FF5964"),
                isSelected: isEraserActive,
                action: onEraserTap
            )
            
            Spacer()
            
            // 3. Undo Button (Tap = Undo, Long Press = Redo)
            ToolbarCircleButton(
                iconName: "arrow.uturn.backward",
                backgroundColor: AppColors.undoButton,
                iconColor: Color(hex: "#006466"),
                action: onUndoTap,
                longPressAction: onRedoTap
            )
            
            Spacer()
            
            // 4. Play Button
            ToolbarCircleButton(
                iconName: "play.fill",
                backgroundColor: AppColors.playButton,
                iconColor: .white,
                action: onPlayTap
            )
            
            Spacer()
            
            // 5. Share Button (Paper plane)
            ToolbarCircleButton(
                iconName: "paperplane.fill",
                backgroundColor: AppColors.shareButton,
                iconColor: .white,
                action: onShareTap
            )
            
            Spacer()
        }
        .frame(height: 70)
        .background(Color.black)
    }
}

struct ToolbarCircleButton: View {
    let iconName: String
    let backgroundColor: Color
    let iconColor: Color
    var isSelected: Bool = false
    var action: () -> Void
    var longPressAction: (() -> Void)? = nil
    
    var size: CGFloat = 52
    
    var body: some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            action()
        }) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: size, height: size)
                    .shadow(color: backgroundColor.opacity(0.4), radius: 3, x: 0, y: 1)
                
                Image(systemName: iconName)
                    .font(.system(size: size * 0.42, weight: .bold))
                    .foregroundColor(iconColor)
            }
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(isSelected ? 0.9 : 0.0), lineWidth: 2.5)
            )
        }
        .buttonStyle(NeonPressableButtonStyle())
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                if let longPress = longPressAction {
                    HapticManager.shared.mediumImpact()
                    SoundEffectManager.shared.playPop()
                    longPress()
                }
            }
        )
    }
}
