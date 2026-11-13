import AVFAudio
import Foundation

@MainActor
final class AudioRecorderService: ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var currentFileURL: URL?
    @Published private(set) var interruptionReason: String?
    private(set) var lastFileURL: URL?
    private(set) var recordingStartedAt: Date?
    private var recorder: AVAudioRecorder?
    private var interruptionObserver: NSObjectProtocol?

    var onInterruption: ((URL, TimeInterval) -> Void)?

    init() {
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.handleInterruption(notification)
            }
        }
    }

    deinit {
        if let interruptionObserver {
            NotificationCenter.default.removeObserver(interruptionObserver)
        }
    }

    func startRecording() -> URL? {
        let session = AVAudioSession.sharedInstance()

        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
        } catch {
            errorMessage = "无法准备录音会话：\(error.localizedDescription)"
            return nil
        }

        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appending(path: "Ambient-\(Int(Date().timeIntervalSince1970)).m4a")

        do {
            recorder = try AVAudioRecorder(url: fileURL, settings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
            ])
            recorder?.record()
            isRecording = true
            currentFileURL = fileURL
            recordingStartedAt = Date()
            errorMessage = nil
            interruptionReason = nil
            return fileURL
        } catch {
            errorMessage = "无法开始录音：\(error.localizedDescription)"
            return nil
        }
    }

    func stopRecording() -> TimeInterval {
        let duration = recorder?.currentTime ?? 0
        recorder?.stop()
        recorder = nil
        isRecording = false
        lastFileURL = currentFileURL
        currentFileURL = nil
        return duration
    }

    func clearLastFileURL() {
        lastFileURL = nil
    }

    private func handleInterruption(_ notification: Notification) {
        let userInfo = notification.userInfo ?? [:]
        let typeRawValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt
        guard typeRawValue == AVAudioSession.InterruptionType.began.rawValue else { return }

        interruptionReason = Self.interruptionDescription(from: userInfo)
        guard isRecording, let fileURL = currentFileURL else { return }
        let duration = stopRecording()
        onInterruption?(fileURL, duration)
    }

    nonisolated static func interruptionDescription(from userInfo: [AnyHashable: Any]) -> String {
        let rawValue = userInfo[AVAudioSessionInterruptionReasonKey] as? UInt
        switch rawValue {
        case AVAudioSession.InterruptionReason.builtInMicMuted.rawValue:
            return "内置麦克风被系统静音，录音已停止。"
        case AVAudioSession.InterruptionReason.routeDisconnected.rawValue:
            return "音频设备断开连接，录音已停止。"
        case AVAudioSession.InterruptionReason.appWasSuspended.rawValue:
            return "App 被系统中断，录音已停止。"
        default:
            return "录音被系统中断，已保留当前文件。"
        }
    }
}
