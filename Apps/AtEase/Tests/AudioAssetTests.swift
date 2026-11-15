@testable import AtEase
import XCTest

final class AudioAssetTests: XCTestCase {
    func testAllAmbientSoundAssetsExist() {
        let bundle = Bundle(for: AmbientSoundMixer.self)

        for sound in AmbientSound.allCases {
            let url = AmbientSoundMixer.assetURL(for: sound, bundle: bundle)
            XCTAssertNotNil(url, "Missing ambient asset: \(sound.rawValue).m4a")
        }
    }

    func testAllMeditationMusicAssetsExist() {
        let bundle = Bundle(for: MeditationMusicMixer.self)

        for music in MeditationMusic.allCases {
            let url = MeditationMusicMixer.assetURL(for: music, bundle: bundle)
            XCTAssertNotNil(url, "Missing meditation music asset: \(music.rawValue).m4a")
        }
    }

    func testGeneratedVoiceAssetsExist() {
        let bundle = Bundle(for: AtEaseAudioGuide.self)
        let expected = [
            "voice-breath-inhale",
            "voice-breath-hold",
            "voice-breath-exhale",
            "voice-timer-start",
            "voice-timer-finish",
        ]

        for name in expected {
            let url = AtEaseVoiceLocator.url(forAsset: name, bundle: bundle)
            XCTAssertNotNil(url, "Missing generated voice asset: \(name)")
        }
    }

    func testMeditationMusicDoesNotUseAmbientSoundAssets() {
        for music in MeditationMusic.allCases {
            let url = MeditationMusicMixer.assetURL(for: music, bundle: Bundle(for: MeditationMusicMixer.self))
            XCTAssertNotNil(url)
            XCTAssertFalse(url?.path.contains("/Sounds/") == true)
        }
    }
}
