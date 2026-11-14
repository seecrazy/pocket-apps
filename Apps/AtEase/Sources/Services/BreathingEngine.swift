import Foundation
import SwiftUI

@MainActor
final class BreathingEngine: ObservableObject {
    @Published private(set) var phase: BreathingPhase
    @Published private(set) var phaseRemaining: Int
    @Published private(set) var cycle: Int = 0
    @Published private(set) var elapsedSeconds: Int = 0
    @Published private(set) var isPaused = false
    @Published var hapticsEnabled = true

    private let pattern: BreathingPattern
    private var timer: Timer?
    private var phaseIndex = 0
    private var onPhaseChange: ((BreathingPhase) -> Void)?

    init(pattern: BreathingPattern = .relaxing, onPhaseChange: ((BreathingPhase) -> Void)? = nil) {
        self.pattern = pattern
        let phases = pattern.phases
        phase = phases[0]
        phaseRemaining = phases[0].seconds
        self.onPhaseChange = onPhaseChange
    }

    var progress: Double {
        let planned = max(1, pattern.phases.reduce(0) { $0 + $1.seconds })
        let completed = elapsedSeconds % planned
        return Double(completed) / Double(planned)
    }

    func start() {
        guard timer == nil else { return }
        isPaused = false
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    func pause() {
        timer?.invalidate()
        timer = nil
        isPaused = true
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isPaused = true
    }

    private func tick() {
        elapsedSeconds += 1
        if phaseRemaining > 1 {
            phaseRemaining -= 1
            return
        }

        phaseIndex = (phaseIndex + 1) % pattern.phases.count
        let next = pattern.phases[phaseIndex]
        if phaseIndex == 0 {
            cycle += 1
        }
        phase = next
        phaseRemaining = next.seconds
        onPhaseChange?(next)
    }
}
