import AVFAudio
import PocketUI
import SwiftUI

struct AmbientSoundCard: View {
    @ObservedObject var mixer: AmbientSoundMixer
    @State private var isExpanded = false

    private var activeCount: Int {
        AmbientSound.allCases.filter { volume(for: $0) > 0 }.count
    }

    var body: some View {
        CardContainer {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("自然音")
                        .font(.headline.weight(.medium))
                        .foregroundStyle(AtEaseDesignTokens.textPrimary)

                    Text(activeCount == 0 ? "未开启" : "\(activeCount) 项")
                        .font(.caption)
                        .foregroundStyle(AtEaseDesignTokens.textSecondary)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.footnote)
                        .foregroundStyle(AtEaseDesignTokens.textSecondary.opacity(0.65))
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isExpanded ? "收起自然音" : "展开自然音")

            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
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
                .padding(.top, 16)
            }
        }
        .background(Color.white.opacity(0.55), in: .rect(cornerRadius: 16))
        .accessibilityElement(children: isExpanded ? .contain : .combine)
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
