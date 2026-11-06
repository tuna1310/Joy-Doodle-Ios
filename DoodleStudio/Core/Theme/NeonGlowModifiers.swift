import SwiftUI

struct NeonGlowBorder: ViewModifier {
    var color: Color
    var cornerRadius: CGFloat = 28
    var lineWidth: CGFloat = 3
    var glowRadius: CGFloat = 8

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(color.opacity(0.4), lineWidth: lineWidth + 4)
                    .blur(radius: glowRadius)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(color.opacity(0.8), lineWidth: lineWidth + 2)
                    .blur(radius: glowRadius / 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(color, lineWidth: lineWidth)
            )
    }
}

struct NeonCircularGlowBorder: ViewModifier {
    var color: Color
    var lineWidth: CGFloat = 3
    var glowRadius: CGFloat = 6

    func body(content: Content) -> some View {
        content
            .overlay(
                Circle()
                    .stroke(color.opacity(0.4), lineWidth: lineWidth + 4)
                    .blur(radius: glowRadius)
            )
            .overlay(
                Circle()
                    .stroke(color.opacity(0.8), lineWidth: lineWidth + 2)
                    .blur(radius: glowRadius / 2)
            )
            .overlay(
                Circle()
                    .stroke(color, lineWidth: lineWidth)
            )
    }
}

extension View {
    func neonGlowBorder(color: Color, cornerRadius: CGFloat = 28, lineWidth: CGFloat = 3, glowRadius: CGFloat = 8) -> some View {
        modifier(NeonGlowBorder(color: color, cornerRadius: cornerRadius, lineWidth: lineWidth, glowRadius: glowRadius))
    }
    
    func neonCircularBorder(color: Color, lineWidth: CGFloat = 3, glowRadius: CGFloat = 6) -> some View {
        modifier(NeonCircularGlowBorder(color: color, lineWidth: lineWidth, glowRadius: glowRadius))
    }
}

struct NeonPressableButtonStyle: ButtonStyle {
    var hapticOnClick: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { isPressed in
                if isPressed && hapticOnClick {
                    HapticManager.shared.lightImpact()
                }
            }
    }
}
