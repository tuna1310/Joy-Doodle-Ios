import SwiftUI

// Renders handwritten/neon-tube hollow lettering with multicolor glowing outline
struct NeonLetteringView: View {
    let text: String
    let fontSize: CGFloat
    let colors: [Color]
    
    init(text: String, fontSize: CGFloat = 36, colors: [Color] = AppColors.defaultPalette) {
        self.text = text
        self.fontSize = fontSize
        self.colors = colors
    }
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(Array(text.enumerated()), id: \.offset) { index, char in
                let color = colors[index % colors.count]
                NeonCharView(char: String(char), fontSize: fontSize, color: color)
            }
        }
    }
}

private struct NeonCharView: View {
    let char: String
    let fontSize: CGFloat
    let color: Color
    
    var body: some View {
        ZStack {
            // Outermost soft glow
            Text(char)
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .foregroundColor(color.opacity(0.4))
                .blur(radius: 6)
            
            // Inner vibrant glow
            Text(char)
                .font(.system(size: fontSize, weight: .heavy, design: .rounded))
                .foregroundColor(color.opacity(0.8))
                .blur(radius: 2)
            
            // Core letter in white/bright hue
            Text(char)
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            // Sharp colored outline
            Text(char)
                .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                .foregroundColor(color)
        }
    }
}
