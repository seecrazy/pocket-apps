import PocketCore
import PocketUI
import SwiftData
import SwiftUI
import UIKit

struct AtEaseThoughtDistancingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var thought = ""
    @State private var holdStartedAt: Date?
    @State private var progress: Double = 0
    @State private var hasCompleted = false
    @State private var startedAt = Date()
    @State private var timer: Timer?
    @State private var hapticPlayer: any AtEaseHapticPlayer = SystemAtEaseHapticPlayer()
    @State private var healthWriter = HealthKitMindfulMinutesWriter()

    private let holdDuration: TimeInterval = 8

    var body: some View {
        ZStack {
            AtEaseDesignTokens.canvas.ignoresSafeArea()

            VStack(spacing: AtEaseDesignTokens.sectionSpacing) {
                HStack {
                    Button {
                        saveSession()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body)
                            .foregroundStyle(AtEaseDesignTokens.textSecondary.opacity(0.4))
                    }
                    .accessibilityLabel("关闭")
                    .padding(.leading, 24)
                    Spacer()
                }
                .padding(.top, 24)

                Spacer()

                ZStack {
                    Circle()
                        .stroke(AtEaseDesignTokens.accentBreath.opacity(0.18), lineWidth: 1.5)
                        .frame(width: 240, height: 240)

                    Circle()
                        .stroke(AtEaseDesignTokens.accentBreath.opacity(0.7), lineWidth: 1.5)
                        .frame(width: 240, height: 240)
                        .scaleEffect(1 + progress * 0.35)
                        .opacity(0.7 - progress * 0.4)

                    Text(displayThought)
                        .font(.body)
                        .foregroundStyle(AtEaseDesignTokens.textPrimary.opacity(max(0, 1 - progress)))
                        .padding(.horizontal, 40)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 260)
                .contentShape(.rect)
                .gesture(pressGesture)

                Text(prompt)
                    .font(.subheadline)
                    .foregroundStyle(AtEaseDesignTokens.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                if hasCompleted {
                    Text("念头已经放下。")
                        .font(.body)
                        .foregroundStyle(AtEaseDesignTokens.textPrimary)
                }

                PrimaryButton(hasCompleted ? "结束" : "跳过") {
                    saveSession()
                    dismiss()
                }
                .padding(.horizontal, AtEaseDesignTokens.pagePadding)
                .padding(.bottom, 48)
            }
        }
        .navigationBarHidden(true)
        .onDisappear {
            timer?.invalidate()
        }
    }

    private var displayThought: String {
        thought.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "把此刻占据你的念头放在这里" : thought
    }

    private var prompt: String {
        if hasCompleted {
            return "不需要评价这一次。"
        }
        if holdStartedAt != nil {
            return "按住不放，让它慢慢离开。"
        }
        return "写下或不说。长按屏幕开始。"
    }

    private var pressGesture: some Gesture {
        LongPressGesture(minimumDuration: holdDuration)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .local))
            .onChanged { value in
                switch value {
                case .first:
                    beginHoldIfNeeded()
                case let .second(_, drag):
                    beginHoldIfNeeded()
                    if let start = holdStartedAt {
                        progress = min(1, Date().timeIntervalSince(start) / holdDuration)
                    }
                    _ = drag
                @unknown default:
                    break
                }
            }
            .onEnded { _ in
                if progress >= 1 {
                    complete()
                } else {
                    resetHold()
                }
            }
    }

    private func beginHoldIfNeeded() {
        guard holdStartedAt == nil else { return }
        holdStartedAt = Date()
        startedAt = Date()
        hapticPlayer.prepare()
        hapticPlayer.phaseChange()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            Task { @MainActor in
                guard let start = holdStartedAt else { return }
                progress = min(1, Date().timeIntervalSince(start) / holdDuration)
                if progress >= 1 {
                    timer?.invalidate()
                    complete()
                }
            }
        }
    }

    private func resetHold() {
        timer?.invalidate()
        timer = nil
        holdStartedAt = nil
        withAnimation(.easeInOut(duration: 0.4)) {
            progress = 0
        }
    }

    private func complete() {
        guard !hasCompleted else { return }
        hasCompleted = true
        hapticPlayer.phaseChange()
        try? modelContext.save()
    }

    private func saveSession() {
        let endedAt = Date()
        let seconds = max(1, hasCompleted ? 8 : Int(Date().timeIntervalSince(startedAt)))
        let session = PracticeSessionModel(
            kind: .thoughtDistancing,
            startedAt: startedAt,
            endedAt: endedAt,
            mindfulSeconds: seconds
        )
        modelContext.insert(session)
        try? modelContext.save()
        Task {
            _ = await healthWriter.save(seconds: Double(seconds), startedAt: startedAt, endedAt: endedAt)
        }
    }
}
