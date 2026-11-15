import AVFAudio
import PocketCore
import PocketUI
import SwiftData
import SwiftUI

struct MeditationPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var player: MeditationScriptPlayer
    @StateObject private var audioGuide = AtEaseAudioGuide()
    @StateObject private var audioPreparation: MeditationAudioPreparationService
    @State private var startedAt = Date()
    @State private var hapticPlayer: any AtEaseHapticPlayer = SystemAtEaseHapticPlayer()
    @State private var showSubscriptionEntry = false
    @State private var showSubscription = false
    @State private var isAccessDenied = false
    @AppStorage("atease.voiceGuidanceEnabled") private var voiceGuidanceEnabled = true
    let item: MeditationContentItem

    init(item: MeditationContentItem, isSubscribed: Bool = false) {
        self.item = item
        self.isSubscribed = isSubscribed
        _player = StateObject(wrappedValue: MeditationScriptPlayer(content: item))
        _audioPreparation = StateObject(
            wrappedValue: MeditationAudioPreparationService(downloadService: ContentDownloadService())
        )
    }

    private let isSubscribed: Bool

    var body: some View {
        ZStack {
            AtEaseDesignTokens.breathBackground.ignoresSafeArea()

            VStack(spacing: 44) {
                HStack {
                    Button {
                        saveProgress()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding(.leading, 24)
                    Spacer()
                }
                .padding(.top, 24)

                VStack(alignment: .leading, spacing: 10) {
                    Text(item.title)
                        .font(.largeTitle.weight(.light))
                        .foregroundStyle(.white.opacity(0.85))
                    Text(item.teacher)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.45))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AtEaseDesignTokens.pagePadding)

                Spacer()

                if isAccessDenied {
                    Text("需要订阅解锁")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.55))
                }

                if case .preparing = audioPreparation.state {
                    Text("正在准备音频")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.55))
                }

                if case .failed = audioPreparation.state {
                    Text("音频暂时无法准备")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.55))
                }

                if let step = player.playbackStep {
                    VStack(spacing: 18) {
                        Text(step.title)
                            .font(.title2.weight(.light))
                            .foregroundStyle(.white.opacity(0.7))
                            .animation(.easeInOut(duration: 0.3), value: step.id)

                        Text(step.text)
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .animation(.easeInOut(duration: 0.3), value: step.id)
                    }
                }

                VStack(spacing: 12) {
                    ProgressView(value: player.overallProgress)
                        .tint(AtEaseDesignTokens.accentBreath)
                    HStack {
                        Text("已完成 \(player.completedSeconds / 60) 分钟")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                        Spacer()
                        Text("\(player.totalSeconds / 60) 分钟")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                .padding(.horizontal, AtEaseDesignTokens.pagePadding)

                Spacer()

                HStack(spacing: 32) {
                    if isPreparingAudio {
                        ProgressView()
                            .frame(width: 48, height: 48)
                    } else {
                        Button {
                            if player.status == .playing {
                                player.pause()
                                audioPreparation.pause()
                            } else {
                                player.resume()
                                audioPreparation.resume()
                            }
                        } label: {
                            Image(systemName: player.status == .playing ? "pause.fill" : "play.fill")
                                .font(.title2)
                                .foregroundStyle(.white.opacity(0.75))
                                .frame(width: 48, height: 48)
                        }
                        .accessibilityLabel(player.status == .playing ? "暂停" : "继续")
                    }

                    Button {
                        saveProgress()
                        dismiss()
                    } label: {
                        Image(systemName: "stop.circle")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.55))
                            .frame(width: 48, height: 48)
                    }
                    .accessibilityLabel("结束练习")
                }
                .padding(.bottom, 48)

                if showSubscriptionEntry {
                    Button {
                        showSubscription = true
                    } label: {
                        Text("解锁完整睡眠故事库与多周课程 →")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.45))
                    }
                    .accessibilityHint("打开订阅页")
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            guard accessService.canPlay(item, isSubscribed: isSubscribed) else {
                isAccessDenied = true
                return
            }

            if item.audioKind == .remote {
                await audioPreparation.prepare(for: item)
                guard audioPreparation.state == .ready else { return }
            }

            player.voiceEnabled = voiceGuidanceEnabled
            player.start()
        }
        .onChange(of: player.playbackStep?.id) { _, _ in
            guard voiceGuidanceEnabled, let step = player.playbackStep else { return }
            audioGuide.speak("\(step.title)。\(step.text)")
            if step.hapticEnabled {
                hapticPlayer.phaseChange()
            }
        }
        .onChange(of: player.status) { _, status in
            if status == .completed {
                saveProgress()
                audioPreparation.stop()
            }
        }
        .sheet(isPresented: $showSubscription) {
            NavigationStack {
                AtEaseSubscriptionView()
            }
        }
        .onDisappear {
            player.stop()
            audioPreparation.stop()
        }
    }

    private func saveProgress() {
        guard accessService.canPlay(item, isSubscribed: isSubscribed) else { return }

        let endedAt = Date()
        let seconds = max(1, player.completedSeconds)
        let session = PracticeSessionModel(
            kind: .guided,
            startedAt: startedAt,
            endedAt: endedAt,
            mindfulSeconds: seconds
        )
        modelContext.insert(session)

        if let state = fetchState() {
            state.lastPlayedAt = endedAt
            state.completedSeconds = max(state.completedSeconds, seconds)
            state.isCompleted = state.isCompleted || player.status == .completed
        } else {
            modelContext.insert(
                GuidedContentStateModel(
                    contentID: item.id,
                    isFavorite: false,
                    lastPlayedAt: endedAt,
                    completedSeconds: seconds,
                    isCompleted: player.status == .completed,
                    downloadState: localDownloadState.rawValue
                )
            )
        }
        try? modelContext.save()

        let sessionCount = (try? modelContext.fetchCount(FetchDescriptor<PracticeSessionModel>())) ?? 0
        showSubscriptionEntry = SubscriptionEntryRule.shouldShowEntry(afterSessionCount: sessionCount)
    }

    private func fetchState() -> GuidedContentStateModel? {
        let descriptor = FetchDescriptor<GuidedContentStateModel>()
        return (try? modelContext.fetch(descriptor))?.first { $0.contentID == item.id }
    }

    private let accessService = MeditationContentAccessService()

    private var isPreparingAudio: Bool {
        if case .preparing = audioPreparation.state {
            return true
        }
        return false
    }

    private var localDownloadState: ContentDownloadState {
        switch item.audioKind {
        case .scripted, .bundled:
            return .notApplicable
        case .remote:
            return audioPreparation.state == .ready ? .downloaded : .failed
        }
    }
}
