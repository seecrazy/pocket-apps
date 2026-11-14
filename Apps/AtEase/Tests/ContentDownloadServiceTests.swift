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
