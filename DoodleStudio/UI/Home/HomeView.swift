import SwiftUI

struct HomeView: View {
    var onNewDrawing: () -> Void
    var onOpenGallery: () -> Void
    
    @State private var showAdFreeAlert: Bool = false
    @State private var selectedPromoApp: PromoAppItem? = nil
    
    var body: some View {
        ZStack {
            AppColors.homeBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Big 2 Stacked Items: NEW & GALLERY
                VStack(spacing: 36) {
                    // Item 1: NEW
                    Button(action: {
                        HapticManager.shared.mediumImpact()
                        SoundEffectManager.shared.playPop()
                        onNewDrawing()
                    }) {
                        VStack(spacing: 12) {
                            PaletteIconView()
                                .frame(width: 140, height: 140)
                                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                                .neonGlowBorder(color: Color(hex: "#00E5FF"), cornerRadius: 30, lineWidth: 3.5, glowRadius: 10)
                            
                            NeonLetteringView(
                                text: "New",
                                fontSize: 40,
                                colors: [Color(hex: "#D084FF"), Color(hex: "#4EFA8B"), Color(hex: "#FF3385")]
                            )
                        }
                    }
                    .buttonStyle(NeonPressableButtonStyle())
                    
                    // Item 2: GALLERY
                    Button(action: {
                        HapticManager.shared.mediumImpact()
                        SoundEffectManager.shared.playPop()
                        onOpenGallery()
                    }) {
                        VStack(spacing: 12) {
                            NotebookIconView()
                                .frame(width: 140, height: 140)
                                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                                .neonGlowBorder(color: Color(hex: "#FF2D95"), cornerRadius: 30, lineWidth: 3.5, glowRadius: 10)
                            
                            NeonLetteringView(
                                text: "GALLERY",
                                fontSize: 32,
                                colors: [
                                    Color(hex: "#FFEE32"),
                                    Color(hex: "#39FF14"),
                                    Color(hex: "#00E5FF"),
                                    Color(hex: "#3D5AFE"),
                                    Color(hex: "#B517FF"),
                                    Color(hex: "#FF2D95"),
                                    Color(hex: "#FF9F1C")
                                ]
                            )
                        }
                    }
                    .buttonStyle(NeonPressableButtonStyle())
                }
                
                Spacer()
                
                // Bottom Area: Ad Free badge (right) & More Apps Row (bottom)
                VStack(alignment: .trailing, spacing: 14) {
                    // Ad Free badge
                    HStack {
                        Spacer()
                        Button(action: {
                            HapticManager.shared.lightImpact()
                            showAdFreeAlert = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "#101015"))
                                    .frame(width: 50, height: 50)
                                    .neonCircularBorder(color: Color(hex: "#FF2D95"), lineWidth: 2.2, glowRadius: 6)
                                
                                VStack(spacing: -2) {
                                    Text("Ad")
                                        .font(.system(size: 13, weight: .black, design: .rounded))
                                        .foregroundColor(Color(hex: "#00E5FF"))
                                    Text("Free")
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundColor(Color(hex: "#FF2D95"))
                                }
                            }
                        }
                        .buttonStyle(NeonPressableButtonStyle())
                        .padding(.trailing, 22)
                    }
                    
                    // 6 More Apps tiles
                    HStack {
                        Spacer()
                        MoreAppsRow { promo in
                            selectedPromoApp = promo
                        }
                        Spacer()
                    }
                    .padding(.bottom, 12)
                }
            }
        }
        .preferredColorScheme(.dark)
        .alert("Ad Free Version", isPresented: $showAdFreeAlert) {
            Button("Upgrade ($0.99)", role: .none) {
                HapticManager.shared.success()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enjoy an ad-free drawing experience forever!")
        }
        .alert(selectedPromoApp?.title ?? "App", isPresented: Binding(
            get: { selectedPromoApp != nil },
            set: { if !$0 { selectedPromoApp = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("More exciting creative apps are coming soon!")
        }
    }
}
