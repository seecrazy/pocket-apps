import PocketUI
import SwiftUI

struct MeditationMusicCard: View {
    @ObservedObject var mixer: MeditationMusicMixer

    var body: some View {
        CardContainer {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("冥想音乐")
                        .font(.headline.weight(.medium))
                        .foregroundStyle(AtEaseDesignTokens.textPrimary)
                    Text(mixer.isPlaying ? mixer.currentTrack.title : "已关闭")
                        .font(.caption)
                        .foregroundStyle(AtEaseDesignTokens.textSecondary)
                }

                Spacer()

                Menu {
                    ForEach(MeditationMusic.allCases) { music in
                        Button(music.title) {
                            mixer.setTrack(music)
                        }
                    }
                } label: {
                    Image(systemName: "music.note.list")
                        .font(.body)
                        .foregroundStyle(AtEaseDesignTokens.textSecondary.opacity(0.7))
                }
                .accessibilityLabel("选择冥想音乐")

                Button {
                    mixer.toggle()
                } label: {
                    Image(systemName: mixer.isPlaying ? "pause.fill" : "play.fill")
                        .font(.body)
                        .foregroundStyle(AtEaseDesignTokens.textPrimary.opacity(0.75))
                        .frame(width: 34, height: 34)
                }
                .accessibilityLabel(mixer.isPlaying ? "暂停冥想音乐" : "播放冥想音乐")
            }
        }
        .background(Color.white.opacity(0.55), in: .rect(cornerRadius: 16))
    }
}
