@testable import AtEase
import XCTest

final class ContentDownloadServiceTests: XCTestCase {
    func testLocalFileURLUsesContentDirectory() {
        let service = ContentDownloadService(directory: URL(fileURLWithPath: "/tmp/atease-downloads"))
        let url = service.localFileURL(for: "content-1", fileExtension: "m4a")

        XCTAssertTrue(url.path.hasSuffix("/content-1/audio.m4a"))
    }

    func testDownloadedFileURLReturnsNilWhenMissing() {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "atease-downloads-\(UUID().uuidString)", directoryHint: .isDirectory)
        let service = ContentDownloadService(directory: directory)

        XCTAssertNil(service.downloadedFileURL(for: "missing-content", fileExtension: "m4a"))
    }

    func testDownloadedAudioURLsReturnsEmptyWhenCacheDirectoryIsMissing() {
        let service = ContentDownloadService(
            directory: FileManager.default.temporaryDirectory
                .appending(path: "atease-cache-missing-\(UUID().uuidString)", directoryHint: .isDirectory)
        )

        XCTAssertTrue(service.downloadedAudioURLs().isEmpty)
    }

    func testFileSizeAndRemoveDownloadAffectOnlySelectedContent() throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "atease-cache-\(UUID().uuidString)", directoryHint: .isDirectory)
        let service = ContentDownloadService(directory: directory)

        try createAudioFile(service: service, contentID: "one", bytes: [1, 2, 3])
        try createAudioFile(service: service, contentID: "two", bytes: [4, 5])

        XCTAssertEqual(service.downloadedAudioURLs().count, 2)
        XCTAssertEqual(service.fileSize(at: service.localFileURL(for: "one", fileExtension: "m4a")), 3)

        try service.removeDownload(contentID: "one")

        XCTAssertFalse(FileManager.default.fileExists(atPath: service.localFileURL(for: "one", fileExtension: "m4a").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: service.localFileURL(for: "two", fileExtension: "m4a").path))
    }

    func testRemoveAllDownloadsClearsCache() throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "atease-cache-\(UUID().uuidString)", directoryHint: .isDirectory)
        let service = ContentDownloadService(directory: directory)

        try createAudioFile(service: service, contentID: "one", bytes: [1])
        try createAudioFile(service: service, contentID: "two", bytes: [2])

        try service.removeAllDownloads()

        XCTAssertTrue(service.downloadedAudioURLs().isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.path))
    }

    private func createAudioFile(
        service: ContentDownloadService,
        contentID: String,
        bytes: [UInt8]
    ) throws {
        let url = service.localFileURL(for: contentID, fileExtension: "m4a")
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data(bytes).write(to: url)
    }
}

final class MockContentDownloadService: ContentDownloadServicing {
    private let session: URLSession
    private let directory: URL
    private let shouldFail: Bool
    private let failedContentIDs: Set<String>
    private(set) var downloadCount = 0
    private let downloadDelayNanoseconds: UInt64

    init(
        session: URLSession = .shared,
        directory: URL = URL(fileURLWithPath: "/tmp/atease-mock-downloads"),
        shouldFail: Bool = false,
        failedContentIDs: Set<String> = [],
        downloadDelayNanoseconds: UInt64 = 0
    ) {
        self.session = session
        self.directory = directory
        self.shouldFail = shouldFail
        self.failedContentIDs = failedContentIDs
        self.downloadDelayNanoseconds = downloadDelayNanoseconds
    }

    func localFileURL(for contentID: String, fileExtension: String) -> URL {
        directory
            .appending(path: contentID, directoryHint: .isDirectory)
            .appending(path: "audio.\(fileExtension)")
    }

    func downloadedFileURL(for contentID: String, fileExtension: String) -> URL? {
        let url = localFileURL(for: contentID, fileExtension: fileExtension)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    func downloadedAudioURLs() -> [URL] {
        guard FileManager.default.fileExists(atPath: directory.path) else { return [] }
        return (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
    }

    func fileSize(at url: URL) -> Int {
        (try? FileManager.default.attributesOfItem(atPath: url.path))?[.size] as? Int ?? 0
    }

    func removeDownload(contentID: String) throws {
        let contentDirectory = directory.appending(path: contentID, directoryHint: .isDirectory)
        guard FileManager.default.fileExists(atPath: contentDirectory.path) else { return }
        try FileManager.default.removeItem(at: contentDirectory)
    }

    func removeAllDownloads() throws {
        guard FileManager.default.fileExists(atPath: directory.path) else { return }
        try FileManager.default.removeItem(at: directory)
    }

    func download(url: URL, contentID: String, fileExtension: String) async throws -> URL {
        downloadCount += 1
        if downloadDelayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: downloadDelayNanoseconds)
        }
        guard !shouldFail, !failedContentIDs.contains(contentID) else {
            throw URLError(.notConnectedToInternet)
        }

        let destination = localFileURL(for: contentID, fileExtension: fileExtension)
        try FileManager.default.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data([0x01]).write(to: destination)
        return destination
    }
}
