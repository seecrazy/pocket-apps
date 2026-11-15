import Foundation

enum AtEaseVoiceLocator {
    static let supportedExtensions = ["mp3", "m4a", "wav"]

    static func assetName(for phase: BreathingPhase) -> String {
        switch phase {
        case .inhale: return "voice-breath-inhale"
        case .hold: return "voice-breath-hold"
        case .exhale: return "voice-breath-exhale"
        }
    }

    static func contentStepName(contentID: String, stepID: String) -> String {
        "voice-\(contentID)-\(stepID)"
    }

    static func url(forAsset name: String, bundle: Bundle = .main) -> URL? {
        let subdirectoryMatches = supportedExtensions.lazy
            .compactMap { bundle.url(forResource: name, withExtension: $0, subdirectory: "Voice") }
            .first
        if let subdirectoryMatches {
            return subdirectoryMatches
        }

        return supportedExtensions.lazy
            .compactMap { bundle.url(forResource: name, withExtension: $0) }
            .first
    }

    static func url(
        forContentID contentID: String,
        stepID: String,
        bundle: Bundle = .main
    ) -> URL? {
        url(forAsset: contentStepName(contentID: contentID, stepID: stepID), bundle: bundle)
    }
}
