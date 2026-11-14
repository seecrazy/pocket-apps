import CoreHaptics
import Foundation
import UIKit

@MainActor
protocol AtEaseHapticPlayer {
    func phaseChange()
    func prepare()
}

struct SystemAtEaseHapticPlayer: AtEaseHapticPlayer {
    func phaseChange() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    func prepare() {
        UIImpactFeedbackGenerator(style: .soft).prepare()
    }
}

@MainActor
final class CoreHapticsAtEasePlayer: AtEaseHapticPlayer {
    private var engine: CHHapticEngine?
    private var player: CHHapticAdvancedPatternPlayer?

    init() {
        prepare()
    }

    func prepare() {
        do {
            let hapticEngine = try CHHapticEngine()
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.25)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            player = try hapticEngine.makeAdvancedPlayer(with: pattern)
            try hapticEngine.start()
            engine = hapticEngine
        } catch {
            engine = nil
            player = nil
        }
    }

    func phaseChange() {
        do {
            guard engine != nil else { return }
            try player?.start(atTime: CHHapticTimeImmediate)
        } catch {
            prepare()
        }
    }
}
