@testable import AtEase
import XCTest

@MainActor
final class MeditationAudioDownloadManagerTests: XCTestCase {
    private func tempDownloadDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: "atease-manager-\(UUID().uuidString)", directoryHint: .isDirectory)
    }

    func testReloadShowsOnlyRemoteItems() {
        let manager = MeditationAudioDownloadManager(
            downloadService: MockContentDownloadService(directory: tempDownloadDirectory()),
            manifestProvider: { makeManifest() }
        )

        manager.reload()

        XCTAssertEqual(manager.items.map(\.id), ["remote-one", "remote-two"])
        XCTAssertTrue(manager.items.allSatisfy { !$0.isDownloaded })
        XCTAssertEqual(manager.downloadedCount, 0)
        XCTAssertEqual(manager.totalBytes, 0)
    }

    func testDownloadCreatesCachedItem() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "atease-manager-\(UUID().uuidString)", directoryHint: .isDirectory)
        let downloader = MockContentDownloadService(directory: directory)
        let manager = MeditationAudioDownloadManager(
            downloadService: downloader,
            manifestProvider: { makeManifest() }
        )

        manager.reload()
        let item = try XCTUnwrap(manager.items.first { $0.id == "remote-one" })

        await manager.download(item)

        XCTAssertEqual(downloader.downloadCount, 1)
        XCTAssertEqual(manager.downloadedCount, 1)
        XCTAssertEqual(manager.itemStates["remote-one"], .downloaded)
        XCTAssertTrue(FileManager.default.fileExists(atPath: item.fileURL.path))
        XCTAssertEqual(manager.fileSizeBytes(for: "remote-one"), 1)
    }

    func testRemoveOnlyDeletesSelectedContent() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "atease-manager-\(UUID().uuidString)", directoryHint: .isDirectory)
        let downloader = MockContentDownloadService(directory: directory)
        let manager = MeditationAudioDownloadManager(
            downloadService: downloader,
            manifestProvider: { makeManifest() }
        )

        manager.reload()
        let first = try XCTUnwrap(manager.items.first { $0.id == "remote-one" })
        let second = try XCTUnwrap(manager.items.first { $0.id == "remote-two" })
        await manager.download(first)
        await manager.download(second)

        manager.remove(first)

        XCTAssertEqual(downloader.downloadCount, 2)
        XCTAssertEqual(manager.downloadedCount, 1)
        XCTAssertTrue(manager.items.contains { $0.id == "remote-one" })
        XCTAssertEqual(manager.items.first { $0.id == "remote-one" }?.isDownloaded, false)
        XCTAssertEqual(manager.items.first { $0.id == "remote-two" }?.isDownloaded, true)
        XCTAssertFalse(FileManager.default.fileExists(atPath: first.fileURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: second.fileURL.path))
    }

    func testRemoveAllDownloadsClearsEveryItem() async {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "atease-manager-\(UUID().uuidString)", directoryHint: .isDirectory)
        let downloader = MockContentDownloadService(directory: directory)
        let manager = MeditationAudioDownloadManager(
            downloadService: downloader,
            manifestProvider: { makeManifest() }
        )

        manager.reload()
        for item in manager.items {
            await manager.download(item)
        }

        manager.removeAll()

        XCTAssertEqual(downloader.downloadCount, 2)
        XCTAssertEqual(manager.downloadedCount, 0)
        XCTAssertEqual(manager.totalBytes, 0)
        XCTAssertTrue(manager.items.allSatisfy { !$0.isDownloaded })
    }

    func testDownloadFailureMarksItemAsRetryable() async throws {
        let downloader = MockContentDownloadService(directory: tempDownloadDirectory(), shouldFail: true)
        let manager = MeditationAudioDownloadManager(
            downloadService: downloader,
            manifestProvider: { makeManifest() }
        )

        manager.reload()
        let item = try XCTUnwrap(manager.items.first { $0.id == "remote-one" })
        await manager.download(item)

        XCTAssertEqual(manager.itemStates["remote-one"], .failed)
        XCTAssertEqual(manager.message, "音频暂时无法准备。")
    }
}

private func makeManifest() -> AtEaseContentManifest {
    func item(id: String, requiresSubscription: Bool) -> MeditationContentItem {
        MeditationContentItem(
            id: id,
            title: id,
            subtitle: "缓存测试",
            teacher: "At Ease",
            theme: .sleep,
            durationSeconds: 60,
            audioKind: .scripted,
            isSubscriptionRequired: requiresSubscription,
            steps: [MeditationContentStep(id: "step", title: "练习", text: "保持觉察。", durationSeconds: 60)]
        )
    }

    func remoteItem(id: String, requiresSubscription: Bool) -> MeditationContentItem {
        var remote = item(id: id, requiresSubscription: requiresSubscription)
        remote.audioKind = .remote
        remote.remoteAudio = MeditationRemoteAudio(
            url: URL(string: "https://example.com/\(id).m4a")!,
            fileExtension: "m4a"
        )
        return remote
    }

    return AtEaseContentManifest(
        schemaVersion: 2,
        items: [
            item(id: "free-scripted", requiresSubscription: false),
            remoteItem(id: "remote-one", requiresSubscription: false),
            remoteItem(id: "remote-two", requiresSubscription: true),
        ]
    )
}

extension MeditationAudioDownloadManager {
    func fileSizeBytes(for contentID: String) -> Int {
        items.first { $0.id == contentID }?.fileSizeBytes ?? 0
    }
}

extension MeditationAudioDownloadManagerTests {
    func testPredownloadSkipsLockedContentWhenNotSubscribed() async {
        let downloader = MockContentDownloadService(directory: tempDownloadDirectory())
        let manager = MeditationAudioDownloadManager(
            downloadService: downloader,
            manifestProvider: { makeManifest() }
        )

        await manager.predownloadUnlocked(isSubscribed: false)

        XCTAssertEqual(downloader.downloadCount, 1)
        XCTAssertFalse(manager.isPredownloadRunning)
        XCTAssertEqual(manager.predownloadCompletedCount, 1)
        XCTAssertEqual(manager.predownloadTotalCount, 1)
        XCTAssertEqual(manager.itemStates["remote-one"], .downloaded)
        XCTAssertNil(manager.itemStates["remote-two"])
    }

    func testPredownloadDownloadsAccessibleSubscriptionContent() async {
        let downloader = MockContentDownloadService(directory: tempDownloadDirectory())
        let manager = MeditationAudioDownloadManager(
            downloadService: downloader,
            manifestProvider: { makeManifest() }
        )

        await manager.predownloadUnlocked(isSubscribed: true)

        XCTAssertEqual(downloader.downloadCount, 2)
        XCTAssertEqual(manager.predownloadCompletedCount, 2)
        XCTAssertEqual(manager.predownloadTotalCount, 2)
        XCTAssertEqual(manager.itemStates["remote-one"], .downloaded)
        XCTAssertEqual(manager.itemStates["remote-two"], .downloaded)
    }

    func testPredownloadContinuesAfterSingleFailure() async {
        let downloader = MockContentDownloadService(directory: tempDownloadDirectory(), failedContentIDs: ["remote-one"])
        let manager = MeditationAudioDownloadManager(
            downloadService: downloader,
            manifestProvider: { makeManifest() }
        )

        await manager.predownloadUnlocked(isSubscribed: true)

        XCTAssertEqual(downloader.downloadCount, 2)
        XCTAssertEqual(manager.itemStates["remote-one"], .failed)
        XCTAssertEqual(manager.itemStates["remote-two"], .downloaded)
        XCTAssertEqual(manager.predownloadCompletedCount, 2)
    }

    func testPredownloadSkipsAlreadyDownloadedContent() async throws {
        let downloader = MockContentDownloadService(directory: tempDownloadDirectory())
        let manager = MeditationAudioDownloadManager(
            downloadService: downloader,
            manifestProvider: { makeManifest() }
        )

        manager.reload()
        let first = try XCTUnwrap(manager.items.first { $0.id == "remote-one" })
        await manager.download(first)
        XCTAssertEqual(downloader.downloadCount, 1)

        await manager.predownloadUnlocked(isSubscribed: false)

        XCTAssertEqual(downloader.downloadCount, 1)
        XCTAssertEqual(manager.predownloadCompletedCount, 0)
        XCTAssertEqual(manager.predownloadTotalCount, 0)
        XCTAssertFalse(manager.isPredownloadRunning)
    }

    func testCancelledPredownloadDoesNotStartNextDownload() async throws {
        let downloader = MockContentDownloadService(
            directory: tempDownloadDirectory(),
            downloadDelayNanoseconds: 30_000_000
        )
        let manager = MeditationAudioDownloadManager(
            downloadService: downloader,
            manifestProvider: { makeManifest() }
        )

        manager.reload()

        let task = Task {
            await manager.predownloadUnlocked(isSubscribed: true)
        }

        try await Task.sleep(nanoseconds: 5_000_000)
        manager.cancelPredownload()
        await task.value

        XCTAssertEqual(downloader.downloadCount, 1)
        XCTAssertEqual(manager.itemStates["remote-one"], .downloaded)
        XCTAssertNil(manager.itemStates["remote-two"])
        XCTAssertFalse(manager.isPredownloadRunning)
        XCTAssertEqual(manager.predownloadCompletedCount, 1)
        XCTAssertEqual(manager.predownloadTotalCount, 2)
    }

    func testDownloadStateOnlyAppliesToRemoteContent() {
        let manager = MeditationAudioDownloadManager(
            downloadService: MockContentDownloadService(directory: tempDownloadDirectory()),
            manifestProvider: { makeManifest() }
        )

        let scripted = MeditationContentItem(
            id: "free-scripted",
            title: "Scripted",
            subtitle: "",
            teacher: "",
            theme: .reset,
            durationSeconds: 60,
            audioKind: .scripted,
            isSubscriptionRequired: false,
            steps: [MeditationContentStep(id: "step", title: "练习", text: "保持觉察。", durationSeconds: 60)]
        )

        manager.reload()

        XCTAssertNil(manager.state(for: scripted))
        XCTAssertFalse(manager.isDownloaded(for: scripted))
    }
}
