import UIKit

public final class HapticManager {
    public static let shared = HapticManager()

    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()

    private init() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }

    public func impact() {
        mediumGenerator.impactOccurred(intensity: 0.6)
    }

    public func lightImpact() {
        lightGenerator.impactOccurred()
    }

    public func mediumImpact() {
        mediumGenerator.impactOccurred()
    }

    public func success() {
        notificationGenerator.notificationOccurred(.success)
    }

    public func warning() {
        notificationGenerator.notificationOccurred(.warning)
    }

    public func selectionChanged() {
        selectionGenerator.selectionChanged()
    }
}
