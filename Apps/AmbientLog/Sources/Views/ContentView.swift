import AVFAudio
import PocketCore
import PocketUI
import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("ambientlog.hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("ambientlog.preferredCategory") private var preferredCategory = AmbientRecordingCategory.nature.rawValue
    @StateObject private var recorder = AudioRecorderService()

    var body: some View {
        TabView {
            NavigationStack {
                RecordView(recorder: recorder, preferredCategory: $preferredCategory)
            }
            .tabItem {
                Label("记录", systemImage: "record.circle")
            }

            NavigationStack {
                LibraryView()
            }
            .tabItem {
                Label("收藏", systemImage: "music.note.list")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("设置", systemImage: "gearshape")
            }
        }
        .onAppear {
            recorder.onInterruption = { fileURL, duration, levels in
                saveRecording(fileURL: fileURL, duration: duration, levels: levels)
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { !hasCompletedOnboarding },
            set: {
                if !$0 {
                    hasCompletedOnboarding = true
                }
            }
        )) {
            OnboardingPage(
                systemImage: "waveform.badge.magnifyingglass",
                title: "保存此刻的声音",
                message: "AmbientLog 是一个本机环境音记录工具，不上传音频，也没有社交功能。",
                bullets: [
                    "录音只保存在 App 沙盒中。",
                    "系统中断时自动停止，保留已录内容。",
                    "分类帮助你回看雨声、咖啡店或夜晚。",
                ],
                primaryTitle: "开始使用"
            ) {
                hasCompletedOnboarding = true
            }
        }
    }

    private func saveRecording(fileURL: URL, duration: TimeInterval, levels: [Double]) {
        let startedAt = recorder.recordingStartedAt ?? Date()
        let title = "环境记录 \(startedAt.formatted(date: .abbreviated, time: .shortened))"
        modelContext.insert(
            AmbientRecordingModel(
                title: title,
                category: preferredCategory,
                startedAt: startedAt,
                duration: duration,
                levels: levels,
                fileURLString: fileURL.path
            )
        )
        try? modelContext.save()
        recorder.clearLastFileURL()
    }
}

private struct RecordView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var recorder: AudioRecorderService
    @Binding var preferredCategory: String
    @State private var showsPermissionDenied = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                RecorderCard(
                    isRecording: recorder.isRecording,
                    error: recorder.errorMessage,
                    interruption: recorder.interruptionReason,
                    levels: recorder.levels,
                    currentPower: recorder.currentPower,
                    peakPower: recorder.peakPower,
                    averagePower: recorder.averagePower,
                    preferredCategory: $preferredCategory,
                    onStart: startRecording,
                    onStop: stopRecording
                )

                SettingSection(title: "录音提示") {
                    SettingRow(
                        systemImage: "iphone",
                        title: "只保存在本机",
                        detail: "录音文件不会自动上传。"
                    )
                    SettingRow(
                        systemImage: "waveform",
                        title: "中断保护",
                        detail: "电话或其他音频会话会自动停止录音。"
                    )
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
        let levels = recorder.lastLevels
        let startedAt = recorder.recordingStartedAt ?? Date()
        let title = "环境记录 \(startedAt.formatted(date: .abbreviated, time: .shortened))"
        modelContext.insert(
            AmbientRecordingModel(
                title: title,
                category: preferredCategory,
                startedAt: startedAt,
                duration: duration,
                levels: levels,
                fileURLString: fileURL.path
            )
        )
        try? modelContext.save()
        recorder.clearLastFileURL()
        recorder.clearLastLevels()
    }
}

private struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AmbientRecordingModel.startedAt, order: .reverse) private var recordings: [AmbientRecordingModel]
    @State private var searchText = ""
    @State private var category = AmbientRecordingCategory.all.rawValue
    @State private var renamingRecording: AmbientRecordingModel?
    @State private var renameText = ""
    @State private var playbackError: String?
    @State private var deletingRecording: AmbientRecordingModel?
    @State private var player: AVAudioPlayer?
    @State private var playingID: UUID?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SearchField(text: $searchText, placeholder: "搜索环境记录")

                Picker("分类", selection: $category) {
                    ForEach(AmbientRecordingCategory.allCases) { item in
                        Text(item.rawValue).tag(item.rawValue)
                    }
                }
                .pickerStyle(.segmented)

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
        .navigationTitle("收藏")
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

    private var filteredRecordings: [AmbientRecordingModel] {
        AmbientRecordingLibrary.filtered(recordings, query: searchText, category: category)
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
    let levels: [Double]
    let currentPower: Double
    let peakPower: Double
    let averagePower: Double
    @Binding var preferredCategory: String
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

            Picker("分类", selection: $preferredCategory) {
                ForEach(AmbientRecordingCategory.allCases.dropFirst()) { item in
                    Text(item.rawValue).tag(item.rawValue)
                }
            }
            .pickerStyle(.segmented)

            AudioWaveformView(levels: levels)

            HStack {
                StatusBarChip(
                    text: String(format: "%.0f dBFS", currentPower),
                    systemImage: "waveform",
                    tint: .blue
                )
                StatusBarChip(
                    text: String(format: "峰值 %.0f", peakPower),
                    systemImage: "arrow.up.right",
                    tint: .orange
                )
                StatusBarChip(
                    text: String(format: "均值 %.0f", averagePower),
                    systemImage: "chart.bar.fill",
                    tint: .green
                )
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
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(recording.title)
                        .font(.headline)
                    Spacer()
                    StatusBarChip(text: recording.category, systemImage: "tag")
                }
                Text("\(Int(recording.duration)) 秒 · \(recording.startedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                AudioWaveformView(levels: recording.levels, tint: .secondary)

                HStack {
                    StatusBarChip(
                        text: String(format: "峰值 %.0f dBFS", AudioLevelAnalyzer.peakPower(recording.levels)),
                        systemImage: "arrow.up.right",
                        tint: .orange
                    )
                    StatusBarChip(
                        text: String(format: "均值 %.0f dBFS", AudioLevelAnalyzer.averagePower(recording.levels)),
                        systemImage: "chart.bar.fill",
                        tint: .green
                    )
                }

                HStack {
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

                    ShareLink(
                        item: recording.fileURL,
                        preview: SharePreview(recording.title)
                    ) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("导出录音")

                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash")
                    }
                    .accessibilityLabel("删除录音")
                }

                if let attributes = try? FileManager.default.attributesOfItem(atPath: recording.fileURL.path) {
                    let size = attributes[.size] as? Int ?? 0
                    let modifiedAt = attributes[.modificationDate] as? Date
                    Text(
                        "\(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)) · 修改于 \(modifiedAt?.formatted(date: .abbreviated, time: .shortened) ?? "未知")"
                    )
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct SettingsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SettingSection(title: "数据与隐私") {
                    SettingRow(
                        systemImage: "iphone",
                        title: "仅本机存储",
                        detail: "录音文件和元数据保存在 App 沙盒中。"
                    )
                    SettingRow(
                        systemImage: "mic.badge.xmark",
                        title: "开始后可后台录音",
                        detail: "锁屏或切后台继续记录；不会自动开始麦克风。"
                    )
                }

                SettingSection(title: "使用建议") {
                    SettingRow(
                        systemImage: "tag",
                        title: "先选分类",
                        detail: "自然、城市、居家或夜晚，之后更容易找回。"
                    )
                }
            }
            .padding(16)
        }
        .navigationTitle("设置")
    }
}
