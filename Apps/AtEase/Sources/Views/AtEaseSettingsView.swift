import PocketCore
import PocketUI
import SwiftData
import SwiftUI

struct AtEaseSettingsView: View {
    @AppStorage("atease.hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("atease.defaultMinutes") private var defaultMinutes = 5
    @AppStorage("atease.voiceGuidanceEnabled") private var voiceGuidanceEnabled = true
    @AppStorage("atease.autoPredownloadEnabled") private var autoPredownloadEnabled = false
    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [PracticeSessionModel]
    @EnvironmentObject private var subscription: AtEaseSubscriptionService
    @EnvironmentObject private var audioDownloadManager: MeditationAudioDownloadManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AtEaseDesignTokens.sectionSpacing) {
                practiceSection
                subscriptionSection
                privacySection
            }
            .padding(.horizontal, AtEaseDesignTokens.pagePadding)
            .padding(.top, 24)
            .padding(.bottom, 48)
        }
        .background(AtEaseDesignTokens.canvas)
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.large)
    }

    private var practiceSection: some View {
        CardContainer {
            Text("练习偏好")
                .font(.headline.weight(.medium))
                .foregroundStyle(AtEaseDesignTokens.textPrimary)

            Toggle("触觉辅助", isOn: $hapticsEnabled)
                .tint(AtEaseDesignTokens.accentBreath)
            Toggle("声音引导", isOn: $voiceGuidanceEnabled)
                .tint(AtEaseDesignTokens.accentBreath)
            Stepper(value: $defaultMinutes, in: 1 ... 60) {
                Text("默认时长 \(defaultMinutes) 分钟")
            }
        }
        .background(Color.white.opacity(0.55), in: .rect(cornerRadius: 16))
    }

    private var subscriptionSection: some View {
        CardContainer {
            Text("内容")
                .font(.headline.weight(.medium))
                .foregroundStyle(AtEaseDesignTokens.textPrimary)
            SettingRow(systemImage: "leaf", title: "当前版本", detail: "呼吸与计时器完全免费")
            NavigationLink {
                AtEaseSubscriptionView()
            } label: {
                SettingRow(
                    systemImage: "sparkles",
                    title: subscription.isSubscribed ? "订阅中" : "订阅",
                    detail: subscription.isSubscribed ? "睡眠故事与多周课程已解锁" : "睡眠故事与多周课程"
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                AtEaseAudioDownloadsView()
            } label: {
                SettingRow(
                    systemImage: "arrow.down.circle",
                    title: "离线音频",
                    detail: "查看下载状态与清理缓存"
                )
            }
            .buttonStyle(.plain)

            Toggle("自动预下载", isOn: $autoPredownloadEnabled)
                .tint(AtEaseDesignTokens.accentBreath)

            if audioDownloadManager.isPredownloadRunning {
                HStack {
                    Text("正在预下载 \(audioDownloadManager.predownloadCompletedCount) / \(audioDownloadManager.predownloadTotalCount)")
                        .font(.footnote)
                        .foregroundStyle(AtEaseDesignTokens.textSecondary)

                    Spacer()

                    Button("取消") {
                        audioDownloadManager.cancelPredownload()
                    }
                    .font(.footnote)
                    .foregroundStyle(AtEaseDesignTokens.textPrimary)
                }
            } else {
                Text("只下载当前可访问的远程音频。")
                    .font(.footnote)
                    .foregroundStyle(AtEaseDesignTokens.textSecondary)
            }
        }
        .background(Color.white.opacity(0.55), in: .rect(cornerRadius: 16))
        .onChange(of: autoPredownloadEnabled) { _, enabled in
            if enabled {
                Task {
                    await audioDownloadManager.predownloadUnlocked(isSubscribed: subscription.isSubscribed)
                }
            } else {
                audioDownloadManager.cancelPredownload()
            }
        }
    }

    private var privacySection: some View {
        CardContainer {
            Text("数据")
                .font(.headline.weight(.medium))
                .foregroundStyle(AtEaseDesignTokens.textPrimary)
            SettingRow(systemImage: "iphone.and.arrow.down", title: "仅本机存储", detail: "情绪与练习记录不上传")
            SettingRow(systemImage: "eye.slash", title: "无追踪", detail: "当前版本没有统计 SDK")
            Button("清除本地记录") {
                clearRecords()
            }
            .font(.body)
            .foregroundStyle(.red)
            .padding(.top, 4)
        }
        .background(Color.white.opacity(0.55), in: .rect(cornerRadius: 16))
    }

    private func clearRecords() {
        try? modelContext.delete(model: PracticeSessionModel.self)
        try? modelContext.delete(model: MoodCheckInModel.self)
        try? modelContext.save()
    }
}
