import PocketCore
import PocketUI
import SwiftData
import SwiftUI

struct MeditationLibrarySection: View {
    let hapticsEnabled: Bool
    let isSubscribed: Bool
    @Binding var activeItem: MeditationContentItem?
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var subscription: AtEaseSubscriptionService

    @Query(sort: \GuidedContentStateModel.lastPlayedAt, order: .reverse) private var states: [GuidedContentStateModel]
    @State private var manifest: AtEaseContentManifest?
    @State private var loadError: String?
    @State private var filter: MeditationLibraryFilter = .all
    @State private var showSubscription = false

    private let loader = MeditationContentCatalogLoader()
    private let accessService = MeditationContentAccessService()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("引导冥想")
                    .font(.title2.weight(.light))
                    .foregroundStyle(AtEaseDesignTokens.textPrimary)
                Spacer()
                Text("\(items.count) 条可用")
                    .font(.caption)
                    .foregroundStyle(AtEaseDesignTokens.textSecondary)
            }

            Picker("过滤", selection: $filter) {
                ForEach(MeditationLibraryFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .tint(AtEaseDesignTokens.accentBreath)

            if let loadError {
                CardContainer {
                    Text(loadError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
                .background(Color.white.opacity(0.35), in: .rect(cornerRadius: 16))
            } else if items.isEmpty {
                EmptyStateView(
                    systemImage: "waveform.path.ecg",
                    title: filter == .favorites ? "还没有收藏" : "内容准备中",
                    message: filter == .favorites ? "点击卡片右上角的星形即可收藏。" : "稍后再来看看。"
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(items) { item in
                        MeditationContentCard(
                            item: item,
                            isFavorite: state(for: item)?.isFavorite ?? false,
                            hasCompleted: state(for: item)?.isCompleted ?? false,
                            isLocked: !accessService.canPlay(item, isSubscribed: isSubscribed),
                            onToggleFavorite: { toggleFavorite(item) },
                            onPlay: {
                                if accessService.canPlay(item, isSubscribed: isSubscribed) {
                                    activeItem = item
                                }
                            },
                            onSubscribe: {
                                showSubscription = true
                            }
                        )
                    }
                }
            }
        }
        .onAppear {
            loadCatalog()
        }
        .sheet(isPresented: $showSubscription) {
            NavigationStack {
                AtEaseSubscriptionView()
            }
        }
        .alert(
            "内容加载失败",
            isPresented: Binding(
                get: { loadError != nil },
                set: {
                    if !$0 {
                        loadError = nil
                    }
                }
            )
        ) {
            Button("好", role: .cancel) {}
        } message: {
            Text(loadError ?? "")
        }
    }

    private var items: [MeditationContentItem] {
        guard let manifest else { return [] }
        let favoriteIDs = Set(states.filter(\.isFavorite).map(\.contentID))
        return accessService.visibleItems(
            from: manifest,
            filter: filter,
            favoriteContentIDs: favoriteIDs,
            isSubscribed: isSubscribed
        )
    }

    private func loadCatalog() {
        do {
            manifest = try loader.loadBundledCatalog()
        } catch {
            manifest = nil
            loadError = (error as? LocalizedError)?.errorDescription ?? "内容无法加载。"
        }
    }

    private func state(for item: MeditationContentItem) -> GuidedContentStateModel? {
        states.first { $0.contentID == item.id }
    }

    private func toggleFavorite(_ item: MeditationContentItem) {
        let state = ensureState(for: item)
        state.isFavorite.toggle()
        try? modelContext.save()
    }

    private func ensureState(for item: MeditationContentItem) -> GuidedContentStateModel {
        if let state = state(for: item) {
            return state
        }
        let state = GuidedContentStateModel(contentID: item.id)
        modelContext.insert(state)
        try? modelContext.save()
        return state
    }
}

struct MeditationContentCard: View {
    let item: MeditationContentItem
    let isFavorite: Bool
    let hasCompleted: Bool
    let isLocked: Bool
    let onToggleFavorite: () -> Void
    let onPlay: () -> Void
    let onSubscribe: () -> Void

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.title)
                            .font(.headline.weight(.medium))
                            .foregroundStyle(AtEaseDesignTokens.textPrimary)
                        Text(item.subtitle)
                            .font(.footnote)
                            .foregroundStyle(AtEaseDesignTokens.textSecondary)
                        HStack(spacing: 8) {
                            StatusBarChip(text: item.theme.title, systemImage: "leaf")
                            StatusBarChip(text: formatDuration(item.durationSeconds), systemImage: "clock")
                            if hasCompleted {
                                StatusBarChip(text: "已完成", systemImage: "checkmark", tint: .green)
                            }
                            if isLocked {
                                StatusBarChip(
                                    text: "订阅",
                                    systemImage: "lock",
                                    tint: AtEaseDesignTokens.textSecondary
                                )
                            }
                        }
                    }
                    Spacer()
                    Button {
                        onToggleFavorite()
                    } label: {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                            .foregroundStyle(.yellow)
                    }
                    .accessibilityLabel(isFavorite ? "取消收藏" : "收藏")
                }

                Text(item.teacher)
                    .font(.caption)
                    .foregroundStyle(AtEaseDesignTokens.textSecondary)

                if isLocked {
                    Button {
                        onSubscribe()
                    } label: {
                        HStack {
                            Image(systemName: "lock")
                            Text("订阅解锁")
                        }
                        .font(.headline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.bordered)
                    .tint(AtEaseDesignTokens.accentBreath)
                } else {
                    PrimaryButton("开始") {
                        onPlay()
                    }
                }
            }
        }
        .background(Color.white.opacity(0.55), in: .rect(cornerRadius: 16))
    }

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = Int(round(Double(seconds) / 60))
        return "\(minutes) 分钟"
    }
}
