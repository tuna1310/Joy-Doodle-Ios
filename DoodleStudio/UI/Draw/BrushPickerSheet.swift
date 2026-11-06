import SwiftUI

struct BrushPickerSheet: View {
    @Binding var currentTool: BrushTool
    @Binding var currentStyle: BrushStyle
    @Binding var currentColor: Color
    @Binding var currentStrokeWidth: CGFloat
    
    var onClose: () -> Void
    
    private let sizePresets: [(name: String, size: CGFloat)] = [
        ("Thin", 6),
        ("Med", 12),
        ("Thick", 20),
        ("Extra", 32)
    ]
    
    var body: some View {
        VStack(spacing: 14) {
            // Header with title and close handle
            HStack {
                Text("Brush & Colors")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            // 1. Horizontal Brush Style Selector (matches video mid_045.jpg)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(BrushStyle.allCases, id: \.self) { style in
                        BrushStyleTile(
                            style: style,
                            isSelected: currentStyle == style && currentTool != .eraser,
                            color: currentColor
                        ) {
                            currentStyle = style
                            if style == .rainbow {
                                currentTool = .rainbow
                            } else {
                                currentTool = .neon
                            }
                            HapticManager.shared.lightImpact()
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            
            // 2. Neon Color Palette
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(AppColors.defaultPalette, id: \.self) { col in
                        ColorCircleButton(
                            color: col,
                            isSelected: currentColor == col && currentStyle != .rainbow,
                            action: {
                                currentColor = col
                                if currentStyle == .rainbow {
                                    currentStyle = .neonGlow
                                    currentTool = .neon
                                }
                                HapticManager.shared.lightImpact()
                            }
                        )
                    }
                    
                    // Native iOS ColorPicker for full freedom
                    ColorPicker("", selection: $currentColor, supportsOpacity: false)
                        .labelsHidden()
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                }
                .padding(.horizontal, 16)
            }
            
            // 3. Size Presets & Slider
            HStack(spacing: 12) {
                ForEach(sizePresets, id: \.name) { preset in
                    Button(action: {
                        currentStrokeWidth = preset.size
                        HapticManager.shared.lightImpact()
                    }) {
                        Text(preset.name)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(currentStrokeWidth == preset.size ? .black : .white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(currentStrokeWidth == preset.size ? AppColors.neonCyan : Color.white.opacity(0.15))
                            )
                    }
                }
                
                Spacer()
                
                // Slider
                Slider(value: $currentStrokeWidth, in: 4...45)
                    .tint(AppColors.neonCyan)
                    .frame(width: 110)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(hex: "#121217").opacity(0.96))
                .shadow(color: .black.opacity(0.8), radius: 10, y: -4)
        )
    }
}

private struct BrushStyleTile: View {
    let style: BrushStyle
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.black)
                        .frame(width: 54, height: 54)
                    
                    // Mini preview shape for each style
                    previewContent
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isSelected ? Color.white : Color.white.opacity(0.2), lineWidth: isSelected ? 2.5 : 1.0)
                )
                
                Text(style.displayName)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(isSelected ? .white : .gray)
            }
        }
        .buttonStyle(NeonPressableButtonStyle())
    }
    
    @ViewBuilder
    private var previewContent: some View {
        switch style {
        case .neonGlow:
            Circle()
                .stroke(color, lineWidth: 3.5)
                .frame(width: 26, height: 26)
                .shadow(color: color, radius: 4)
        case .rainbow:
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [.red, .orange, .yellow, .green, .cyan, .purple, .red],
                        center: .center
                    ),
                    lineWidth: 3.5
                )
                .frame(width: 26, height: 26)
                .shadow(color: .cyan, radius: 4)
        case .solid:
            Circle()
                .fill(color)
                .frame(width: 22, height: 22)
        case .thinGlow:
            Circle()
                .stroke(color, lineWidth: 1.5)
                .frame(width: 26, height: 26)
                .shadow(color: color, radius: 2)
        case .stars, .sparkles:
            Image(systemName: "star.fill")
                .foregroundColor(color)
                .font(.system(size: 22))
                .shadow(color: color, radius: 3)
        case .snowflakes:
            Image(systemName: "snowflake")
                .foregroundColor(color)
                .font(.system(size: 22))
                .shadow(color: color, radius: 3)
        case .hearts:
            Image(systemName: "heart.fill")
                .foregroundColor(color)
                .font(.system(size: 22))
                .shadow(color: color, radius: 3)
        case .bubbles:
            Circle()
                .stroke(color, lineWidth: 2)
                .frame(width: 24, height: 24)
        case .fireworks:
            Image(systemName: "sparkles")
                .foregroundColor(color)
                .font(.system(size: 22))
                .shadow(color: color, radius: 3)
        }
    }
}

private struct ColorCircleButton: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 34, height: 34)
                .shadow(color: color.opacity(0.6), radius: 4)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: isSelected ? 3 : 0)
                )
        }
        .buttonStyle(NeonPressableButtonStyle())
    }
}
