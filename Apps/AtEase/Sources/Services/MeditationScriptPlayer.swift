import Foundation
import SwiftUI

enum MeditationPlaybackStatus: Equatable {
    case ready
    case playing
    case paused
    case completed
}

struct MeditationPlaybackStep: Identifiable, Equatable {
    let id: String
    let title: String
    let text: String
    let remainingSeconds: Int
    let progress: Double
    let hapticEnabled: Bool
}

@MainActor
final class MeditationScriptPlayer: ObservableObject {
    @Published private(set) var status: MeditationPlaybackStatus = .ready
    @Published private(set) var currentStepIndex: Int = 0
    @Published private(set) var stepRemainingSeconds: Int
    @Published private(set) var completedSeconds: Int = 0
    @Published var voiceEnabled = true

    let content: MeditationContentItem
    private var timer: Timer?
    private let onStepChange: ((MeditationContentStep) -> Void)?

    init(content: MeditationContentItem, onStepChange: ((MeditationContentStep) -> Void)? = nil) {
        self.content = content
        stepRemainingSeconds = content.steps.first?.durationSeconds ?? 0
        self.onStepChange = onStepChange
    }

    var currentStep: MeditationContentStep? {
        content.steps[safe: currentStepIndex]
    }

    var totalSeconds: Int {
        content.durationSeconds
    }

    var overallProgress: Double {
        guard totalSeconds > 0 else { return 0 }
        let prior = content.steps.prefix(currentStepIndex).reduce(0) { $0 + $1.durationSeconds }
        let current = content.steps[currentStepIndex].durationSeconds - stepRemainingSeconds
        return min(1, Double(prior + max(0, current)) / Double(totalSeconds))
    }

    var playbackStep: MeditationPlaybackStep? {
        guard let step = currentStep else { return nil }
        let total = max(1, step.durationSeconds)
        let elapsed = total - stepRemainingSeconds
        return MeditationPlaybackStep(
            id: step.id,
            title: step.title,
            text: step.text,
            remainingSeconds: stepRemainingSeconds,
            progress: Double(elapsed) / Double(total),
            hapticEnabled: step.hapticEnabled
        )
    }

    func start() {
        guard status == .ready else { return }
        status = .playing
        startTimer()
        if let step = currentStep {
            onStepChange?(step)
        }
    }

    func pause() {
        guard status == .playing else { return }
        timer?.invalidate()
        timer = nil
        status = .paused
    }

    func resume() {
        guard status == .paused else { return }
        status = .playing
        startTimer()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    func advanceOneSecond() {
        tick()
    }

    private func tick() {
        guard status == .playing else { return }
        completedSeconds += 1
        if stepRemainingSeconds > 1 {
            stepRemainingSeconds -= 1
            return
        }

        if currentStepIndex < content.steps.count - 1 {
            currentStepIndex += 1
            stepRemainingSeconds = content.steps[currentStepIndex].durationSeconds
            if let step = currentStep {
                onStepChange?(step)
            }
        } else {
            timer?.invalidate()
            timer = nil
            status = .completed
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
