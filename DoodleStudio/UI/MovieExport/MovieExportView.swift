import SwiftUI
import AVKit

struct MovieExportView: View {
    let strokes: [StrokeAction]
    var onBack: () -> Void
    
    @State private var rotationDegrees: Double = 0
    @State private var speedIndex: Int = 0 // 1x, 2x, 4x
    private let speeds: [Double] = [1.0, 2.0, 4.0]
    
    @State private var isExporting: Bool = false
    @State private var exportProgress: Double = 0.0
    @State private var exportedVideoUrl: URL? = nil
    @State private var showShareSheet: Bool = false
    @State private var alertMessage: String? = nil
    
    private var videoDurationSeconds: Double {
        let baseDuration: Double = 5.0
        return max(1.0, baseDuration / speeds[speedIndex])
    }
    
    var body: some View {
        ZStack {
            // Starry Night Sky Background (deep purple to midnight blue with twinkling stars)
            StarrySkyBackground()
                .ignoresSafeArea()
            
            VStack {
                // Top bar with Coral Back button
                HStack {
                    CoralCircleButton(iconName: "chevron.backward", size: 44) {
                        onBack()
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()
                
                // Centered Artwork Preview Card
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.black)
                        .frame(width: 250, height: 350)
                        .shadow(color: Color.black.opacity(0.8), radius: 16, y: 8)
                    
                    if let image = renderPreview() {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 250, height: 350)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }
                }
                .rotationEffect(.degrees(rotationDegrees))
                .animation(.easeInOut(duration: 0.3), value: rotationDegrees)
                
                // Video length label
                Text(String(format: "Video Length: %.0f seconds", videoDurationSeconds))
                    .font(.system(size: 19, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 28)
                
                // Speed pill (1x, 2x, 4x)
                Button(action: {
                    HapticManager.shared.lightImpact()
                    speedIndex = (speedIndex + 1) % speeds.count
                }) {
                    Text(String(format: "%.0fx", speeds[speedIndex]))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 22)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.12))
                        )
                }
                .padding(.top, 12)
                
                Spacer()
                
                // Bottom 3 Controls (matching end_038.jpg)
                HStack(spacing: 36) {
                    // Left: Green Rotate Counter-Clockwise
                    Button(action: {
                        HapticManager.shared.lightImpact()
                        rotationDegrees -= 90
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#00E676"))
                                .frame(width: 52, height: 52)
                                .shadow(color: Color(hex: "#00E676").opacity(0.4), radius: 6)
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 22, weight: .heavy))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(NeonPressableButtonStyle())
                    
                    // Center: Record / Export Movie (Large white circle with red dot)
                    Button(action: startMovieExport) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 72, height: 72)
                                .shadow(color: .white.opacity(0.35), radius: 10)
                            
                            if isExporting {
                                ProgressView()
                                    .tint(.red)
                                    .scaleEffect(1.3)
                            } else {
                                Circle()
                                    .fill(Color(hex: "#EE5060"))
                                    .frame(width: 32, height: 32)
                            }
                        }
                    }
                    .buttonStyle(NeonPressableButtonStyle())
                    .disabled(isExporting)
                    
                    // Right: Green Rotate Clockwise
                    Button(action: {
                        HapticManager.shared.lightImpact()
                        rotationDegrees += 90
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#00E676"))
                                .frame(width: 52, height: 52)
                                .shadow(color: Color(hex: "#00E676").opacity(0.4), radius: 6)
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 22, weight: .heavy))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(NeonPressableButtonStyle())
                }
                .padding(.bottom, 36)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = exportedVideoUrl {
                ShareActivityView(activityItems: [url])
            }
        }
        .alert("Notice", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
    }
    
    private func renderPreview() -> UIImage? {
        PNGExporter.renderImage(
            strokes: strokes,
            size: CGSize(width: 250, height: 350),
            backgroundColor: .black
        )
    }
    
    private func startMovieExport() {
        guard !strokes.isEmpty else {
            alertMessage = "No strokes to export into movie!"
            return
        }
        
        isExporting = true
        HapticManager.shared.mediumImpact()
        
        TimelapseExporter.exportVideo(
            strokes: strokes,
            outputSize: CGSize(width: 720, height: 1280),
            fps: 30,
            targetDurationSeconds: videoDurationSeconds,
            progressHandler: { p in
                exportProgress = p
            }
        ) { result in
            isExporting = false
            switch result {
            case .success(let url):
                exportedVideoUrl = url
                showShareSheet = true
                HapticManager.shared.success()
            case .failure(let err):
                alertMessage = "Export failed: \(err.localizedDescription)"
                HapticManager.shared.warning()
            }
        }
    }
}

// Custom Starry Sky Background with twinkling stars
private struct StarrySkyBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "#0D0A24"),
                    Color(hex: "#1B1745"),
                    Color(hex: "#2B215A"),
                    Color(hex: "#150D32")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Randomly distributed stars
            Canvas { context, size in
                var rng = SystemRandomNumberGenerator()
                for _ in 0..<120 {
                    let x = Double.random(in: 0...size.width, using: &rng)
                    let y = Double.random(in: 0...size.height, using: &rng)
                    let r = Double.random(in: 0.8...2.2, using: &rng)
                    let opacity = Double.random(in: 0.3...0.95, using: &rng)
                    
                    let starRect = CGRect(x: x, y: y, width: r * 2, height: r * 2)
                    context.fill(Path(ellipseIn: starRect), with: .color(Color.white.opacity(opacity)))
                }
            }
        }
    }
}
