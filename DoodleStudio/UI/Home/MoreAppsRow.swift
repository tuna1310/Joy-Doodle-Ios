import SwiftUI

public struct PromoAppItem: Identifiable {
    public let id: String
    public let title: String
    public let color: Color
    public let iconName: String
}

public enum PromoAppConfig {
    public static let items: [PromoAppItem] = [
        PromoAppItem(id: "kaleidoscope", title: "Kaleidoscope", color: Color(hex: "#FF5964"), iconName: "camera.filters"),
        PromoAppItem(id: "coloring", title: "Kids Coloring", color: Color(hex: "#35A7FF"), iconName: "paintpalette.fill"),
        PromoAppItem(id: "sketch", title: "Sketch Draw", color: Color(hex: "#6C757D"), iconName: "pencil.and.outline"),
        PromoAppItem(id: "fireworks", title: "Glow Magic", color: Color(hex: "#38040E"), iconName: "sparkles"),
        PromoAppItem(id: "princess", title: "Princess Art", color: Color(hex: "#FF99C8"), iconName: "crown.fill"),
        PromoAppItem(id: "dolphin", title: "Color Zoo", color: Color(hex: "#2EC4B6"), iconName: "water.waves")
    ]
}

struct MoreAppsRow: View {
    var onSelect: ((PromoAppItem) -> Void)?
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(PromoAppConfig.items) { item in
                Button(action: {
                    HapticManager.shared.lightImpact()
                    onSelect?(item)
                }) {
                    PromoTileView(item: item, size: 48)
                }
                .buttonStyle(NeonPressableButtonStyle())
            }
        }
    }
}

struct PromoTileView: View {
    let item: PromoAppItem
    var size: CGFloat = 48
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [item.color.opacity(0.85), item.color],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Subtle white border
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.35), lineWidth: 1.2)
            
            Image(systemName: item.iconName)
                .font(.system(size: size * 0.44, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        }
        .frame(width: size, height: size)
        .shadow(color: item.color.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}
