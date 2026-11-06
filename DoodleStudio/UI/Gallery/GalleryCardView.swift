import SwiftUI

struct ArtworkCardView: View {
    let artwork: Artwork
    var onTap: () -> Void
    var onDelete: () -> Void
    var onShare: () -> Void
    
    var thumbnailImage: UIImage? {
        guard let path = artwork.thumbnailPath else { return nil }
        return FileStore.shared.loadThumbnail(from: path)
    }
    
    var body: some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            onTap()
        }) {
            ZStack {
                // Outer white card with subtle shadow
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
                
                // Thin inner gray frame
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(hex: "#D0D0D5"), lineWidth: 1.2)
                    .padding(3)
                
                // Black canvas thumbnail
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.black)
                    
                    if let img = thumbnailImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
                .padding(6)
            }
            .aspectRatio(3.0 / 4.0, contentMode: .fit)
        }
        .buttonStyle(NeonPressableButtonStyle())
        .contextMenu {
            Button(action: onShare) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct GalleryPromoCardView: View {
    let item: PromoAppItem
    var onTap: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            onTap()
        }) {
            ZStack {
                // Outer white card
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
                
                // Inner thin gray frame
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(hex: "#D0D0D5"), lineWidth: 1.2)
                    .padding(3)
                
                // Content
                VStack(spacing: 8) {
                    PromoTileView(item: item, size: 58)
                    
                    Text(item.title)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "#FF007F"), Color(hex: "#0072FF")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal, 4)
                }
                .padding(8)
            }
            .aspectRatio(3.0 / 4.0, contentMode: .fit)
        }
        .buttonStyle(NeonPressableButtonStyle())
    }
}
