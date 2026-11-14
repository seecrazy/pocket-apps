import PocketCore
import PocketUI
import SwiftData
import SwiftUI

struct ContentView: View {
    @AppStorage("slowcard.hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var haptics: any HapticPerformer = SystemHaptics()

    var body: some View {
        TabView {
            NavigationStack {
                LibraryView(haptics: haptics)
            }
            .tabItem {
                Label("明信片", systemImage: "envelope")
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
                systemImage: "envelope.open.fill",
                title: "写给未来的自己",
                message: "SlowCard 不发送邮件、不分享内容，也不上传卡片。",
                bullets: [
                    "卡在解锁时间之前，内容保持隐藏。",
                    "到达日会有本地提醒。",
                    "所有明信片只保存在这台 iPhone 上。",
                ],
                primaryTitle: "开始使用"
            ) {
                hasCompletedOnboarding = true
            }
        }
    }
}

private struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SlowCardModel.unlockAt) private var cards: [SlowCardModel]
    @State private var showsCompose = false
    @State private var filter: SlowCardFilter = .all
    @State private var scheduler: any NotificationScheduling = SystemNotificationScheduler()
    private let haptics: any HapticPerformer

    init(haptics: any HapticPerformer) {
        self.haptics = haptics
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Picker("过滤", selection: $filter) {
                    ForEach(SlowCardFilter.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                .pickerStyle(.segmented)

                if filteredCards.isEmpty {
                    EmptyStateView(
                        systemImage: "envelope.open.fill",
                        title: "还没有慢递明信片",
                        message: "写一张给自己的卡片，让它在未来某一天到达。"
                    )
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredCards) { card in
                            SlowCardView(card: card, scheduler: scheduler, haptics: haptics)
                        }
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("SlowCard")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showsCompose = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .accessibilityLabel("写明信片")
            }
        }
        .sheet(isPresented: $showsCompose) {
            ComposeCardSheet(scheduler: scheduler)
        }
    }

    private var filteredCards: [SlowCardModel] {
        SlowCardLibrary.filtered(cards, by: filter)
    }
}

private struct SlowCardView: View {
    @Environment(\.modelContext) private var modelContext
    let card: SlowCardModel
    let scheduler: any NotificationScheduling
    let haptics: any HapticPerformer
    @State private var showsBody = false
    @State private var showsDeleteConfirmation = false

    var body: some View {
        CardContainer {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(card.title)
                        .font(.headline)
                    StatusBarChip(
                        text: card.status() == .received ? "已收到" : "在路上",
                        systemImage: card.status() == .received ? "envelope.open.fill" : "paperplane.fill",
                        tint: card.status() == .received ? .green : .blue
                    )
                    Text(
                        "到达时间 \(card.unlockAt.formatted(date: .long, time: .omitted)) · \(SlowCardLibrary.countdown(unlockAt: card.unlockAt).text)"
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 8) {
                    Button {
                        card.isFavorite.toggle()
                        try? modelContext.save()
                        haptics.perform(.light)
                    } label: {
                        Image(systemName: card.isFavorite ? "star.fill" : "star")
                            .foregroundStyle(.yellow)
                    }
                    .accessibilityLabel(card.isFavorite ? "取消收藏" : "收藏")
                    Button(role: .destructive) {
                        showsDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .accessibilityLabel("删除明信片")
                }
            }

            if card.status() == .received {
                PrimaryButton(showsBody ? "收起内容" : "查看内容", systemImage: "eye") {
                    showsBody.toggle()
                }
                if showsBody {
                    Text(card.body)
                        .font(.body)
                }
            } else {
                Text("已上锁，\(card.unlockAt.formatted(date: .long, time: .omitted)) 解锁。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .confirmationDialog(
            "删除明信片？",
            isPresented: $showsDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("删除", role: .destructive, action: delete)
            Button("取消", role: .cancel) {}
        } message: {
            Text("该操作会删除卡片内容并取消到达提醒，且无法恢复。")
        }
    }

    private func delete() {
        Task {
            await scheduler.cancel(ids: [SlowCardNotifications.id(for: card.id)])
        }
        modelContext.delete(card)
        try? modelContext.save()
    }
}

private struct ComposeCardSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var bodyText = ""
    @State private var selectedDays = 30
    let scheduler: any NotificationScheduling
    private let delayOptions = [7, 30, 90, 180]

    var body: some View {
        NavigationStack {
            Form {
                Section("标题") {
                    TextField("例如：给三个月后的我", text: $title)
                }
                Section("提示") {
                    ForEach(SlowCardPrompts.titles, id: \.self) { prompt in
                        Button(prompt) {
                            title = prompt
                        }
                    }
                }
                Section("想对未来的自己说") {
                    TextEditor(text: $bodyText)
                        .frame(minHeight: 160)
                }
                Section("解锁延迟") {
                    Picker("延迟", selection: $selectedDays) {
                        ForEach(delayOptions, id: \.self) { days in
                            Text("\(days) 天后").tag(days)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("写明信片")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let now = Date()
                        let cardID = UUID()
                        let unlockAt = Calendar.current.date(byAdding: .day, value: selectedDays, to: now) ?? now
                        modelContext.insert(
                            SlowCardModel(
                                id: cardID,
                                title: title.isEmpty ? "给自己的信" : title,
                                body: bodyText,
                                createdAt: now,
                                unlockAt: unlockAt
                            )
                        )
                        dismiss()

                        Task {
                            guard await scheduler.requestAuthorization() else { return }
                            try? await scheduler.scheduleAt(
                                id: SlowCardNotifications.id(for: cardID),
                                date: unlockAt,
                                title: "一张明信片到达了",
                                body: "写给自己的内容现在可以打开。"
                            )
                        }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
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
                        detail: "明信片内容保存在 App 沙盒中。"
                    )
                    SettingRow(
                        systemImage: "bell.badge",
                        title: "本地提醒",
                        detail: "到达日使用系统通知提醒你。"
                    )
                }

                SettingSection(title: "使用建议") {
                    SettingRow(
                        systemImage: "sparkles",
                        title: "写具体一点",
                        detail: "把你现在正在面对的事写清楚，未来读起来更有价值。"
                    )
                }
            }
            .padding(16)
        }
        .navigationTitle("设置")
    }
}
