import SwiftUI

struct CoralCircleButton: View {
    let iconName: String
    var size: CGFloat = 46
    var isSystemIcon: Bool = true
    var action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.shared.lightImpact()
            action()
        }) {
            ZStack {
                Circle()
                    .fill(AppColors.coralButton)
                    .frame(width: size, height: size)
                    .shadow(color: AppColors.coralButton.opacity(0.4), radius: 4, x: 0, y: 2)
                
                if isSystemIcon {
                    Image(systemName: iconName)
                        .font(.system(size: size * 0.44, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(NeonPressableButtonStyle())
    }
}
