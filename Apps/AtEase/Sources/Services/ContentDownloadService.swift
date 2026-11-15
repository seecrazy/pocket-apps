import Foundation

enum ContentDownloadState: String, Codable {
    case notApplicable
    case notDownloaded
    case downloading
    case downloaded
    case failed
}

protocol ContentDownloadServicing {
    func localFileURL(for contentID: String, fileExtension: String) -> URL
    func downloadedFileURL(for contentID: String, fileExtension: String) -> URL?
    func downloadedAudioURLs() -> [URL]
    func fileSize(at url: URL) -> Int
    func removeDownload(contentID: String) throws
    func removeAllDownloads() throws
    func download(url: URL, contentID: String, fileExtension: String) async throws -> URL
}

struct ContentDownloadService: ContentDownloadServicing {
    private let session: URLSession
    private let directory: URL

    init(session: URLSession = .shared, directory: URL? = nil) {
        self.session = session
        if let directory {
            self.directory = directory
        } else {
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            self.directory = documents.appending(path: "Downloads", directoryHint: .isDirectory)
        }
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

        let urls = (try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )) ?? []

        return urls
            .filter { $0.lastPathComponent != ".DS_Store" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    func fileSize(at url: URL) -> Int {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        return (attributes?[.size] as? NSNumber)?.intValue ?? 0
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
        let destination = localFileURL(for: contentID, fileExtension: fileExtension)
        try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)

        let (tempURL, response) = try await session.download(from: url)
        guard let http = response as? HTTPURLResponse, 200 ..< 300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }

        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.moveItem(at: tempURL, to: destination)
        return destination
    }
}
