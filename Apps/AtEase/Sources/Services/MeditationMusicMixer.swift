import AVFAudio
import Foundation

enum MeditationMusic: String, CaseIterable, Identifiable {
    case calm = "placid-ambient"
    case warm = "spiritual-ambient"

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .calm: return "平静铺底"
        case .warm: return "温润氛围"
        }
    }

    var subtitle: String {
        switch self {
        case .calm: return "低频铺底，适合专注"
        case .warm: return "柔和氛围，适合睡前"
        }
    }

    nonisolated static func assetURL(for music: MeditationMusic, bundle: Bundle = .main) -> URL? {
        if let url = bundle.url(
            forResource: music.rawValue,
            withExtension: "m4a",
            subdirectory: "Music"
        ) {
            return url
        }
        return bundle.url(forResource: music.rawValue, withExtension: "m4a")
    }
}

@MainActor
final class MeditationMusicMixer: ObservableObject {
    @Published private(set) var isPlaying = false
    @Published var currentTrack: MeditationMusic = .calm

    private var player: AVAudioPlayer?
    private var loadedTrack: MeditationMusic?
    private let volume: Float = 0.32

    nonisolated static func assetURL(for music: MeditationMusic, bundle: Bundle = .main) -> URL? {
        MeditationMusic.assetURL(for: music, bundle: bundle)
    }

    func setTrack(_ music: MeditationMusic) {
        currentTrack = music
        start()
    }

    func toggle() {
        if isPlaying {
            stop()
        } else {
            start()
        }
    }

    func start() {
        if let player, loadedTrack == currentTrack {
            player.play()
            isPlaying = player.isPlaying
            return
        }

        stopPlayerOnly()

        guard let url = Self.assetURL(for: currentTrack) else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.duckOthers, .mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(
                true,
                options: [.notifyOthersOnDeactivation]
            )
            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.numberOfLoops = -1
            newPlayer.volume = volume
            newPlayer.prepareToPlay()
            guard newPlayer.play() else { return }
            player = newPlayer
            loadedTrack = currentTrack
            isPlaying = true
        } catch {
            player = nil
            loadedTrack = nil
            isPlaying = false
        }
    }

    func stop() {
        stopPlayerOnly()
        isPlaying = false
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: [.notifyOthersOnDeactivation]
        )
    }

    private func stopPlayerOnly() {
        player?.stop()
        player = nil
        loadedTrack = nil
    }
}
