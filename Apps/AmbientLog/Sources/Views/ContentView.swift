import AVFAudio
import PocketCore
import PocketUI
import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AmbientRecordingModel.startedAt, order: .reverse) private var recordings: [AmbientRecordingModel]
    @StateObject private var recorder = AudioRecorderService()
    @State private var player: AVAudioPlayer?
    @State private var playingID: UUID?
    @State private var showsPermissionDenied = false
    @State private var searchText = ""
    @State private var renamingRecording: AmbientRecordingModel?
    @State private var renameText = ""
    @State private var playbackError: String?
    @State private var deletingRecording: AmbientRecordingModel?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    RecorderCard(
                        isRecording: recorder.isRecording,
                        error: recorder.errorMessage,
                        interruption: recorder.interruptionReason,
                        onStart: startRecording,
                        onStop: stopRecording
                    )

                    SearchField(text: $searchText, placeholder: "搜索环境记录")

                    if filteredRecordings.isEmpty {
                        EmptyStateView(
                            systemImage: searchText.isEmpty ? "waveform" : "questionmark.magnifyingglass",
                            title: searchText.isEmpty ? "还没有环境记录" : "没有匹配的记录",
                            message: searchText.isEmpty ? "录下咖啡店的嘈杂、雨声或深夜的安静。" : "换一个关键词试试。"
                        )
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredRecordings) { recording in
                                RecordingCard(
                                    recording: recording,
                                    isPlaying: playingID == recording.id,
                                    onPlay: { play(recording) },
                                    onStop: stopPlaying,
                                    onRename: {
                                        renamingRecording = recording
                                        renameText = recording.title
                                    },
                                    onDelete: { deletingRecording = recording }
                                )
                            }
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle("AmbientLog")
            .onAppear {
                recorder.onInterruption = { fileURL, duration in
                    saveRecording(fileURL: fileURL, duration: duration)
                }
            }
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
            .alert(
                "无法播放音频",
                isPresented: Binding(
                    get: { playbackError != nil },
                    set: {
                        if !$0 {
                            playbackError = nil
                        }
                    }
                )
            ) {
                Button("好", role: .cancel) {}
            } message: {
                Text(playbackError ?? "音频文件不可用。")
            }
            .confirmationDialog(
                "删除录音？",
                isPresented: Binding(
                    get: { deletingRecording != nil },
                    set: {
                        if !$0 {
                            deletingRecording = nil
                        }
                    }
                ),
                titleVisibility: .visible
            ) {
                Button("删除", role: .destructive) {
                    if let recording = deletingRecording {
                        delete(recording)
                    }
                    deletingRecording = nil
                }
                Button("取消", role: .cancel) {
                    deletingRecording = nil
                }
            } message: {
                Text("会同时删除沙盒中的音频文件，且无法恢复。")
            }
            .sheet(item: $renamingRecording) { recording in
                RenameSheet(
                    title: renameText,
                    onRename: { newTitle in
                        recording.title = newTitle.isEmpty ? recording.title : newTitle
                        try? modelContext.save()
                        renamingRecording = nil
                    },
                    onCancel: {
                        renamingRecording = nil
                    }
                )
            }
        }
    }

    private var filteredRecordings: [AmbientRecordingModel] {
        AmbientRecordingLibrary.filtered(recordings, query: searchText)
    }

    private func startRecording() {
        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async {
                guard granted else {
                    showsPermissionDenied = true
                    return
                }
                _ = recorder.startRecording()
            }
        }
    }

    private func stopRecording() {
        let duration = recorder.stopRecording()
        guard let fileURL = recorder.lastFileURL else { return }
        saveRecording(fileURL: fileURL, duration: duration)
    }

    private func saveRecording(fileURL: URL, duration: TimeInterval) {
        let startedAt = recorder.recordingStartedAt ?? Date()
        let title = "环境记录 \(startedAt.formatted(date: .abbreviated, time: .shortened))"
        modelContext.insert(
            AmbientRecordingModel(
                title: title,
                startedAt: startedAt,
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
        if let player {
            player.play()
            playingID = recording.id
        } else {
            playbackError = "找不到可播放的音频文件，或文件已损坏。"
        }
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

private struct RenameSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State var title: String
    let onRename: (String) -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("记录名称", text: $title)
            }
            .navigationTitle("重命名")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        dismiss()
                        onRename(title)
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                        onCancel()
                    }
                }
            }
        }
    }
}

private struct RecorderCard: View {
    let isRecording: Bool
    let error: String?
    let interruption: String?
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
                    if let interruption {
                        Text(interruption)
                            .font(.footnote)
                            .foregroundStyle(.orange)
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
    let onRename: () -> Void
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
                HStack(spacing: 8) {
                    Button {
                        isPlaying ? onStop() : onPlay()
                    } label: {
                        Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                            .font(.title)
                    }
                    .accessibilityLabel(isPlaying ? "停止播放" : "播放录音")
                    Button(action: onRename) {
                        Image(systemName: "pencil")
                    }
                    .accessibilityLabel("重命名录音")
                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash")
                    }
                    .accessibilityLabel("删除录音")
                }
            }
        }
    }
}
