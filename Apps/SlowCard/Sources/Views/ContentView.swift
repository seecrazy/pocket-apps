import PocketCore
import PocketUI
import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SlowCardModel.unlockAt) private var cards: [SlowCardModel]
    @State private var showsCompose = false
    @State private var filter: SlowCardFilter = .all
    @State private var scheduler: any NotificationScheduling = SystemNotificationScheduler()

    var body: some View {
        NavigationStack {
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
                                SlowCardView(card: card, scheduler: scheduler)
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
                }
            }
            .sheet(isPresented: $showsCompose) {
                ComposeCardSheet(scheduler: scheduler)
            }
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
                    Text("到达时间 \(card.unlockAt.formatted(date: .long, time: .omitted))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 8) {
                    Button {
                        card.isFavorite.toggle()
                        try? modelContext.save()
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
                TextField("标题", text: $title)
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
