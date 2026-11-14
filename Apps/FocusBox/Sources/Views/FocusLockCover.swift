import PocketUI
import SwiftUI

struct FocusLockCover: View {
    let plannedMinutes: Int
    let intention: String?
    let remainingSeconds: Int
    let isPaused: Bool
    let onComplete: () -> Void
    let onTogglePause: () -> Void
    let onAbandon: () -> Void

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    Text("FocusBox Lock")
                        .font(.title.weight(.bold))
                    ActiveSessionCard(
                        plannedMinutes: plannedMinutes,
                        intention: intention,
                        remainingSeconds: remainingSeconds,
                        isPaused: isPaused,
                        onComplete: onComplete,
                        onTogglePause: onTogglePause,
                        onAbandon: onAbandon
                    )
                    Text("这是 App 内锁定，不是系统级 Screen Time 锁机。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
            }
        }
        .interactiveDismissDisabled(true)
    }
}
