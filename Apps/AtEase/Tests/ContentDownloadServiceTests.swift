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
}

final class MockContentDownloadService: ContentDownloadServicing {
    private let session: URLSession
    private let directory: URL
    private let shouldFail: Bool
    private(set) var downloadCount = 0

    init(
        session: URLSession = .shared,
        directory: URL = URL(fileURLWithPath: "/tmp/atease-mock-downloads"),
        shouldFail: Bool = false
    ) {
        self.session = session
        self.directory = directory
        self.shouldFail = shouldFail
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

    func download(url: URL, contentID: String, fileExtension: String) async throws -> URL {
        downloadCount += 1
        guard !shouldFail else {
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
