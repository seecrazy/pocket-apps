import PocketUI
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @AppStorage("tabstash.hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        TabView {
            NavigationStack {
                InboxView()
            }
            .tabItem {
                Label("收件箱", systemImage: "tray")
            }

            NavigationStack {
                SyncView()
            }
            .tabItem {
                Label("同步", systemImage: "arrow.triangle.2.circlepath")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("设置", systemImage: "gearshape")
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { !hasCompletedOnboarding },
            set: {
                if !$0 {
                    hasCompletedOnboarding = true
                }
            }
        )) {
            OnboardingPage(
                systemImage: "square.stack.3d.up",
                title: "继续阅读不丢失",
                message: "TabStash iOS 把浏览器插件保存的标签页带到手机上继续处理。",
                bullets: [
                    "使用 PocketTabStash.v1 JSON 导入导出。",
                    "数据保存在本机 SwiftData。",
                    "后续可接入 iCloud，不影响现有 schema。",
                ],
                primaryTitle: "开始使用"
            ) {
                hasCompletedOnboarding = true
            }
        }
    }
}

private struct InboxView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var collections: [StashCollectionModel]
    @Query(sort: \StashedTabModel.lastModifiedAt, order: .reverse) private var tabs: [StashedTabModel]
    @State private var selectedCollectionID: UUID?
    @State private var filter: TabFilter = .unread
    @State private var searchText = ""
    @State private var showsAddTab = false
    @State private var deletingTab: StashedTabModel?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CollectionFilterCard(
                    collections: collections,
                    selectedCollectionID: selectedCollectionID,
                    onSelect: { selectedCollectionID = $0 }
                )

                SearchField(text: $searchText, placeholder: "搜索标题或链接")

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
                        message: "导入 JSON 或手动添加一个链接，开始继续阅读。"
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
                Button {
                    showsAddTab = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("手动添加标签页")
            }
        }
        .sheet(isPresented: $showsAddTab) {
            AddTabSheet(defaultCollectionID: selectedCollectionID)
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

    private var filteredTabs: [StashedTabModel] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return tabs.filter { tab in
            let matchesCollection = selectedCollectionID == nil || tab.collectionID == selectedCollectionID
            let matchesFilter: Bool
            switch filter {
            case .unread:
                matchesFilter = !tab.isRead
            case .read:
                matchesFilter = tab.isRead
            case .favorite:
                matchesFilter = tab.isFavorite
            }
            let matchesSearch = trimmed.isEmpty
                || tab.title.localizedCaseInsensitiveContains(trimmed)
                || tab.urlString.localizedCaseInsensitiveContains(trimmed)
            return matchesCollection && matchesFilter && matchesSearch
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
}

private struct SyncView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var collections: [StashCollectionModel]
    @Query(sort: \StashedTabModel.lastModifiedAt, order: .reverse) private var tabs: [StashedTabModel]
    @State private var showsImporter = false
    @State private var exportFile: ExportFile?
    @State private var syncMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let syncMessage {
                    CardContainer {
                        Text(syncMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                CardContainer {
                    Text("数据交换")
                        .font(.headline)
                    Text("使用 PocketTabStash.v1 JSON 在浏览器插件和 iOS 之间交换数据。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack {
                        Button("导入 JSON") {
                            showsImporter = true
                        }
                        .buttonStyle(.bordered)
                        Button("导出 JSON") {
                            exportJSON()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                CollectionSummaryCard(collections: collections, tabs: tabs)
            }
            .padding(16)
        }
        .navigationTitle("同步")
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

private struct CollectionSummaryCard: View {
    let collections: [StashCollectionModel]
    let tabs: [StashedTabModel]

    var body: some View {
        CardContainer {
            Text("当前数据")
                .font(.headline)
            SettingRow(systemImage: "folder", title: "集合", detail: "\(collections.count) 个")
            SettingRow(systemImage: "link", title: "标签页", detail: "\(tabs.count) 条")
            SettingRow(
                systemImage: "checkmark.circle",
                title: "未读",
                detail: "\(tabs.filter { !$0.isRead }.count) 条"
            )
        }
    }
}

private struct SettingsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SettingSection(title: "数据与隐私") {
                    SettingRow(
                        systemImage: "iphone.and.arrow.down",
                        title: "仅本机存储",
                        detail: "标签页与集合保存在 App 沙盒中。"
                    )
                    SettingRow(
                        systemImage: "arrow.up.arrow.down",
                        title: "显式导入导出",
                        detail: "数据不会自动上传，也不会读取浏览器。"
                    )
                }

                SettingSection(title: "schema") {
                    SettingRow(
                        systemImage: "number",
                        title: "PocketTabStash.v1",
                        detail: "当前仅接受 schemaVersion = 1。"
                    )
                    SettingRow(
                        systemImage: "clock",
                        title: "合并策略",
                        detail: "按 ID 匹配，最新修改时间优先。"
                    )
                }
            }
            .padding(16)
        }
        .navigationTitle("设置")
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

private struct AddTabSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var collections: [StashCollectionModel]
    @State private var title = ""
    @State private var urlString = ""
    @State private var collectionID: UUID?
    @State private var errorMessage: String?
    let defaultCollectionID: UUID?

    var body: some View {
        NavigationStack {
            Form {
                TextField("标题", text: $title)
                TextField("https://example.com", text: $urlString)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Picker("集合", selection: Binding(
                    get: { collectionID ?? defaultCollectionID ?? collections.first?.id },
                    set: { collectionID = $0 }
                )) {
                    Text("未分组").tag(UUID?.none)
                    ForEach(collections) { collection in
                        Text(collection.name).tag(UUID?.some(collection.id))
                    }
                }
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("添加标签页")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .onAppear {
                if collectionID == nil, defaultCollectionID != nil {
                    collectionID = defaultCollectionID
                }
            }
        }
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedURL = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmedURL), url.host != nil else {
            errorMessage = "请输入可打开的完整 URL。"
            return
        }

        let finalCollectionID: UUID
        if let collectionID {
            finalCollectionID = collectionID
        } else {
            let collection = StashCollectionModel(name: "我的标签页", lastModifiedAt: Date())
            modelContext.insert(collection)
            finalCollectionID = collection.id
        }

        modelContext.insert(
            StashedTabModel(
                title: trimmedTitle.isEmpty ? url.host ?? trimmedURL : trimmedTitle,
                urlString: trimmedURL,
                collectionID: finalCollectionID,
                lastModifiedAt: Date()
            )
        )
        try? modelContext.save()
        dismiss()
    }
}
