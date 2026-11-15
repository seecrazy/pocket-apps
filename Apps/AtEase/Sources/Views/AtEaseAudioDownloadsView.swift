import PocketUI
import SwiftUI

struct AtEaseAudioDownloadsView: View {
    @EnvironmentObject private var subscription: AtEaseSubscriptionService
    @EnvironmentObject private var manager: MeditationAudioDownloadManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AtEaseDesignTokens.sectionSpacing) {
                summarySection

                if let message = manager.message {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(AtEaseDesignTokens.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.35), in: .rect(cornerRadius: 16))
                }

                if manager.items.isEmpty {
                    EmptyStateView(
                        systemImage: "arrow.down.circle",
                        title: "还没有远程音频内容",
                        message: "正式音频上架后，可以在这里管理离线内容。"
                    )
                } else {
                    itemsSection
                }
            }
            .padding(.horizontal, AtEaseDesignTokens.pagePadding)
            .padding(.top, 24)
            .padding(.bottom, 48)
        }
        .background(AtEaseDesignTokens.canvas)
        .navigationTitle("离线音频")
        .navigationBarTitleDisplayMode(.large)
        .task {
            manager.reload()
        }
    }

    private var summarySection: some View {
        CardContainer {
            HStack(alignment: .firstTextBaseline) {
                Text("已缓存")
                    .font(.headline.weight(.medium))
                    .foregroundStyle(AtEaseDesignTokens.textPrimary)

                Spacer()

                Text("\(manager.downloadedCount) 条 / \(formattedTotalBytes)")
                    .font(.body)
                    .foregroundStyle(AtEaseDesignTokens.textSecondary)
            }

            Button {
                manager.removeAll()
            } label: {
                HStack {
                    Text("清理全部")
                    if manager.isLoading {
                        Spacer()
                        ProgressView()
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .font(.body)
            .foregroundStyle(AtEaseDesignTokens.textPrimary)
            .disabled(manager.downloadedCount == 0 || manager.isLoading)
            .padding(.top, 4)
            .accessibilityLabel("清理全部音频缓存")

            Text("清理只删除音频文件，不会删除练习记录。")
                .font(.footnote)
                .foregroundStyle(AtEaseDesignTokens.textSecondary)
                .padding(.top, 4)
        }
        .background(Color.white.opacity(0.55), in: .rect(cornerRadius: 16))
    }

    private var itemsSection: some View {
        LazyVStack(spacing: 12) {
            ForEach(manager.items) { item in
                AudioDownloadCard(
                    item: item,
                    state: manager.itemStates[item.id] ?? .idle,
                    isLocked: item.isSubscriptionRequired && !subscription.isSubscribed,
                    onDownload: {
                        Task {
                            await manager.download(item)
                        }
                    },
                    onRemove: {
                        manager.remove(item)
                    }
                )
            }
        }
    }

    private var formattedTotalBytes: String {
        ByteCountFormatter.string(fromByteCount: Int64(manager.totalBytes), countStyle: .file)
    }
}

private struct AudioDownloadCard: View {
    let item: AudioDownloadSummary
    let state: AudioDownloadItemState
    let isLocked: Bool
    let onDownload: () -> Void
    let onRemove: () -> Void

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.title)
                        .font(.headline.weight(.medium))
                        .foregroundStyle(AtEaseDesignTokens.textPrimary)
                    Text(item.subtitle)
                        .font(.footnote)
                        .foregroundStyle(AtEaseDesignTokens.textSecondary)
                }

                HStack {
                    if item.isDownloaded {
                        StatusBarChip(
                            text: ByteCountFormatter.string(fromByteCount: Int64(item.fileSizeBytes), countStyle: .file),
                            systemImage: "internaldrive"
                        )
                    } else {
                        StatusBarChip(text: "未下载", systemImage: "arrow.down.circle")
                    }

                    Spacer()

                    actionButton
                }
            }
        }
        .background(Color.white.opacity(0.55), in: .rect(cornerRadius: 16))
    }

    @ViewBuilder
    private var actionButton: some View {
        if isLocked {
            Button("订阅解锁") {}
                .font(.footnote)
                .foregroundStyle(AtEaseDesignTokens.textSecondary)
                .disabled(true)
                .accessibilityLabel("\(item.title)，订阅解锁")
        } else {
            switch state {
            case .idle where !item.isDownloaded, .failed:
                Button("下载") {
                    onDownload()
                }
                .font(.footnote)
                .foregroundStyle(AtEaseDesignTokens.textPrimary)
                .accessibilityLabel("\(item.title)，下载")

            case .downloading:
                HStack(spacing: 8) {
                    Text("下载中")
                        .font(.footnote)
                        .foregroundStyle(AtEaseDesignTokens.textSecondary)
                    ProgressView()
                }

            case .downloaded:
                Button("删除") {
                    onRemove()
                }
                .font(.footnote)
                .foregroundStyle(AtEaseDesignTokens.textSecondary)
                .accessibilityLabel("\(item.title)，删除")

            default:
                Button("下载") {
                    onDownload()
                }
                .font(.footnote)
                .foregroundStyle(AtEaseDesignTokens.textPrimary)
                .accessibilityLabel("\(item.title)，下载")
            }
        }
    }
}
