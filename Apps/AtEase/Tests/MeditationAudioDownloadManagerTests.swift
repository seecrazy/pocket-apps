@testable import AtEase
import XCTest

@MainActor
final class MeditationAudioDownloadManagerTests: XCTestCase {
    func testReloadShowsOnlyRemoteItems() {
        let manager = MeditationAudioDownloadManager(
            downloadService: MockContentDownloadService(),
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
        let downloader = MockContentDownloadService(shouldFail: true)
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
