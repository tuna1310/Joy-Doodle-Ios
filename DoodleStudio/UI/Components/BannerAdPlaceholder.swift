import SwiftUI

struct BannerAdPlaceholder: View {
    var height: CGFloat = 85
    
    var body: some View {
        ZStack {
            // Denim-blue textured background
            AppColors.bannerDenim
            
            // Subtle diagonal texture
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
                .stroke(Color.white.opacity(0.04), lineWidth: 1.0)
            }
            
            // Ad placeholder content (non-intrusive)
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "app.badge.fill")
                            .foregroundColor(.white.opacity(0.7))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Joy Doodle Studio")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Glow drawing & timelapse art")
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.75))
                }
                
                Spacer()
                
                Text("AD")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(4)
            }
            .padding(.horizontal, 16)
        }
        .frame(height: height)
    }
}
