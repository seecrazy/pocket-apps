import AVFAudio
import Foundation

enum MeditationAudioPreparationState: Equatable {
    case idle
    case preparing
    case ready
    case failed(String)
}

enum MeditationAudioError: Error, LocalizedError, Equatable {
    case contentIsNotRemote
    case remoteAudioMissing
    case downloadFailed

    var errorDescription: String? {
        switch self {
        case .contentIsNotRemote:
            return "This content does not use remote audio."
        case .remoteAudioMissing:
            return "Remote audio metadata is missing."
        case .downloadFailed:
            return "音频暂时无法准备。"
        }
    }
}

protocol MeditationAudioPlaying {
    func play(url: URL) throws
    func pause()
    func resume()
    func stop()
}

final class AVAudioPlayerAdapter: MeditationAudioPlaying {
    private var player: AVAudioPlayer?

    func play(url: URL) throws {
        let newPlayer = try AVAudioPlayer(contentsOf: url)
        newPlayer.numberOfLoops = -1
        newPlayer.prepareToPlay()
        guard newPlayer.play() else {
            throw MeditationAudioError.downloadFailed
        }
        player = newPlayer
    }

    func pause() {
        player?.pause()
    }

    func resume() {
        player?.play()
    }

    func stop() {
        player?.stop()
    }
}

@MainActor
final class MeditationAudioPreparationService: ObservableObject {
    @Published private(set) var state: MeditationAudioPreparationState = .idle
    @Published private(set) var localURL: URL?

    private let downloadService: ContentDownloadServicing
    private var playback: MeditationAudioPlaying

    init(
        downloadService: ContentDownloadServicing,
        playback: MeditationAudioPlaying = AVAudioPlayerAdapter()
    ) {
        self.downloadService = downloadService
        self.playback = playback
    }

    func prepare(for item: MeditationContentItem) async {
        switch item.audioKind {
        case .scripted, .bundled:
            state = .ready
            localURL = nil
            return
        case .remote:
            await prepareRemote(item)
        }
    }

    func pause() {
        playback.pause()
    }

    func resume() {
        playback.resume()
    }

    func stop() {
        playback.stop()
    }

    private func prepareRemote(_ item: MeditationContentItem) async {
        guard let remoteAudio = item.remoteAudio else {
            state = .failed(MeditationAudioError.remoteAudioMissing.errorDescription ?? "音频不可用。")
            return
        }

        state = .preparing
        playback.stop()

        if let existing = downloadService.downloadedFileURL(
            for: item.id,
            fileExtension: remoteAudio.fileExtension
        ) {
            localURL = existing
            startPlayback(at: existing)
            return
        }

        do {
            let downloaded = try await downloadService.download(
                url: remoteAudio.url,
                contentID: item.id,
                fileExtension: remoteAudio.fileExtension
            )
            localURL = downloaded
            startPlayback(at: downloaded)
        } catch {
            state = .failed(MeditationAudioError.downloadFailed.errorDescription ?? "音频暂时无法准备。")
        }
    }

    private func startPlayback(at url: URL) {
        do {
            try playback.play(url: url)
            state = .ready
        } catch {
            state = .failed(MeditationAudioError.downloadFailed.errorDescription ?? "音频暂时无法准备。")
        }
    }
}
