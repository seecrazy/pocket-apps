import PocketUI
import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SlowCardModel.unlockAt) private var cards: [SlowCardModel]
    @State private var showsCompose = false
    @State private var filter: CardFilter = .all

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Picker("过滤", selection: $filter) {
                        ForEach(CardFilter.allCases) { item in
                            Text(item.title).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)

                    if filteredCards.isEmpty {
                        EmptyStateView(
                            systemImage: "envelope.open.path",
                            title: "还没有慢递明信片",
                            message: "写一张给自己的卡片，让它在未来某一天到达。"
                        )
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredCards) { card in
                                SlowCardView(card: card)
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
                ComposeCardSheet()
            }
        }
    }

    private var filteredCards: [SlowCardModel] {
        cards.filter { card in
            switch filter {
            case .all: return true
            case .traveling: return card.status() == .traveling
            case .received: return card.status() == .received
            case .favorite: return card.isFavorite
            }
        }
    }
}

private enum CardFilter: String, CaseIterable, Identifiable {
    case all
    case traveling
    case received
    case favorite

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .all: return "全部"
        case .traveling: return "在路上"
        case .received: return "已收到"
        case .favorite: return "收藏"
        }
    }
}

private struct SlowCardView: View {
    @Environment(\.modelContext) private var modelContext
    let card: SlowCardModel
    @State private var showsBody = false

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
                Button {
                    card.isFavorite.toggle()
                    try? modelContext.save()
                } label: {
                    Image(systemName: card.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(.yellow)
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
    }
}

private struct ComposeCardSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var bodyText = ""
    @State private var selectedDays = 30

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
                        modelContext.insert(
                            SlowCardModel(
                                title: title.isEmpty ? "给自己的信" : title,
                                body: bodyText,
                                createdAt: now,
                                unlockAt: Calendar.current.date(byAdding: .day, value: selectedDays, to: now) ?? now
                            )
                        )
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}
