import UIKit

public enum HapticImpact {
    case light
    case medium
    case success
    case warning
}

public protocol HapticPerformer {
    func perform(_ impact: HapticImpact)
}

public struct SystemHaptics: HapticPerformer {
    public init() {}

    public func perform(_ impact: HapticImpact) {
        switch impact {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
    }
}
