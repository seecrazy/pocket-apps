@testable import AmbientLog
import AVFAudio
import XCTest

final class AudioRecorderServiceTests: XCTestCase {
    func testInterruptionDescription() {
        XCTAssertEqual(
            AudioRecorderService.interruptionDescription(from: [
                AVAudioSessionInterruptionReasonKey: AVAudioSession.InterruptionReason.builtInMicMuted.rawValue,
            ]),
            "内置麦克风被系统静音，录音已停止。"
        )
        XCTAssertEqual(
            AudioRecorderService.interruptionDescription(from: [
                AVAudioSessionInterruptionReasonKey: AVAudioSession.InterruptionReason.routeDisconnected.rawValue,
            ]),
            "音频设备断开连接，录音已停止。"
        )
        XCTAssertEqual(
            AudioRecorderService.interruptionDescription(from: [:]),
            "录音被系统中断，已保留当前文件。"
        )
    }
}
