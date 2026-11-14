import PocketCore
import PocketUI
import SwiftData
import SwiftUI

struct AtEaseTimerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var audioGuide = AtEaseAudioGuide()
    @StateObject private var ambientMixer = AmbientSoundMixer()
    @State private var healthWriter = HealthKitMindfulMinutesWriter()
    @AppStorage("atease.voiceGuidanceEnabled") private var voiceGuidanceEnabled = true
    @State private var minutes: Int
    @State private var remainingSeconds: Int
    @State private var isRunning = false
    @State private var startedAt = Date()
    @State private var timer: Timer?
    let moodLevel: Int?

    init(minutes: Int = 5, moodLevel: Int? = nil) {
        _minutes = State(initialValue: min(max(minutes, 1), 60))
        _remainingSeconds = State(initialValue: min(max(minutes, 1), 60) * 60)
        self.moodLevel = moodLevel
    }

    var body: some View {
        ZStack {
            AtEaseDesignTokens.breathBackground.ignoresSafeArea()

            VStack(spacing: 48) {
                HStack {
                    Button {
                        saveSession()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding(.leading, 24)

                    Spacer()

                    Button {
                        voiceGuidanceEnabled.toggle()
                    } label: {
                        Image(systemName: voiceGuidanceEnabled ? "speaker.wave.2" : "speaker.slash")
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .accessibilityLabel(voiceGuidanceEnabled ? "关闭声音引导" : "开启声音引导")
                    .padding(.trailing, 24)
                }
                .padding(.top, 24)

                Spacer()

                Text(timeString)
                    .font(.system(size: 64, weight: .light))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.85))

                if isRunning {
                    Text("自由练习")
                        .font(.subheadline.weight(.light))
                        .foregroundStyle(.white.opacity(0.4))
                } else {
                    Stepper(value: $minutes, in: 1 ... 60) {
                        Text("\(minutes) 分钟")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.65))
                    }
                    .padding(.horizontal, 40)
                }

                AmbientSoundCard(mixer: ambientMixer)
                    .padding(.horizontal, 24)

                Spacer()

                PrimaryButton(isRunning ? "暂停" : "开始") {
                    isRunning ? pause() : start()
                }
                .frame(maxWidth: 220)
                .padding(.bottom, 48)
            }
        }
        .preferredColorScheme(.dark)
        .onDisappear {
            timer?.invalidate()
            ambientMixer.stop()
        }
    }

    private var timeString: String {
        String(format: "%02d:%02d", remainingSeconds / 60, remainingSeconds % 60)
    }

    private func start() {
        startedAt = Date()
        isRunning = true
        if voiceGuidanceEnabled {
            audioGuide.startTimer()
        }
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                tick()
            }
        }
    }

    private func pause() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    private func tick() {
        guard remainingSeconds > 1 else {
            if voiceGuidanceEnabled {
                audioGuide.finish()
            }
            saveSession()
            dismiss()
            return
        }
        remainingSeconds -= 1
    }

    private func saveSession() {
        let endedAt = Date()
        let elapsed = max(1, minutes * 60 - remainingSeconds)
        let session = PracticeSessionModel(
            kind: .timer,
            startedAt: startedAt,
            endedAt: endedAt,
            mindfulSeconds: elapsed,
            moodLevel: moodLevel
        )
        modelContext.insert(session)
        try? modelContext.save()
        Task {
            _ = await healthWriter.save(seconds: Double(elapsed), startedAt: startedAt, endedAt: endedAt)
        }
    }
}
