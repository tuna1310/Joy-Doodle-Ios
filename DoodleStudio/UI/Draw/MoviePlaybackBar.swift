import SwiftUI

struct MoviePlaybackBar: View {
    @ObservedObject var player: ActionLogPlayer
    var onExit: () -> Void
    var onRecordTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // Top Blue Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 3)
                    
                    Rectangle()
                        .fill(AppColors.playButton)
                        .frame(width: geo.size.width * CGFloat(player.progress), height: 3)
                }
            }
            .frame(height: 3)
            
            // Playback controls row (matches video mid_052.jpg)
            HStack(spacing: 16) {
                // 1. Speedometer button (1x, 2x, 4x)
                Button(action: {
                    HapticManager.shared.lightImpact()
                    player.cycleSpeed()
                }) {
                    VStack(spacing: -1) {
                        Image(systemName: "gauge.with.needle")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(hex: "#FF2D95"))
                        Text(String(format: "%.0fx", player.speedMultiplier))
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundColor(Color(hex: "#FF2D95"))
                    }
                    .frame(width: 44, height: 44)
                }
                .buttonStyle(NeonPressableButtonStyle())
                
                // 2. Playhead Scrubber Slider with coral knob
                Slider(
                    value: Binding(
                        get: { player.progress },
                        set: { newProgress in
                            player.seek(progress: newProgress)
                        }
                    ),
                    in: 0...1
                )
                .tint(AppColors.coralButton)
                
                // 3. Record / Movie Export shortcut button (white circle with red dot)
                Button(action: {
                    HapticManager.shared.mediumImpact()
                    onRecordTapped()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 40, height: 40)
                        Circle()
                            .fill(Color(hex: "#EE5060"))
                            .frame(width: 18, height: 18)
                    }
                }
                .buttonStyle(NeonPressableButtonStyle())
                
                // 4. Play / Pause button
                Button(action: {
                    HapticManager.shared.lightImpact()
                    player.togglePlayPause()
                }) {
                    ZStack {
                        Circle()
                            .fill(AppColors.playButton)
                            .frame(width: 44, height: 44)
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(NeonPressableButtonStyle())
                
                // 5. Stop button
                Button(action: {
                    HapticManager.shared.lightImpact()
                    player.stop()
                }) {
                    ZStack {
                        Circle()
                            .fill(AppColors.playButton)
                            .frame(width: 44, height: 44)
                        Image(systemName: "stop.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(NeonPressableButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background(Color.black.opacity(0.95))
    }
}
