import PocketCore
import PocketUI
import SwiftData
import SwiftUI

struct AtEaseBreathView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var engine: BreathingEngine
    @State private var startedAt = Date()
    @State private var showsExitConfirmation = false
    @State private var hapticsEnabled = UserDefaults.standard.bool(forKey: "atease.hapticsEnabled")
    let practiceKind: AtEasePracticeKind
    let moodLevel: Int?

    init(
        pattern: BreathingPattern,
        practiceKind: AtEasePracticeKind,
        moodLevel: Int? = nil
    ) {
        _engine = StateObject(wrappedValue: BreathingEngine(pattern: pattern))
        self.practiceKind = practiceKind
        self.moodLevel = moodLevel
    }

    var body: some View {
        ZStack {
            AtEaseDesignTokens.breathBackground.ignoresSafeArea()

            VStack(spacing: 48) {
                HStack {
                    Button {
                        showsExitConfirmation = true
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding(.leading, 24)
                    Spacer()
                }
                .padding(.top, 24)

                Spacer()

                BreathingRing(phase: engine.phase, progress: engine.progress)

                Text(engine.phase.title)
                    .font(.subheadline.weight(.light))
                    .foregroundStyle(.white.opacity(0.5))
                    .opacity(engine.phase.title == "屏息" ? 0.7 : 1)

                Spacer()

                HStack(spacing: 32) {
                    Button {
                        engine.isPaused ? engine.start() : engine.pause()
                    } label: {
                        Image(systemName: engine.isPaused ? "play.fill" : "pause.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.75))
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(engine.isPaused ? "继续" : "暂停")

                    Button {
                        saveSession()
                        dismiss()
                    } label: {
                        Image(systemName: "stop.circle")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.55))
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("结束本次呼吸")
                }
                .padding(.bottom, 48)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            engine.hapticsEnabled = hapticsEnabled
            engine.start()
        }
        .onDisappear {
            engine.stop()
        }
        .confirmationDialog(
            "结束本次呼吸？",
            isPresented: $showsExitConfirmation,
            titleVisibility: .visible
        ) {
            Button("结束并保存", role: .destructive) {
                saveSession()
                dismiss()
            }
            Button("继续", role: .cancel) {}
        } message: {
            Text("已完成时长会正常计入。")
        }
    }

    private func saveSession() {
        let seconds = max(1, engine.elapsedSeconds)
        let session = PracticeSessionModel(
            kind: practiceKind,
            startedAt: startedAt,
            endedAt: Date(),
            mindfulSeconds: seconds,
            moodLevel: moodLevel
        )
        modelContext.insert(session)
        try? modelContext.save()
    }
}

private struct BreathingRing: View {
    let phase: BreathingPhase
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(AtEaseDesignTokens.accentBreath.opacity(0.15), lineWidth: 2)
                .frame(width: 180, height: 180)

            Circle()
                .stroke(AtEaseDesignTokens.accentBreath.opacity(phase.opacity), lineWidth: 2)
                .frame(width: 100, height: 100)
                .scaleEffect(phase.scale)
                .animation(.easeInOut(duration: Double(phase.seconds)), value: phase)
        }
    }
}
