import SwiftUI

// MARK: - GalleryView
// Matches Android GalleryScreen and user screenshot (media_1793974280891_0ebc612d.jpg):
// - Clean white/light gray background
// - Top-left back button (coral circle with white arrow)
// - Top-right "N Artworks" label
// - 3-column grid
// - Each card: White background card with thin inner gray border, aspect ratio 3:4
// - Saved artworks with black thumbnail
// - Promo app cards with graphic icon and title below
// - Tapping artwork opens DrawView with the saved ActionLog

public struct GalleryView: View {
    @Environment(\.dismiss) var dismiss
    @State private var artworks: [Artwork] = []
    @State private var selectedArtworkId: String? = nil
    @State private var navigateToDraw = false

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    public init() {}

    public var body: some View {
        ZStack {
            Color(UIColor(hex: 0xFFF8F9FA)).ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Header Bar
                HStack {
                    // Back button (coral circle)
                    Button(action: {
                        HapticManager.shared.impact()
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(AppColors.coralButton)
                            .clipShape(Circle())
                            .shadow(color: AppColors.coralButton.opacity(0.4), radius: 4)
                    }

                    Spacer()

                    Text("\(artworks.count) Artworks")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Color(UIColor(hex: 0xFF9E9E9E)))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 3, y: 2)

                // 3-Column Grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        // 1. Saved Artworks
                        ForEach(artworks) { artwork in
                            GalleryArtworkCard(artwork: artwork) {
                                HapticManager.shared.impact()
                                selectedArtworkId = artwork.id
                                navigateToDraw = true
                            } onDelete: {
                                ArtworkRepository.shared.deleteArtwork(id: artwork.id)
                                artworks = ArtworkRepository.shared.loadAllArtworks()
                            }
                        }

                        // 2. Promo App Cards (fill out grid)
                        ForEach(promoAppsList) { app in
                            GalleryPromoAppCard(app: app) {
                                HapticManager.shared.impact()
                                openAppStore(app: app)
                            }
                        }
                    }
                    .padding(12)
                }
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToDraw) {
            if let id = selectedArtworkId {
                DrawView(viewModel: DrawViewModel(artworkId: id, existing: ArtworkRepository.shared.getArtworkById(id)))
            }
        }
        .onAppear {
            artworks = ArtworkRepository.shared.loadAllArtworks()
        }
    }
}

// MARK: - GalleryArtworkCard (White card, thin inner gray frame, 3:4 ratio)
struct GalleryArtworkCard: View {
    let artwork: Artwork
    let onTap: () -> Void
    let onDelete: () -> Void

    @State private var thumbnail: UIImage? = nil

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Outer white card
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.06), radius: 4, y: 2)

                // Inner thin gray frame
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color(UIColor(hex: 0xFFE0E0E0)), lineWidth: 1)
                    .padding(3)

                // Black thumbnail
                ZStack {
                    Color.black
                    if let img = thumbnail {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                    } else {
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .padding(6)
            }
            .aspectRatio(0.72, contentMode: .fit)
        }
        .buttonStyle(PressAnimButtonStyle())
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Xóa tranh", systemImage: "trash")
            }
        }
        .onAppear {
            thumbnail = ArtworkRepository.shared.loadThumbnail(artwork: artwork)
        }
    }
}

// MARK: - GalleryPromoAppCard (Matches screenshot in media_1793974280891_0ebc612d.jpg)
struct GalleryPromoAppCard: View {
    let app: PromoApp
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Outer white card
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.06), radius: 4, y: 2)

                // Inner thin gray frame
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color(UIColor(hex: 0xFFE0E0E0)), lineWidth: 1)
                    .padding(3)

                // Content
                VStack(spacing: 6) {
                    PromoAppIconView(iconType: app.iconType, size: 58)

                    Text(app.title)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color(UIColor(hex: 0xFF212121)))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal, 4)
                }
                .padding(8)
            }
            .aspectRatio(0.72, contentMode: .fit)
        }
        .buttonStyle(PressAnimButtonStyle())
    }
}
