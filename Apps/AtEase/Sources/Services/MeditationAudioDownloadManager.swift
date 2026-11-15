import Foundation

struct AudioDownloadSummary: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let fileExtension: String
    let fileURL: URL
    let fileSizeBytes: Int
    let modifiedAt: Date?
    let isSubscriptionRequired: Bool
    let isDownloaded: Bool
}

enum AudioDownloadItemState: Equatable {
    case idle
    case downloading
    case downloaded
    case failed
}

enum AudioDownloadError: Error, LocalizedError, Equatable {
    case contentNotFound
    case notRemoteAudio
    case removeFailed

    var errorDescription: String? {
        switch self {
        case .contentNotFound:
            return "内容不存在。"
        case .notRemoteAudio:
            return "This content does not use remote audio."
        case .removeFailed:
            return "暂时无法删除。"
        }
    }
}

@MainActor
final class MeditationAudioDownloadManager: ObservableObject {
    @Published private(set) var items: [AudioDownloadSummary] = []
    @Published private(set) var itemStates: [String: AudioDownloadItemState] = [:]
    @Published private(set) var isLoading = false
    @Published private(set) var message: String?

    private let downloadService: ContentDownloadServicing
    private let manifestProvider: () throws -> AtEaseContentManifest
    private var remoteItems: [String: MeditationContentItem] = [:]

    init(
        downloadService: ContentDownloadServicing,
        manifestProvider: @escaping () throws -> AtEaseContentManifest = {
            try MeditationContentCatalogLoader().loadBundledCatalog()
        }
    ) {
        self.downloadService = downloadService
        self.manifestProvider = manifestProvider
    }

    var downloadedCount: Int {
        items.filter(\.isDownloaded).count
    }

    var totalBytes: Int {
        items
            .filter(\.isDownloaded)
            .reduce(0) { $0 + $1.fileSizeBytes }
    }

    func reload() {
        isLoading = true
        defer { isLoading = false }

        do {
            let manifest = try manifestProvider()
            let remoteItems = manifest.items.filter { $0.audioKind == .remote }
            self.remoteItems = Dictionary(
                uniqueKeysWithValues: remoteItems.map { ($0.id, $0) }
            )

            let items = remoteItems.map { item -> AudioDownloadSummary in
                let remoteAudio = item.remoteAudio
                let fileURL = downloadService.localFileURL(
                    for: item.id,
                    fileExtension: remoteAudio?.fileExtension ?? "m4a"
                )
                let isDownloaded = downloadService.downloadedFileURL(
                    for: item.id,
                    fileExtension: remoteAudio?.fileExtension ?? "m4a"
                ) != nil

                return AudioDownloadSummary(
                    id: item.id,
                    title: item.title,
                    subtitle: item.subtitle,
                    fileExtension: remoteAudio?.fileExtension ?? "m4a",
                    fileURL: fileURL,
                    fileSizeBytes: isDownloaded ? downloadService.fileSize(at: fileURL) : 0,
                    modifiedAt: isDownloaded ? fileModificationDate(at: fileURL) : nil,
                    isSubscriptionRequired: item.isSubscriptionRequired,
                    isDownloaded: isDownloaded
                )
            }

            self.items = items
            let downloadedIDs = Set(items.filter(\.isDownloaded).map(\.id))
            itemStates = itemStates.filter { key, state in
                guard downloadedIDs.contains(key) else { return false }
                return state != .downloading
            }
            message = nil
        } catch {
            items = []
            itemStates = [:]
            message = (error as? LocalizedError)?.errorDescription ?? "音频缓存无法读取。"
        }
    }

    func download(_ item: AudioDownloadSummary) async {
        guard itemStates[item.id] != .downloading else { return }

        guard let remoteItem = remoteItems[item.id],
              let remoteAudio = remoteItem.remoteAudio
        else {
            message = AudioDownloadError.contentNotFound.errorDescription
            itemStates[item.id] = .failed
            return
        }

        itemStates[item.id] = .downloading
        do {
            _ = try await downloadService.download(
                url: remoteAudio.url,
                contentID: item.id,
                fileExtension: remoteAudio.fileExtension
            )
            reload()
            itemStates[item.id] = .downloaded
        } catch {
            reload()
            itemStates[item.id] = .failed
            message = "音频暂时无法准备。"
        }
    }

    func remove(_ item: AudioDownloadSummary) {
        do {
            try downloadService.removeDownload(contentID: item.id)
            reload()
            itemStates[item.id] = .idle
            message = nil
        } catch {
            message = AudioDownloadError.removeFailed.errorDescription
        }
    }

    func removeAll() {
        do {
            try downloadService.removeAllDownloads()
            reload()
            itemStates = [:]
            message = nil
        } catch {
            message = AudioDownloadError.removeFailed.errorDescription
        }
    }

    private func fileModificationDate(at url: URL) -> Date? {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        return attributes?[.modificationDate] as? Date
    }
}
