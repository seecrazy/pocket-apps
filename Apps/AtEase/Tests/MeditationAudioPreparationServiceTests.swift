@testable import AtEase
import XCTest

@MainActor
final class MeditationAudioPreparationServiceTests: XCTestCase {
    func testScriptedContentIsReadyWithoutDownload() async {
        let downloader = MockContentDownloadService()
        let service = MeditationAudioPreparationService(
            downloadService: downloader,
            playback: MockAudioPlayer()
        )

        await service.prepare(for: makeItem(audioKind: .scripted))

        XCTAssertEqual(service.state, .ready)
        XCTAssertNil(service.localURL)
        XCTAssertEqual(downloader.downloadCount, 0)
    }

    func testRemoteContentDownloadsWhenMissing() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "atease-audio-\(UUID().uuidString)", directoryHint: .isDirectory)
        let downloader = MockContentDownloadService(directory: directory)
        let service = MeditationAudioPreparationService(
            downloadService: downloader,
            playback: MockAudioPlayer()
        )

        await service.prepare(for: makeItem(audioKind: .remote))

        XCTAssertEqual(service.state, .ready)
        XCTAssertEqual(downloader.downloadCount, 1)
        XCTAssertEqual(
            service.localURL?.path,
            downloader.localFileURL(for: "remote-content", fileExtension: "m4a").path
        )
        XCTAssertTrue(try FileManager.default.fileExists(atPath: XCTUnwrap(service.localURL?.path)))
    }

    func testRemoteContentReusesExistingDownload() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "atease-audio-\(UUID().uuidString)", directoryHint: .isDirectory)
        let downloader = MockContentDownloadService(directory: directory)
        let remote = makeItem(audioKind: .remote)

        let existing = downloader.localFileURL(for: remote.id, fileExtension: "m4a")
        try FileManager.default.createDirectory(
            at: existing.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data([0x01]).write(to: existing)

        let service = MeditationAudioPreparationService(
            downloadService: downloader,
            playback: MockAudioPlayer()
        )

        await service.prepare(for: remote)

        XCTAssertEqual(service.state, .ready)
        XCTAssertEqual(downloader.downloadCount, 0)
        XCTAssertEqual(service.localURL, existing)
    }

    func testRemoteDownloadFailureShowsNeutralMessage() async {
        let downloader = MockContentDownloadService(shouldFail: true)
        let service = MeditationAudioPreparationService(
            downloadService: downloader,
            playback: MockAudioPlayer()
        )

        await service.prepare(for: makeItem(audioKind: .remote))

        XCTAssertEqual(service.state, .failed("音频暂时无法准备。"))
        XCTAssertEqual(downloader.downloadCount, 1)
    }
}

private func makeItem(audioKind: MeditationAudioKind) -> MeditationContentItem {
    MeditationContentItem(
        id: "remote-content",
        title: "Remote",
        subtitle: "",
        teacher: "",
        theme: .sleep,
        durationSeconds: 60,
        audioKind: audioKind,
        isSubscriptionRequired: false,
        steps: [MeditationContentStep(id: "step", title: "练习", text: "保持觉察。", durationSeconds: 60)],
        remoteAudio: audioKind == .remote
            ? MeditationRemoteAudio(url: URL(string: "https://example.com/audio.m4a")!, fileExtension: "m4a")
            : nil
    )
}

private final class MockAudioPlayer: MeditationAudioPlaying {
    private(set) var playCount = 0
    private(set) var stopCount = 0

    func play(url: URL) throws {
        playCount += 1
    }

    func pause() {}

    func resume() {}

    func stop() {
        stopCount += 1
    }
}
