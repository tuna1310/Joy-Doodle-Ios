import SwiftUI

struct ShareMenuOverlay: View {
    var onCameraTapped: () -> Void
    var onMovieTapped: () -> Void
    var onSavePhotoTapped: () -> Void
    var onShareSheetTapped: () -> Void
    var onDismiss: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Dismiss background tap
            Color.black.opacity(0.001)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            // 4 vertical popup buttons (matching video f_030.jpg)
            VStack(spacing: 16) {
                // 1. Camera
                SubmenuCircleButton(
                    iconName: "camera.fill",
                    backgroundColor: Color(hex: "#48CAE4"),
                    iconColor: .white,
                    action: {
                        onDismiss()
                        onCameraTapped()
                    }
                )
                
                // 2. Movie / Record
                Button(action: {
                    HapticManager.shared.mediumImpact()
                    onDismiss()
                    onMovieTapped()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 48, height: 48)
                            .shadow(color: .black.opacity(0.4), radius: 4, y: 2)
                        Circle()
                            .fill(Color(hex: "#EE5060"))
                            .frame(width: 22, height: 22)
                    }
                }
                .buttonStyle(NeonPressableButtonStyle())
                
                // 3. Save to Photos
                SubmenuCircleButton(
                    iconName: "photo.on.rectangle.angled",
                    backgroundColor: Color(hex: "#FF6B6B"),
                    iconColor: .white,
                    action: {
                        onDismiss()
                        onSavePhotoTapped()
                    }
                )
                
                // 4. Share Sheet
                SubmenuCircleButton(
                    iconName: "square.and.arrow.up.fill",
                    backgroundColor: AppColors.shareButton,
                    iconColor: .white,
                    action: {
                        onDismiss()
                        onShareSheetTapped()
                    }
                )
            }
            .padding(.trailing, 22)
            .padding(.bottom, 82) // sits right above the 5th button
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

private struct SubmenuCircleButton: View {
    let iconName: String
    let backgroundColor: Color
    let iconColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            action()
        }) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 48, height: 48)
                    .shadow(color: backgroundColor.opacity(0.4), radius: 4, y: 2)
                
                Image(systemName: iconName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(iconColor)
            }
        }
        .buttonStyle(NeonPressableButtonStyle())
    }
}
