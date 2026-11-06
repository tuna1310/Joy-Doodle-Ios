import SwiftUI

struct PaletteIconView: View {
    var body: some View {
        ZStack {
            // Rainbow striped background
            HStack(spacing: 0) {
                Color(hex: "#4A00E0")
                Color(hex: "#0072FF")
                Color(hex: "#00C9FF")
                Color(hex: "#92FE9D")
                Color(hex: "#FFEB3B")
                Color(hex: "#FF9800")
                Color(hex: "#F44336")
            }
            
            // Wooden Palette
            ZStack {
                // Palette body
                Ellipse()
                    .fill(Color(hex: "#FFD166"))
                    .frame(width: 95, height: 80)
                    .rotationEffect(.degrees(-15))
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 2, y: 2)
                    .overlay(
                        // Thumb hole
                        Circle()
                            .fill(Color.black.opacity(0.4))
                            .frame(width: 14, height: 14)
                            .offset(x: 28, y: 15)
                    )
                
                // Paint dollops
                Circle().fill(Color(hex: "#00E5FF")).frame(width: 13, height: 13).offset(x: -28, y: -20)
                Circle().fill(Color(hex: "#39FF14")).frame(width: 13, height: 13).offset(x: -32, y: 2)
                Circle().fill(Color(hex: "#FF2D95")).frame(width: 13, height: 13).offset(x: -16, y: 22)
                Circle().fill(Color(hex: "#FFEE32")).frame(width: 12, height: 12).offset(x: 6, y: 24)
                
                // Paintbrush
                ZStack {
                    // Wooden handle
                    Capsule()
                        .fill(Color(hex: "#D48C46"))
                        .frame(width: 8, height: 75)
                    
                    // Silver ferrule
                    Rectangle()
                        .fill(Color(hex: "#C0C0C0"))
                        .frame(width: 9, height: 12)
                        .offset(y: -25)
                    
                    // Brush tip (cyan paint)
                    Ellipse()
                        .fill(Color(hex: "#00E5FF"))
                        .frame(width: 14, height: 26)
                        .offset(y: -40)
                }
                .rotationEffect(.degrees(38))
                .offset(x: 5, y: -10)
                .shadow(color: .black.opacity(0.4), radius: 3, x: 2, y: 2)
            }
        }
    }
}

struct NotebookIconView: View {
    var body: some View {
        ZStack {
            // Notebook cover
            HStack(spacing: 0) {
                // Left spine (coral/orange)
                Color(hex: "#FF6F59")
                    .frame(width: 32)
                
                // Main notebook page cover (sky blue)
                Color(hex: "#4EA8DE")
            }
            
            // Spiral rings (4 rings)
            VStack(spacing: 14) {
                ForEach(0..<4) { _ in
                    Capsule()
                        .fill(Color(hex: "#E0E0E0"))
                        .frame(width: 22, height: 8)
                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                }
            }
            .offset(x: -48)
            
            // Flower illustration
            VStack(spacing: 0) {
                // Flower petals + center
                ZStack {
                    ForEach(0..<8) { i in
                        Circle()
                            .fill(Color(hex: "#FFD166"))
                            .frame(width: 18, height: 18)
                            .offset(y: -14)
                            .rotationEffect(.degrees(Double(i) * 45))
                    }
                    Circle()
                        .fill(Color(hex: "#F77F00"))
                        .frame(width: 20, height: 20)
                }
                
                // Stem & leaves
                ZStack {
                    // Stem
                    Rectangle()
                        .fill(Color(hex: "#7F4F24"))
                        .frame(width: 4, height: 32)
                    
                    // Left leaf
                    Ellipse()
                        .fill(Color(hex: "#52B788"))
                        .frame(width: 16, height: 9)
                        .rotationEffect(.degrees(-35))
                        .offset(x: -9, y: -4)
                    
                    // Right leaf
                    Ellipse()
                        .fill(Color(hex: "#52B788"))
                        .frame(width: 16, height: 9)
                        .rotationEffect(.degrees(35))
                        .offset(x: 9, y: -4)
                }
            }
            .offset(x: 10)
        }
    }
}
