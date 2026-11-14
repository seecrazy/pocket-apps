import PocketCore
import PocketUI
import SwiftData
import SwiftUI

struct PracticeView: View {
    let hapticsEnabled: Bool
    let defaultMinutes: Int
    @State private var activeMeditation: MeditationContentItem?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AtEaseDesignTokens.sectionSpacing) {
                breathingSection
                timerSection
                MeditationLibrarySection(hapticsEnabled: hapticsEnabled, activeItem: $activeMeditation)
                futureSection
            }
            .padding(.horizontal, AtEaseDesignTokens.pagePadding)
            .padding(.top, 24)
            .padding(.bottom, 48)
        }
        .background(AtEaseDesignTokens.canvas)
        .navigationTitle("练习")
        .fullScreenCover(item: $activeMeditation) { item in
            MeditationPlayerView(item: item)
        }
        .navigationBarTitleDisplayMode(.large)
    }

    private var breathingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("呼吸")
                .font(.title2.weight(.light))
                .foregroundStyle(AtEaseDesignTokens.textPrimary)

            ForEach(BreathingPattern.allCases) { pattern in
                NavigationLink {
                    AtEaseBreathView(pattern: pattern, practiceKind: pattern == .sos ? .sos : .breath)
                } label: {
                    CardContainer {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(pattern.title)
                                    .font(.headline.weight(.medium))
                                    .foregroundStyle(AtEaseDesignTokens.textPrimary)
                                Text(pattern.subtitle)
                                    .font(.footnote)
                                    .foregroundStyle(AtEaseDesignTokens.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.footnote)
                                .foregroundStyle(AtEaseDesignTokens.textSecondary.opacity(0.4))
                        }
                    }
                    .background(Color.white.opacity(0.55), in: .rect(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var timerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("计时器")
                .font(.title2.weight(.light))
                .foregroundStyle(AtEaseDesignTokens.textPrimary)

            NavigationLink {
                AtEaseTimerView(minutes: defaultMinutes)
            } label: {
                CardContainer {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("自由计时")
                                .font(.headline.weight(.medium))
                                .foregroundStyle(AtEaseDesignTokens.textPrimary)
                            Text("1–60 分钟，安静结束。")
                                .font(.footnote)
                                .foregroundStyle(AtEaseDesignTokens.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundStyle(AtEaseDesignTokens.textSecondary.opacity(0.4))
                    }
                }
                .background(Color.white.opacity(0.55), in: .rect(cornerRadius: 16))
            }
            .buttonStyle(.plain)
        }
    }

    private var futureSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("后续加入")
                .font(.title2.weight(.light))
                .foregroundStyle(AtEaseDesignTokens.textPrimary)

            NavigationLink {
                AtEaseThoughtDistancingView()
            } label: {
                CardContainer {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("念头放下")
                                .font(.headline.weight(.medium))
                                .foregroundStyle(AtEaseDesignTokens.textPrimary)
                            Text("把占据注意力的一句话轻轻放下。")
                                .font(.footnote)
                                .foregroundStyle(AtEaseDesignTokens.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundStyle(AtEaseDesignTokens.textSecondary.opacity(0.4))
                    }
                }
                .background(Color.white.opacity(0.55), in: .rect(cornerRadius: 16))
            }
            .buttonStyle(.plain)

            NavigationLink {
                AtEaseBodyScanView()
            } label: {
                CardContainer {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("触摸身体扫描")
                                .font(.headline.weight(.medium))
                                .foregroundStyle(AtEaseDesignTokens.textPrimary)
                            Text("沿身体轮廓移动手指，无引导语。")
                                .font(.footnote)
                                .foregroundStyle(AtEaseDesignTokens.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundStyle(AtEaseDesignTokens.textSecondary.opacity(0.4))
                    }
                }
                .background(Color.white.opacity(0.55), in: .rect(cornerRadius: 16))
            }
            .buttonStyle(.plain)

            CardContainer {
                SettingRow(systemImage: "moon.stars", title: "睡眠故事", detail: "订阅内容，暂未开放")
            }
            .background(Color.white.opacity(0.35), in: .rect(cornerRadius: 16))
        }
    }
}
