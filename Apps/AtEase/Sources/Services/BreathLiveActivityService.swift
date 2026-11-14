import ActivityKit
import Foundation

@MainActor
protocol BreathLiveActivityServicing {
    func canStart() -> Bool
    @discardableResult
    func start(patternTitle: String, phaseTitle: String, progress: Double, remainingSeconds: Int) -> Bool
    func update(phaseTitle: String, progress: Double, remainingSeconds: Int, isPaused: Bool)
    func end(elapsedSeconds: Int)
}

struct NoopBreathLiveActivityService: BreathLiveActivityServicing {
    func canStart() -> Bool {
        false
    }

    @discardableResult
    func start(patternTitle: String, phaseTitle: String, progress: Double, remainingSeconds: Int) -> Bool {
        false
    }

    func update(phaseTitle: String, progress: Double, remainingSeconds: Int, isPaused: Bool) {}
    func end(elapsedSeconds: Int) {}
}

@MainActor
final class SystemBreathLiveActivityService: BreathLiveActivityServicing, ObservableObject {
    private var activity: Activity<BreathActivityAttributes>?

    func canStart() -> Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    func start(
        patternTitle: String,
        phaseTitle: String,
        progress: Double,
        remainingSeconds: Int
    ) -> Bool {
        guard activity == nil, canStart() else { return false }

        let state = BreathActivityAttributes.ContentState(
            phaseTitle: phaseTitle,
            progress: progress,
            remainingSeconds: remainingSeconds,
            isPaused: false
        )

        do {
            activity = try Activity.request(
                attributes: BreathActivityAttributes(patternTitle: patternTitle),
                content: .init(state: state, staleDate: nil)
            )
            return activity != nil
        } catch {
            activity = nil
            return false
        }
    }

    func update(
        phaseTitle: String,
        progress: Double,
        remainingSeconds: Int,
        isPaused: Bool
    ) {
        guard let activity else { return }
        let state = BreathActivityAttributes.ContentState(
            phaseTitle: phaseTitle,
            progress: progress,
            remainingSeconds: remainingSeconds,
            isPaused: isPaused
        )
        Task {
            await activity.update(.init(state: state, staleDate: nil))
        }
    }

    func end(elapsedSeconds: Int) {
        guard let activity else { return }
        let state = BreathActivityAttributes.ContentState(
            phaseTitle: "已结束",
            progress: 1,
            remainingSeconds: 0,
            isPaused: false
        )
        Task {
            await activity.end(.init(state: state, staleDate: nil), dismissalPolicy: .immediate)
        }
        self.activity = nil
    }
}
