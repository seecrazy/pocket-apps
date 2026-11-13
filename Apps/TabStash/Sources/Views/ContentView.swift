import PocketUI
import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var collections: [StashCollectionModel]
    @Query(sort: \StashedTabModel.lastModifiedAt, order: .reverse) private var tabs: [StashedTabModel]
    @State private var selectedCollectionID: UUID?
    @State private var filter: TabFilter = .unread

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    CollectionFilterCard(
                        collections: collections,
                        selectedCollectionID: selectedCollectionID,
                        onSelect: { selectedCollectionID = $0 }
                    )

                    Picker("过滤", selection: $filter) {
                        ForEach(TabFilter.allCases) { item in
                            Text(item.title).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)

                    if filteredTabs.isEmpty {
                        EmptyStateView(
                            systemImage: "tray.full",
                            title: "没有可展示的标签页",
                            message: "从浏览器插件保存标签页后，这里会显示继续阅读列表。"
                        )
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredTabs) { tab in
                                StashedTabCard(
                                    tab: tab,
                                    collectionName: collectionName(for: tab.collectionID),
                                    onOpen: { open(tab) },
                                    onToggleRead: { toggleRead(tab) },
                                    onToggleFavorite: { toggleFavorite(tab) }
                                )
                            }
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle("TabStash")
            .onAppear {
                if collections.isEmpty {
                    seedSampleData()
                }
            }
        }
    }

    private var filteredTabs: [StashedTabModel] {
        tabs.filter { tab in
            let matchesCollection = selectedCollectionID == nil || tab.collectionID == selectedCollectionID
            let matchesFilter: Bool
            switch filter {
            case .unread: matchesFilter = !tab.isRead
            case .read: matchesFilter = tab.isRead
            case .favorite: matchesFilter = tab.isFavorite
            }
            return matchesCollection && matchesFilter
        }
    }

    private func collectionName(for collectionID: UUID) -> String {
        collections.first { $0.id == collectionID }?.name ?? "未分组"
    }

    private func open(_ tab: StashedTabModel) {
        guard let url = tab.url else { return }
        UIApplication.shared.open(url)
    }

    private func toggleRead(_ tab: StashedTabModel) {
        tab.isRead.toggle()
        tab.lastModifiedAt = Date()
        try? modelContext.save()
    }

    private func toggleFavorite(_ tab: StashedTabModel) {
        tab.isFavorite.toggle()
        tab.lastModifiedAt = Date()
        try? modelContext.save()
    }

    private func seedSampleData() {
        let collection = StashCollectionModel(name: "稍后阅读", lastModifiedAt: Date())
        modelContext.insert(collection)
        modelContext.insert(
            StashedTabModel(
                title: "SwiftUI 官方文档",
                urlString: "https://developer.apple.com/documentation/swiftui",
                collectionID: collection.id,
                lastModifiedAt: Date()
            )
        )
        modelContext.insert(
            StashedTabModel(
                title: "SwiftData 文档",
                urlString: "https://developer.apple.com/documentation/swiftdata",
                collectionID: collection.id,
                lastModifiedAt: Date().addingTimeInterval(-60)
            )
        )
        try? modelContext.save()
    }
}

private enum TabFilter: String, CaseIterable, Identifiable {
    case unread
    case read
    case favorite

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .unread: return "未读"
        case .read: return "已读"
        case .favorite: return "收藏"
        }
    }
}

private struct CollectionFilterCard: View {
    let collections: [StashCollectionModel]
    let selectedCollectionID: UUID?
    let onSelect: (UUID?) -> Void

    var body: some View {
        CardContainer {
            Text("集合")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button("全部") {
                        onSelect(nil)
                    }
                    .buttonStyle(.bordered)
                    .tint(selectedCollectionID == nil ? Color.accentColor : Color.secondary)

                    ForEach(collections) { collection in
                        Button(collection.name) {
                            onSelect(collection.id)
                        }
                        .buttonStyle(.bordered)
                        .tint(selectedCollectionID == collection.id ? Color.accentColor : Color.secondary)
                    }
                }
            }
        }
    }
}

private struct StashedTabCard: View {
    let tab: StashedTabModel
    let collectionName: String
    let onOpen: () -> Void
    let onToggleRead: () -> Void
    let onToggleFavorite: () -> Void

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(tab.title)
                            .font(.headline)
                        StatusBarChip(text: collectionName, systemImage: "folder")
                    }
                    Spacer()
                    Button {
                        onToggleFavorite()
                    } label: {
                        Image(systemName: tab.isFavorite ? "star.fill" : "star")
                            .foregroundStyle(.yellow)
                    }
                }

                Text(tab.urlString)
                    .font(.footnote.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack {
                    PrimaryButton("打开", systemImage: "arrow.up.forward") {
                        onOpen()
                    }
                    Button(tab.isRead ? "标记未读" : "标记已读") {
                        onToggleRead()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
}
