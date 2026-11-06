import SwiftUI
import UIKit

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

// MARK: - BannerAdView
// Top banner area with denim textured background (#1E5068) and real Google AdMob banner.
// Preserves exact height while loading so canvas layout does not jump.

public struct BannerAdView: View {
    public var adUnitID: String = AdConfig.bannerDrawScreen
    public var height: CGFloat = 85

    public init(adUnitID: String = AdConfig.bannerDrawScreen, height: CGFloat = 85) {
        self.adUnitID = adUnitID
        self.height = height
    }

    public var body: some View {
        ZStack {
            // 1. Denim blue background (#1E5068)
            Color(UIColor(hex: 0xFF1E5068))

            // 2. Denim diagonal weave pattern (stripes at 8pt spacing)
            GeometryReader { geo in
                Path { path in
                    let step: CGFloat = 8
                    let w = geo.size.width
                    let h = geo.size.height
                    var x: CGFloat = -h
                    while x < w + h {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x + h, y: h))
                        x += step
                    }
                }
                .stroke(Color(UIColor(hex: 0xFF163E52)), lineWidth: 1.5)
            }

            // 3. AdMob Banner (Real when GoogleMobileAds is linked)
            #if canImport(GoogleMobileAds)
            AdMobBannerRepresentable(adUnitID: adUnitID)
                .frame(maxWidth: .infinity, maxHeight: height)
            #else
            // Fallback placeholder display when SDK is not linked
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "paintpalette.fill")
                            .foregroundColor(.white.opacity(0.8))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Joy Doodle")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Glow drawing studio")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                Text("AD")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.25))
                    .cornerRadius(4)
            }
            .padding(.horizontal, 16)
            #endif
        }
        .frame(height: height)
        .clipped()
    }
}

#if canImport(GoogleMobileAds)
struct AdMobBannerRepresentable: UIViewRepresentable {
    let adUnitID: String

    func makeUIView(context: Context) -> GADBannerView {
        let bannerView = GADBannerView()
        bannerView.adUnitID = adUnitID
        bannerView.backgroundColor = .clear
        
        // Find top root view controller
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
            bannerView.rootViewController = rootVC
            let frame = scene.windows.first?.frame ?? .zero
            let viewWidth = frame.size.width > 0 ? frame.size.width : 320
            bannerView.adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(viewWidth)
        } else {
            bannerView.adSize = GADAdSizeBanner
        }
        
        let request = GADRequest()
        bannerView.load(request)
        return bannerView
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}
}
#endif
