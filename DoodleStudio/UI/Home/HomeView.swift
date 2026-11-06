import SwiftUI

// MARK: - HomeView
// Matches Android HomeScreen exactly (see media_1793974256573_fcf5c962.jpg):
// - Black background
// - Top card: Rainbow palette icon with neon teal/blue border + "NEW" multicolor neon text
// - Bottom card: Spring notebook icon with neon pink border + "GALLERY" multicolor neon text
// - Bottom right: Circular "Ad Free" badge
// - Bottom row: 6 More Apps icons with press feedback and haptic vibration

public struct HomeView: View {
    @State private var navigateToGallery = false
    @State private var navigateToDraw = false
    @State private var showAdFreeSheet = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer(minLength: 20)

                    // 1. NEW Button Card
                    HomeCardButton(
                        content: {
                            PaletteIconGraphic()
                                .frame(width: 140, height: 140)
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        },
                        label: "NEW",
                        labelColors: [
                            Color(UIColor(hex: 0xFF00E5FF)), // Neon Cyan
                            Color(UIColor(hex: 0xFF00E676)), // Neon Green
                            Color(UIColor(hex: 0xFFFF2D95))  // Neon Pink
                        ],
                        borderColor: Color(UIColor(hex: 0xFF00E5FF)),
                        action: { navigateToDraw = true }
                    )

                    Spacer(minLength: 28)

                    // 2. GALLERY Button Card
                    HomeCardButton(
                        content: {
                            NotebookIconGraphic()
                                .frame(width: 140, height: 140)
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        },
                        label: "GALLERY",
                        labelColors: [
                            Color(UIColor(hex: 0xFFFFEA00)), // Yellow
                            Color(UIColor(hex: 0xFFFF9100)), // Orange
                            Color(UIColor(hex: 0xFFFF2D95)), // Pink
                            Color(UIColor(hex: 0xFF00E5FF)), // Cyan
                            Color(UIColor(hex: 0xFF7C4DFF)), // Purple
                            Color(UIColor(hex: 0xFFFF1744)), // Red
                            Color(UIColor(hex: 0xFF00E676))  // Green
                        ],
                        borderColor: Color(UIColor(hex: 0xFFFF2D95)),
                        action: { navigateToGallery = true }
                    )

                    Spacer(minLength: 20)

                    // 3. Bottom More Apps Row (6 apps)
                    HomeMoreAppsRow()
                        .padding(.bottom, 12)
                }

                // 4. "Ad Free" Badge (bottom-right above More Apps)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        AdFreeButton { showAdFreeSheet = true }
                            .padding(.trailing, 20)
                            .padding(.bottom, 82)
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToDraw) {
                DrawView(viewModel: DrawViewModel())
            }
            .navigationDestination(isPresented: $navigateToGallery) {
                GalleryView()
            }
            .sheet(isPresented: $showAdFreeSheet) {
                AdFreeSheet()
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Home Card Button (Big icon + Neon Text + Press animation)
struct HomeCardButton<Content: View>: View {
    let content: () -> Content
    let label: String
    let labelColors: [Color]
    let borderColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.impact()
            action()
        }) {
            VStack(spacing: 12) {
                // Card graphic container
                ZStack {
                    content()
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(borderColor, lineWidth: 3.5)
                        .shadow(color: borderColor.opacity(0.85), radius: 12)
                        .shadow(color: borderColor.opacity(0.4), radius: 22)
                )

                // Multicolor Neon Lettering
                HomeNeonTextView(text: label, colors: labelColors, fontSize: 32)
            }
        }
        .buttonStyle(PressAnimButtonStyle())
    }
}

// MARK: - Palette Icon Graphic (Matches original app & screenshot)
struct PaletteIconGraphic: View {
    var body: some View {
        ZStack {
            // Rainbow striped background
            HStack(spacing: 0) {
                Color(UIColor(hex: 0xFF4A00E0))
                Color(UIColor(hex: 0xFF0072FF))
                Color(UIColor(hex: 0xFF00C9FF))
                Color(UIColor(hex: 0xFF92FE9D))
                Color(UIColor(hex: 0xFFFFEB3B))
                Color(UIColor(hex: 0xFFFF9800))
                Color(UIColor(hex: 0xFFF44336))
            }

            // Wooden Palette
            ZStack {
                Ellipse()
                    .fill(Color(UIColor(hex: 0xFFFFD166)))
                    .frame(width: 88, height: 74)
                    .rotationEffect(.degrees(-15))
                    .shadow(color: .black.opacity(0.35), radius: 4, x: 2, y: 2)
                    .overlay(
                        // Thumb hole
                        Circle()
                            .fill(Color.black.opacity(0.45))
                            .frame(width: 14, height: 14)
                            .offset(x: 26, y: 14)
                    )

                // Paint dollops
                Circle().fill(Color(UIColor(hex: 0xFF00E5FF))).frame(width: 12, height: 12).offset(x: -26, y: -18)
                Circle().fill(Color(UIColor(hex: 0xFF00E676))).frame(width: 12, height: 12).offset(x: -30, y: 2)
                Circle().fill(Color(UIColor(hex: 0xFFFF2D95))).frame(width: 12, height: 12).offset(x: -16, y: 20)
                Circle().fill(Color(UIColor(hex: 0xFFFFEA00))).frame(width: 11, height: 11).offset(x: 5, y: 22)

                // Paintbrush
                ZStack {
                    Capsule()
                        .fill(Color(UIColor(hex: 0xFFD48C46)))
                        .frame(width: 7, height: 70)
                    Rectangle()
                        .fill(Color(UIColor(hex: 0xFFC0C0C0)))
                        .frame(width: 8, height: 11)
                        .offset(y: -23)
                    Ellipse()
                        .fill(Color(UIColor(hex: 0xFF00E5FF)))
                        .frame(width: 13, height: 24)
                        .offset(y: -36)
                }
                .rotationEffect(.degrees(38))
                .offset(x: 4, y: -8)
                .shadow(color: .black.opacity(0.4), radius: 3, x: 2, y: 2)
            }
        }
    }
}

// MARK: - Notebook Icon Graphic (Matches original app & screenshot)
struct NotebookIconGraphic: View {
    var body: some View {
        ZStack {
            // Notebook cover
            HStack(spacing: 0) {
                // Left spine (coral/orange)
                Color(UIColor(hex: 0xFFFF6F59))
                    .frame(width: 32)
                // Main page cover (sky blue)
                Color(UIColor(hex: 0xFF4EA8DE))
            }

            // 4 Spiral rings
            VStack(spacing: 12) {
                ForEach(0..<4) { _ in
                    Capsule()
                        .fill(Color(UIColor(hex: 0xFFE0E0E0)))
                        .frame(width: 20, height: 7)
                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                }
            }
            .offset(x: -44)

            // Flower illustration
            VStack(spacing: 0) {
                ZStack {
                    ForEach(0..<8) { i in
                        Circle()
                            .fill(Color(UIColor(hex: 0xFFFFD166)))
                            .frame(width: 16, height: 16)
                            .offset(y: -12)
                            .rotationEffect(.degrees(Double(i) * 45))
                    }
                    Circle()
                        .fill(Color(UIColor(hex: 0xFFF77F00)))
                        .frame(width: 18, height: 18)
                }

                // Stem & leaves
                ZStack {
                    Rectangle()
                        .fill(Color(UIColor(hex: 0xFF7F4F24)))
                        .frame(width: 4, height: 28)
                    Ellipse()
                        .fill(Color(UIColor(hex: 0xFF52B788)))
                        .frame(width: 14, height: 8)
                        .rotationEffect(.degrees(-35))
                        .offset(x: -8, y: -4)
                    Ellipse()
                        .fill(Color(UIColor(hex: 0xFF52B788)))
                        .frame(width: 14, height: 8)
                        .rotationEffect(.degrees(35))
                        .offset(x: 8, y: -4)
                }
            }
            .offset(x: 8)
        }
    }
}

// MARK: - 4-Layer Glow Neon Text
struct HomeNeonTextView: View {
    let text: String
    let colors: [Color]
    let fontSize: CGFloat

    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(text.enumerated()), id: \.offset) { index, char in
                let color = colors[index % colors.count]
                ZStack {
                    // Layer 1: Soft diffuse glow
                    Text(String(char))
                        .font(.system(size: fontSize, weight: .heavy, design: .rounded))
                        .foregroundColor(color.opacity(0.45))
                        .blur(radius: 8)

                    // Layer 2: Tight intense glow
                    Text(String(char))
                        .font(.system(size: fontSize, weight: .heavy, design: .rounded))
                        .foregroundColor(color.opacity(0.9))
                        .blur(radius: 2.5)

                    // Layer 3: White-hot core
                    Text(String(char))
                        .font(.system(size: fontSize, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    // Layer 4: Sharp vibrant stroke
                    Text(String(char))
                        .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                        .foregroundColor(color)
                }
            }
        }
    }
}

// MARK: - More Apps Row
struct HomeMoreAppsRow: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(promoAppsList) { app in
                    Button(action: {
                        HapticManager.shared.impact()
                        openAppStore(app: app)
                    }) {
                        PromoAppIconView(iconType: app.iconType, size: 54)
                    }
                    .buttonStyle(PressAnimButtonStyle())
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 68)
    }
}

// MARK: - Ad Free Button Badge
struct AdFreeButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.impact()
            action()
        }) {
            ZStack {
                Circle()
                    .fill(Color.black)
                    .frame(width: 46, height: 46)
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.7), lineWidth: 1.2)
                    )
                    .shadow(color: .white.opacity(0.3), radius: 4)

                VStack(spacing: -1) {
                    Text("Ad")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Free")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Ad Free Sheet
struct AdFreeSheet: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 22) {
            Text("🌟 Phiên bản không quảng cáo")
                .font(.title2.bold())
                .foregroundColor(.white)

            Text("Trải nghiệm vẽ tranh neon tuyệt đỉnh không bị làm phiền bởi quảng cáo.\n\nTính năng đang hoàn thiện qua StoreKit!")
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal, 24)

            Button("Đóng") { dismiss() }
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(AppColors.tealButton)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor(hex: 0xFF0F172A)))
    }
}


