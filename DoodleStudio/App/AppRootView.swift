import SwiftUI

enum AppScreen: Hashable {
    case home
    case draw(artworkId: UUID?)
    case gallery
}

struct AppRootView: View {
    @State private var currentScreen: AppScreen = .home
    @State private var isSplashActive: Bool = true
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if isSplashActive {
                SplashScreenView()
                    .transition(.opacity)
            } else {
                switch currentScreen {
                case .home:
                    HomeView(
                        onNewDrawing: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                currentScreen = .draw(artworkId: nil)
                            }
                        },
                        onOpenGallery: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                currentScreen = .gallery
                            }
                        }
                    )
                    .transition(.opacity)
                    
                case .draw(let artworkId):
                    DrawView(artworkId: artworkId) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            currentScreen = .home
                        }
                    }
                    .transition(.opacity)
                    
                case .gallery:
                    GalleryView(
                        onBack: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                currentScreen = .home
                            }
                        },
                        onSelectArtwork: { artwork in
                            withAnimation(.easeInOut(duration: 0.25)) {
                                currentScreen = .draw(artworkId: artwork.id)
                            }
                        }
                    )
                    .transition(.opacity)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeOut(duration: 0.4)) {
                    isSplashActive = false
                }
            }
        }
    }
}

private struct SplashScreenView: View {
    @State private var glowScale: CGFloat = 0.95
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                ZStack {
                    PaletteIconView()
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                        .neonGlowBorder(color: AppColors.neonCyan, cornerRadius: 26, lineWidth: 3, glowRadius: 12)
                }
                .scaleEffect(glowScale)
                
                NeonLetteringView(
                    text: "Joy Doodle",
                    fontSize: 34,
                    colors: [Color(hex: "#FF2D95"), Color(hex: "#00E5FF"), Color(hex: "#39FF14"), Color(hex: "#FFEE32")]
                )
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                glowScale = 1.05
            }
        }
    }
}
