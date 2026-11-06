import Foundation
import AudioToolbox

final class SoundEffectManager {
    static let shared = SoundEffectManager()
    
    var isSoundEnabled: Bool = true
    
    private init() {}
    
    func playPop() {
        guard isSoundEnabled else { return }
        // System sound 1104 is a subtle tap/pop
        AudioServicesPlaySystemSound(1104)
    }
    
    func playUndo() {
        guard isSoundEnabled else { return }
        // System sound 1103 is a soft swoosh/back
        AudioServicesPlaySystemSound(1103)
    }
    
    func playTrash() {
        guard isSoundEnabled else { return }
        // System sound 1105 is trash can crumple
        AudioServicesPlaySystemSound(1105)
    }
    
    func playClick() {
        guard isSoundEnabled else { return }
        AudioServicesPlaySystemSound(1123)
    }
}
