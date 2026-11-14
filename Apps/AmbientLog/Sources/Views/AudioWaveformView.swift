import SwiftUI

struct AudioWaveformView: View {
    let levels: [Double]
    var tint: Color = .accentColor

    var body: some View {
        let normalized = AudioLevelAnalyzer.downsample(levels, maximumPoints: 120).map {
            AudioLevelAnalyzer.normalizePower($0)
        }

        VStack(alignment: .leading, spacing: 8) {
            if normalized.isEmpty {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.primary.opacity(0.06))
                    .frame(height: 64)
                    .overlay {
                        Text("尚无音量采样")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
            } else {
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(Array(normalized.enumerated()), id: \.offset) { _, level in
                        Capsule()
                            .fill(tint.opacity(0.7))
                            .frame(height: max(4, CGFloat(level) * 64))
                    }
                }
                .frame(height: 64, alignment: .bottom)
            }
        }
    }
}
