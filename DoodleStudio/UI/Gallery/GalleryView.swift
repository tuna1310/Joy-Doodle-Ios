import SwiftUI

struct GalleryView: View {
    @ObservedObject var repository = ArtworkRepository.shared
    var onBack: () -> Void
    var onSelectArtwork: (Artwork) -> Void
    
    @State private var shareItems: [Any] = []
    @State private var showShareSheet: Bool = false
    @State private var promoAlertItem: PromoAppItem? = nil
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        ZStack {
            AppColors.galleryBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar with Back button
                HStack {
                    CoralCircleButton(iconName: "chevron.backward", size: 44) {
                        onBack()
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 6)
                
                // 3-Column Grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 14) {
                        // 1. User's saved drawings
                        ForEach(repository.artworks) { artwork in
                            ArtworkCardView(
                                artwork: artwork,
                                onTap: {
                                    onSelectArtwork(artwork)
                                },
                                onDelete: {
                                    withAnimation {
                                        repository.delete(id: artwork.id)
                                    }
                                    HapticManager.shared.mediumImpact()
                                },
                                onShare: {
                                    if let thumbPath = artwork.thumbnailPath,
                                       let image = FileStore.shared.loadThumbnail(from: thumbPath) {
                                        shareItems = [image]
                                        showShareSheet = true
                                    }
                                }
                            )
                        }
                        
                        // 2. Promo App Tiles (matching reference gallery)
                        ForEach(PromoAppConfig.items) { promo in
                            GalleryPromoCardView(item: promo) {
                                promoAlertItem = promo
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 24)
                    
                    // Empty state hint if user has no saved drawings yet
                    if repository.artworks.isEmpty {
                        VStack(spacing: 6) {
                            Text("Draw something!")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "#FF2D95"))
                            Text("Your saved creations will show up here.")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 16)
                    }
                    
                    // Centered Footer Count (live from repository)
                    Text("\(repository.artworks.count) Artworks")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(Color.gray.opacity(0.7))
                        .padding(.vertical, 20)
                }
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            repository.loadIndex()
        }
        .sheet(isPresented: $showShareSheet) {
            ShareActivityView(activityItems: shareItems)
        }
        .alert(promoAlertItem?.title ?? "App", isPresented: Binding(
            get: { promoAlertItem != nil },
            set: { if !$0 { promoAlertItem = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("More exciting creative apps are coming soon!")
        }
    }
}
