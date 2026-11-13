import AVFAudio
import PocketUI
import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AmbientRecordingModel.startedAt, order: .reverse) private var recordings: [AmbientRecordingModel]
    @StateObject private var recorder = AudioRecorderService()
    @State private var player: AVAudioPlayer?
    @State private var playingID: UUID?
    @State private var recordingStarted = Date()
    @State private var showsPermissionDenied = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    RecorderCard(
                        isRecording: recorder.isRecording,
                        error: recorder.errorMessage,
                        onStart: startRecording,
                        onStop: stopRecording
                    )

                    if recordings.isEmpty {
                        EmptyStateView(
                            systemImage: "waveform",
                            title: "还没有环境记录",
                            message: "录下咖啡店的嘈杂、雨声或深夜的安静。"
                        )
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(recordings) { recording in
                                RecordingCard(
                                    recording: recording,
                                    isPlaying: playingID == recording.id,
                                    onPlay: { play(recording) },
                                    onStop: stopPlaying,
                                    onDelete: { delete(recording) }
                                )
                            }
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle("AmbientLog")
            .alert("麦克风权限被拒绝", isPresented: $showsPermissionDenied) {
                Button("打开设置") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("录音需要麦克风权限。你可以在系统设置中重新开启。")
            }
        }
    }

    private func startRecording() {
        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async {
                guard granted else {
                    showsPermissionDenied = true
                    return
                }
                guard let url = recorder.startRecording() else { return }
                recordingStarted = Date()
                _ = url
            }
        }
    }

    private func stopRecording() {
        let duration = recorder.stopRecording()
        let title = "环境记录 \(Date().formatted(date: .abbreviated, time: .shortened))"
        guard let fileURL = recorder.lastFileURL else { return }
        modelContext.insert(
            AmbientRecordingModel(
                title: title,
                startedAt: recordingStarted,
                duration: duration,
                fileURLString: fileURL.path
            )
        )
        try? modelContext.save()
        recorder.clearLastFileURL()
    }

    private func play(_ recording: AmbientRecordingModel) {
        stopPlaying()
        player = try? AVAudioPlayer(contentsOf: recording.fileURL)
        player?.play()
        playingID = recording.id
    }

    private func stopPlaying() {
        player?.stop()
        player = nil
        playingID = nil
    }

    private func delete(_ recording: AmbientRecordingModel) {
        try? FileManager.default.removeItem(at: recording.fileURL)
        modelContext.delete(recording)
        try? modelContext.save()
    }
}

private struct RecorderCard: View {
    let isRecording: Bool
    let error: String?
    let onStart: () -> Void
    let onStop: () -> Void

    var body: some View {
        CardContainer {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(isRecording ? "正在记录环境音" : "准备记录环境音")
                        .font(.headline)
                    if let error {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
                Spacer()
                Image(systemName: isRecording ? "waveform.circle.fill" : "waveform.circle")
                    .font(.largeTitle)
                    .foregroundStyle(.tint)
            }

            PrimaryButton(
                isRecording ? "停止" : "开始录音",
                systemImage: isRecording ? "stop.fill" : "record.circle",
                role: isRecording ? .destructive : nil
            ) {
                isRecording ? onStop() : onStart()
            }
        }
    }
}

private struct RecordingCard: View {
    let recording: AmbientRecordingModel
    let isPlaying: Bool
    let onPlay: () -> Void
    let onStop: () -> Void
    let onDelete: () -> Void

    var body: some View {
        CardContainer {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(recording.title)
                        .font(.headline)
                    Text("\(Int(recording.duration)) 秒 · \(recording.startedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    isPlaying ? onStop() : onPlay()
                } label: {
                    Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                        .font(.title)
                }
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
            }
        }
    }
}
