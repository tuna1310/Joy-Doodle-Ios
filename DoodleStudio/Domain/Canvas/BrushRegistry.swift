import Foundation

// MARK: - BrushRegistry (port of Android's BrushRegistry.kt)
// Global registry of all 21 brushes. Order matches Android exactly.

public enum BrushRegistry {

    public static let allBrushes: [any BrushEffect] = [
        ClassicNeonBrush(),       //  1
        RainbowGlowBrush(),       //  2
        CalligraphyRibbonBrush(), //  3
        DoubleStrokeBrush(),      //  4
        ThinNeonPenBrush(),       //  5
        CrayonChalkBrush(),       //  6
        SolidMarkerBrush(),       //  7
        DottedPearlBrush(),       //  8
        SoftBlurBrush(),          //  9
        ConcentricRingsBrush(),   // 10
        SparklerBrush(),          // 11
        FireworksBrush(),         // 12
        NeonStarsBrush(),         // 13
        CrossSparklesBrush(),     // 14
        BokehDotsBrush(),         // 15
        BigCrossStarBrush(),      // 16
        PurpleSparklesBrush(),    // 17
        FairyDustBrush(),         // 18
        SnowflakesBrush(),        // 19
        HeartBubblesBrush(),      // 20
        SoapBubblesBrush()        // 21
    ]

    private static let brushMap: [String: any BrushEffect] = {
        var map: [String: any BrushEffect] = [:]
        for b in allBrushes { map[b.id.uppercased()] = b }
        return map
    }()

    public static let defaultBrush: any BrushEffect = allBrushes[0]

    /// Look up brush by id string (case-insensitive). Falls back to ClassicNeon.
    public static func get(_ id: String?) -> any BrushEffect {
        guard let id = id else { return defaultBrush }
        let upper = id.uppercased()
        if let found = brushMap[upper] { return found }
        // Legacy / alias mappings (match Android)
        switch upper {
        case "NEON":    return brushMap["CLASSIC_NEON"] ?? defaultBrush
        case "PEN":     return brushMap["THIN_NEON_PEN"] ?? defaultBrush
        case "RAINBOW": return brushMap["RAINBOW_GLOW"] ?? defaultBrush
        case "SPARKLE": return brushMap["CROSS_SPARKLES"] ?? defaultBrush
        case "STARS":   return brushMap["NEON_STARS"] ?? defaultBrush
        case "MARKER":  return brushMap["SOLID_MARKER"] ?? defaultBrush
        default:        return defaultBrush
        }
    }
}

