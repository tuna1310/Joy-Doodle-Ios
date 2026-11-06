import SwiftUI

// MARK: - MoreApps (port of Android's PromoApps.kt)
// 6 apps matching Android version. App Store IDs are TODO placeholders.
// Opening links: tries itms-apps:// first, falls back to https://apps.apple.com

public enum PromoIconType: CaseIterable {
    case kaleidoscope, pencils, princess, dolphin, glowFlower, sparkleNight
}

public struct PromoApp: Identifiable {
    public let id: String
    public let title: String
    public let iconType: PromoIconType
    /// App Store numeric ID. Set to nil if unknown — tapping will do nothing.
    public let appStoreID: String?

    public var storeURL: URL? {
        guard let appStoreID = appStoreID else { return nil }
        // Try App Store deep link first; SwiftUI openURL will pick correct one
        return URL(string: "https://apps.apple.com/app/id\(appStoreID)")
    }

    public var storeDeepLinkURL: URL? {
        guard let appStoreID = appStoreID else { return nil }
        return URL(string: "itms-apps://itunes.apple.com/app/id\(appStoreID)")
    }
}

// MARK: - App List (names match Android's PromoApps.kt)
public let promoAppsList: [PromoApp] = [
    PromoApp(
        id: "promo_kaleido",
        title: "Kaleidoscope Drawing",
        iconType: .kaleidoscope,
        appStoreID: nil  // TODO: Fill in real App Store ID
    ),
    PromoApp(
        id: "promo_pencils",
        title: "Kids Coloring",
        iconType: .pencils,
        appStoreID: nil  // TODO: Fill in real App Store ID
    ),
    PromoApp(
        id: "promo_princess",
        title: "Draw Princess",
        iconType: .princess,
        appStoreID: nil  // TODO: Fill in real App Store ID
    ),
    PromoApp(
        id: "promo_dolphin",
        title: "Where's Color in Zoo",
        iconType: .dolphin,
        appStoreID: nil  // TODO: Fill in real App Store ID
    ),
    PromoApp(
        id: "promo_paintjoy",
        title: "Paint Joy",
        iconType: .glowFlower,
        appStoreID: nil  // TODO: Fill in real App Store ID
    ),
    PromoApp(
        id: "promo_sparkle",
        title: "Glow Sparkle",
        iconType: .sparkleNight,
        appStoreID: nil  // TODO: Fill in real App Store ID
    )
]

// MARK: - Open App Store helper

public func openAppStore(app: PromoApp) {
    guard app.appStoreID != nil else { return }  // No ID → no-op, no crash
    if let deepLink = app.storeDeepLinkURL, UIApplication.shared.canOpenURL(deepLink) {
        UIApplication.shared.open(deepLink, options: [:], completionHandler: nil)
    } else if let webURL = app.storeURL {
        UIApplication.shared.open(webURL, options: [:], completionHandler: nil)
    }
}

// MARK: - PromoAppIconView (canvas-drawn icons, same visuals as Android)

public struct PromoAppIconView: View {
    let iconType: PromoIconType
    let size: CGFloat

    @State private var isPressed = false

    var body: some View {
        Canvas { ctx, size in
            drawIcon(ctx: ctx, size: size, type: iconType)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.2)
                .stroke(Color(UIColor.systemGray5), lineWidth: 1)
        )
    }

    private func drawIcon(ctx: GraphicsContext, size: CGSize, type: PromoIconType) {
        switch type {
        case .kaleidoscope:
            // Red/purple gradient bg
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(UIColor(hex: 0xFFFF1744))))
            // Purple tube
            var tubePath = Path()
            tubePath.move(to: CGPoint(x: size.width*0.25, y: size.height*0.25))
            tubePath.addLine(to: CGPoint(x: size.width*0.7, y: size.height*0.7))
            ctx.stroke(tubePath, with: .color(Color(UIColor(hex: 0xFF7C4DFF))), lineWidth: size.width*0.24)
            // Yellow lens
            ctx.fill(Circle().path(in: CGRect(x: size.width*0.72-size.width*0.18, y: size.height*0.72-size.width*0.18, width: size.width*0.36, height: size.width*0.36)), with: .color(Color(UIColor(hex: 0xFFFFD600))))
            ctx.fill(Circle().path(in: CGRect(x: size.width*0.72-size.width*0.08, y: size.height*0.72-size.width*0.08, width: size.width*0.16, height: size.width*0.16)), with: .color(Color(UIColor(hex: 0xFF00E5FF))))

        case .pencils:
            // Sky blue bg
            let grad = Gradient(colors: [Color(UIColor(hex: 0xFF40C4FF)), Color(UIColor(hex: 0xFFE1F5FE))])
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(grad, startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
            let pencilColors: [Color] = [.red, .orange, .yellow, .green, Color(UIColor(hex: 0xFF00B0FF)), .purple, .pink]
            let pw = size.width / CGFloat(pencilColors.count + 1)
            for (i, c) in pencilColors.enumerated() {
                let x = pw * CGFloat(i) + pw * 0.5
                let h = size.height * (0.45 + CGFloat(i % 3) * 0.12)
                ctx.fill(Path(CGRect(x: x, y: size.height - h, width: pw*0.85, height: h)), with: .color(c))
            }

        case .princess:
            let grad2 = Gradient(colors: [Color(UIColor(hex: 0xFFB2DFDB)), Color(UIColor(hex: 0xFFE0F2F1))])
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(grad2, startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
            ctx.fill(Circle().path(in: CGRect(x: size.width*0.5-size.width*0.22, y: size.height*0.38-size.width*0.22, width: size.width*0.44, height: size.width*0.44)), with: .color(Color(UIColor(hex: 0xFFFFD54F))))
            var gown = Path()
            gown.move(to: CGPoint(x: size.width*0.5, y: size.height*0.45))
            gown.addLine(to: CGPoint(x: size.width*0.85, y: size.height))
            gown.addLine(to: CGPoint(x: size.width*0.15, y: size.height))
            gown.closeSubpath()
            ctx.fill(gown, with: .color(Color(UIColor(hex: 0xFF7E57C2))))

        case .dolphin:
            let grad3 = Gradient(colors: [Color(UIColor(hex: 0xFF2979FF)), Color(UIColor(hex: 0xFF00E5FF))])
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(grad3, startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
            var dolphin = Path()
            dolphin.move(to: CGPoint(x: size.width*0.2, y: size.height*0.55))
            dolphin.addQuadCurve(to: CGPoint(x: size.width*0.85, y: size.height*0.45), control: CGPoint(x: size.width*0.45, y: size.height*0.2))
            dolphin.addQuadCurve(to: CGPoint(x: size.width*0.2, y: size.height*0.55), control: CGPoint(x: size.width*0.55, y: size.height*0.55))
            ctx.fill(dolphin, with: .color(Color(UIColor(hex: 0xFFFF4081))))

        case .glowFlower:
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black))
            let petalColors: [Color] = [.pink, .orange, .yellow, .green, Color(UIColor(hex: 0xFF00E5FF)), .purple]
            let r = size.width * 0.26; let pr = size.width * 0.22
            for i in 0..<6 {
                let angle = CGFloat(i) * 60.0 * .pi / 180.0
                let px = size.width*0.5 + cos(angle) * r
                let py = size.height*0.5 + sin(angle) * r
                ctx.stroke(Circle().path(in: CGRect(x: px-pr, y: py-pr, width: pr*2, height: pr*2)), with: .color(petalColors[i].opacity(0.5)), lineWidth: 4)
            }
            ctx.fill(Circle().path(in: CGRect(x: size.width*0.5-size.width*0.12, y: size.height*0.5-size.width*0.12, width: size.width*0.24, height: size.width*0.24)), with: .color(Color(UIColor(hex: 0xFFFFD600))))

        case .sparkleNight:
            let grad4 = Gradient(colors: [Color(UIColor(hex: 0xFF0D1B2A)), Color(UIColor(hex: 0xFF1B263B))])
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(grad4, startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
            ctx.fill(Circle().path(in: CGRect(x: size.width*0.45-size.width*0.16, y: size.height*0.65-size.width*0.16, width: size.width*0.32, height: size.width*0.32)), with: .color(.white))
            ctx.fill(Circle().path(in: CGRect(x: size.width*0.45-size.width*0.11, y: size.height*0.44-size.width*0.11, width: size.width*0.22, height: size.width*0.22)), with: .color(.white))
            for i in 0..<8 {
                let angle = CGFloat(i) * 45.0 * .pi / 180.0
                let ex = size.width*0.72 + size.width*0.18*cos(angle)
                let ey = size.height*0.25 + size.width*0.18*sin(angle)
                var line = Path()
                line.move(to: CGPoint(x: size.width*0.72, y: size.height*0.25))
                line.addLine(to: CGPoint(x: ex, y: ey))
                ctx.stroke(line, with: .color(.yellow), lineWidth: 2)
            }
        }
    }
}

// MARK: - PromoAppCard for Gallery (white card with icon + title)
public struct PromoGalleryCard: View {
    let app: PromoApp
    var body: some View {
        VStack(spacing: 8) {
            PromoAppIconView(iconType: app.iconType, size: 68)
            Text(app.title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(UIColor.label))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(radius: 2)
    }
}

