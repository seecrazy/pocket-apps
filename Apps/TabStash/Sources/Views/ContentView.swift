import PocketUI
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var collections: [StashCollectionModel]
    @Query(sort: \StashedTabModel.lastModifiedAt, order: .reverse) private var tabs: [StashedTabModel]
    @State private var selectedCollectionID: UUID?
    @State private var filter: TabFilter = .unread
    @State private var showsImporter = false
    @State private var exportFile: ExportFile?
    @State private var syncMessage: String?
    @State private var deletingTab: StashedTabModel?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let syncMessage {
                        CardContainer {
                            Text(syncMessage)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }

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
                                    onToggleFavorite: { toggleFavorite(tab) },
                                    onDelete: { deletingTab = tab }
                                )
                            }
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle("TabStash")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showsImporter = true
                        } label: {
                            Label("导入 JSON", systemImage: "square.and.arrow.down")
                        }

                        Button {
                            exportJSON()
                        } label: {
                            Label("导出 JSON", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .fileImporter(
                isPresented: $showsImporter,
                allowedContentTypes: [.json]
            ) { result in
                importJSON(from: result)
            }
            .sheet(item: $exportFile) { file in
                ShareLink(item: file.url, preview: SharePreview("PocketTabStash.v1.json")) {
                    Text("分享导出的标签页 JSON")
                }
                .padding()
                .presentationDetents([.medium])
            }
            .confirmationDialog(
                "删除标签页？",
                isPresented: Binding(
                    get: { deletingTab != nil },
                    set: {
                        if !$0 {
                            deletingTab = nil
                        }
                    }
                ),
                titleVisibility: .visible
            ) {
                Button("删除", role: .destructive) {
                    if let tab = deletingTab {
                        modelContext.delete(tab)
                        try? modelContext.save()
                    }
                    deletingTab = nil
                }
                Button("取消", role: .cancel) {
                    deletingTab = nil
                }
            } message: {
                Text("删除本机标签页记录，不会影响浏览器插件原始数据。")
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

    private func exportJSON() {
        let document = TabStashSyncService.makeDocument(
            collections: collections,
            tabs: tabs,
            generatedAt: Date()
        )

        do {
            let data = try TabStashSyncService.encode(document)
            let url = FileManager.default.temporaryDirectory
                .appending(path: "PocketTabStash.v1-\(Int(Date().timeIntervalSince1970)).json")
            try data.write(to: url, options: .atomic)
            exportFile = ExportFile(url: url)
            syncMessage = "已生成 JSON，可以分享保存。"
        } catch {
            syncMessage = "导出失败：\(error.localizedDescription)"
        }
    }

    private func importJSON(from result: Result<URL, Error>) {
        switch result {
        case let .failure(error):
            syncMessage = "选择文件失败：\(error.localizedDescription)"
        case let .success(url):
            let secured = url.startAccessingSecurityScopedResource()
            defer {
                if secured {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            do {
                let data = try Data(contentsOf: url)
                let document = try TabStashSyncService.decode(data)
                let counts = try TabStashSyncService.importDocument(document, into: modelContext)
                syncMessage = "导入完成：新增 \(counts.insertedTabs) 条、更新 \(counts.updatedTabs) 条、跳过 \(counts.skippedInvalidURLs) 条。"
            } catch {
                syncMessage = "导入失败：\(error.localizedDescription)"
            }
        }
    }
}

private struct ExportFile: Identifiable {
    let id = UUID()
    let url: URL
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
    let onDelete: () -> Void

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
                    .accessibilityLabel(tab.isFavorite ? "取消收藏" : "收藏")
                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash")
                    }
                    .accessibilityLabel("删除标签页")
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
