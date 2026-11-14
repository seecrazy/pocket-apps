import PocketUI
import SwiftUI

struct AudioLevelHelpSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    CardContainer {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("dBFS 不是普通分贝表", systemImage: "waveform.badge.exclamationmark")
                                .font(.headline)
                            Text(AudioLevelExplainer.explanation)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    CardContainer {
                        Text("常见读数示例")
                            .font(.headline)
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(AudioLevelExplainer.scale) { item in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(item.range)
                                            .font(.footnote.monospaced())
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text(item.title)
                                            .font(.body.weight(.medium))
                                    }
                                    Text(item.detail)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    Text("如果你需要 30–120 dB 的环境噪声等级，需要用声级计或对设备麦克风做校准；手机麦克风未校准时，不能直接换算。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
            }
            .navigationTitle("音量读数说明")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
