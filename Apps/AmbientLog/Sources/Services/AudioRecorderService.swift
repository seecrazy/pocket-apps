import AVFAudio
import Foundation

@MainActor
final class AudioRecorderService: ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var currentFileURL: URL?
    @Published private(set) var interruptionReason: String?
    @Published private(set) var levels: [Double] = []
    @Published private(set) var currentPower: Double = AudioLevelAnalyzer.silence
    @Published private(set) var peakPower: Double = AudioLevelAnalyzer.silence
    @Published private(set) var averagePower: Double = AudioLevelAnalyzer.silence
    @Published private(set) var recordingSeconds: Int = 0
    private(set) var lastFileURL: URL?
    private(set) var lastLevels: [Double] = []
    private(set) var recordingStartedAt: Date?
    private var recorder: AVAudioRecorder?
    private var meterTimer: Timer?
    private var allLevels: [Double] = []
    private var interruptionObserver: NSObjectProtocol?

    var onInterruption: ((URL, TimeInterval, [Double]) -> Void)?

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
            try session.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth, .defaultToSpeaker])
            try session.setActive(true, options: [])
        } catch {
            errorMessage = "无法准备录音会话：\(error.localizedDescription)"
            return nil
        }

        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appending(path: "Ambient-\(Int(Date().timeIntervalSince1970)).m4a")

        do {
            let newRecorder = try AVAudioRecorder(url: fileURL, settings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
            ])
            newRecorder.isMeteringEnabled = true
            newRecorder.record()
            recorder = newRecorder
            isRecording = true
            currentFileURL = fileURL
            recordingStartedAt = Date()
            allLevels = []
            levels = []
            currentPower = AudioLevelAnalyzer.silence
            peakPower = AudioLevelAnalyzer.silence
            averagePower = AudioLevelAnalyzer.silence
            errorMessage = nil
            interruptionReason = nil
            recordingSeconds = 0
            startMetering()
            return fileURL
        } catch {
            errorMessage = "无法开始录音：\(error.localizedDescription)"
            return nil
        }
    }

    func stopRecording() -> TimeInterval {
        sampleMeter()
        let duration = recorder?.currentTime ?? 0
        recorder?.stop()
        recorder = nil
        stopMetering()
        isRecording = false
        lastFileURL = currentFileURL
        lastLevels = allLevels
        currentFileURL = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        return duration
    }

    func clearLastFileURL() {
        lastFileURL = nil
    }

    func clearLastLevels() {
        lastLevels = []
    }

    private func startMetering() {
        meterTimer?.invalidate()
        meterTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sampleMeter()
            }
        }
    }

    private func stopMetering() {
        meterTimer?.invalidate()
        meterTimer = nil
    }

    private func sampleMeter() {
        guard let recorder, recorder.isRecording, recorder.isMeteringEnabled else { return }
        recorder.updateMeters()
        let power = Double(recorder.averagePower(forChannel: 0))
        allLevels.append(power)
        recordingSeconds = Int(max(0, recorder.currentTime))
        levels = Array(allLevels.suffix(120))
        currentPower = power
        peakPower = max(peakPower, power)
        averagePower = AudioLevelAnalyzer.averagePower(allLevels)
    }

    private func handleInterruption(_ notification: Notification) {
        let userInfo = notification.userInfo ?? [:]
        let typeRawValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt
        guard typeRawValue == AVAudioSession.InterruptionType.began.rawValue else { return }

        interruptionReason = Self.interruptionDescription(from: userInfo)
        guard isRecording, let fileURL = currentFileURL else { return }
        let duration = stopRecording()
        onInterruption?(fileURL, duration, allLevels)
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
