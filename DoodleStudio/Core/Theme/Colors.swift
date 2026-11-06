import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

enum AppColors {
    static let homeBackground = Color(hex: "#000000")
    static let drawBackground = Color(hex: "#000000")
    static let galleryBackground = Color(hex: "#FAFAFA")
    static let coralButton = Color(hex: "#EE6A6A")
    static let bannerDenim = Color(hex: "#1E5068")
    static let undoButton = Color(hex: "#6FE0D0")
    static let playButton = Color(hex: "#3DB8F5")
    static let shareButton = Color(hex: "#EE5060")
    static let toolButtonBg = Color(hex: "#DDF1FA")
    
    // Neon palette
    static let neonPink = Color(hex: "#FF2D95")
    static let neonOrange = Color(hex: "#FF9F1C")
    static let neonYellow = Color(hex: "#FFEE32")
    static let neonGreen = Color(hex: "#39FF14")
    static let neonCyan = Color(hex: "#00E5FF")
    static let neonBlue = Color(hex: "#3D5AFE")
    static let neonPurple = Color(hex: "#B517FF")
    static let neonWhite = Color(hex: "#FFFFFF")
    
    static let defaultPalette: [Color] = [
        neonPink,
        neonOrange,
        neonYellow,
        neonGreen,
        neonCyan,
        neonBlue,
        neonPurple,
        neonWhite
    ]
}
