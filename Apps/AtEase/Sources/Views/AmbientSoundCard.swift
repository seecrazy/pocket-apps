import AVFAudio
import PocketUI
import SwiftUI

struct AmbientSoundCard: View {
    @ObservedObject var mixer: AmbientSoundMixer

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("环境音")
                        .font(.headline.weight(.medium))
                        .foregroundStyle(AtEaseDesignTokens.textPrimary)
                    Spacer()
                    Text("免费 6 种")
                        .font(.caption)
                        .foregroundStyle(AtEaseDesignTokens.textSecondary)
                }

                ForEach(AmbientSound.allCases) { sound in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(sound.title)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(AtEaseDesignTokens.textPrimary)
                                Text(sound.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(AtEaseDesignTokens.textSecondary)
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { volume(for: sound) > 0 },
                                set: { enabled in
                                    mixer.setLevel(enabled ? 0.45 : 0, for: sound)
                                }
                            ))
                            .labelsHidden()
                            .tint(AtEaseDesignTokens.accentBreath)
                        }

                        Slider(value: Binding(
                            get: { volume(for: sound) },
                            set: { mixer.setLevel($0, for: sound) }
                        ), in: 0 ... 1)
                            .tint(AtEaseDesignTokens.accentBreath)
                            .disabled(volume(for: sound) <= 0)
                    }
                }
            }
        }
        .background(Color.white.opacity(0.55), in: .rect(cornerRadius: 16))
    }

    private func volume(for sound: AmbientSound) -> Double {
        switch sound {
        case .rain: return mixer.levels.rain
        case .stream: return mixer.levels.stream
        case .insects: return mixer.levels.insects
        case .ocean: return mixer.levels.ocean
        case .forest: return mixer.levels.forest
        case .wind: return mixer.levels.wind
        }
    }
}
