import CoreHaptics
import Foundation

@MainActor
final class CoreHapticsBreathGuide: ObservableObject {
    private var engine: CHHapticEngine?
    private var player: CHHapticAdvancedPatternPlayer?
    private(set) var isPrepared = false

    func prepare() {
        do {
            let hapticEngine = try CHHapticEngine()
            hapticEngine.resetHandler = { [weak self] in
                Task { @MainActor in
                    self?.prepare()
                }
            }
            try hapticEngine.start()
            engine = hapticEngine
            isPrepared = true
        } catch {
            engine = nil
            player = nil
            isPrepared = false
        }
    }

    func stop() {
        try? player?.stop(atTime: CHHapticTimeImmediate)
    }

    func play(phase: BreathingPhase) {
        guard let engine else { return }

        do {
            try engine.start()
            let player = try engine.makeAdvancedPlayer(with: makePhasePattern(phase, seconds: Double(phase.seconds)))
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            prepare()
        }
    }

    private func makePhasePattern(_ phase: BreathingPhase, seconds: Double) throws -> CHHapticPattern {
        let intensity: Float
        let sharpness: Float

        switch phase {
        case .inhale:
            intensity = 0.28
            sharpness = 0.45
        case .hold:
            intensity = 0.16
            sharpness = 0.25
        case .exhale:
            intensity = 0.34
            sharpness = 0.55
        }

        let intensityParameter = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
        let sharpnessParameter = CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [intensityParameter, sharpnessParameter],
            relativeTime: 0,
            duration: seconds
        )

        return try CHHapticPattern(events: [event], parameters: [])
    }
}
