import SwiftUI

// MARK: - App Colors (matches Android Color.kt)
public enum AppColors {
    public static let neonPink    = Color(UIColor(hex: 0xFFFF2D95))
    public static let neonCyan    = Color(UIColor(hex: 0xFF00E5FF))
    public static let neonGreen   = Color(UIColor(hex: 0xFF00E676))
    public static let neonYellow  = Color(UIColor(hex: 0xFFFFEA00))
    public static let neonOrange  = Color(UIColor(hex: 0xFFFF9100))
    public static let neonPurple  = Color(UIColor(hex: 0xFF7C4DFF))
    public static let neonBlue    = Color(UIColor(hex: 0xFF00B0FF))
    public static let neonRed     = Color(UIColor(hex: 0xFFFF1744))
    public static let coralButton = Color(UIColor(hex: 0xFFFF5252))
    public static let tealButton  = Color(UIColor(hex: 0xFF009688))
    public static let pinkButton  = Color(UIColor(hex: 0xFFE91E8C))
    public static let denimBanner = Color(UIColor(hex: 0xFF1E5068))
    public static let bannerDenim = Color(UIColor(hex: 0xFF1E5068))

    // 20-color picker palette matching Android
    public static let palette: [Color] = [
        neonPink, neonCyan, neonGreen, neonYellow, neonOrange,
        neonPurple, neonBlue, neonRed,
        Color(UIColor(hex: 0xFFFFFFFF)),  // white
        Color(UIColor(hex: 0xFF80D8FF)),  // light blue
        Color(UIColor(hex: 0xFFFFD740)),  // gold
        Color(UIColor(hex: 0xFF69F0AE)),  // mint
        Color(UIColor(hex: 0xFFEA80FC)),  // lavender
        Color(UIColor(hex: 0xFFFF6E40)),  // deep orange
        Color(UIColor(hex: 0xFF40C4FF)),  // sky blue
        Color(UIColor(hex: 0xFFCCFF90)),  // lime
        Color(UIColor(hex: 0xFFFF4081)),  // hot pink
        Color(UIColor(hex: 0xFFB2FF59)),  // yellow-green
        Color(UIColor(hex: 0xFFE040FB)),  // fuchsia
        Color(UIColor(hex: 0xFFFFD600))   // pure yellow
    ]
}
