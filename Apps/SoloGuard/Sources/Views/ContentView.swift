import PocketCore
import PocketUI
import SwiftData
import SwiftUI

struct ContentView: View {
    @AppStorage("sologuard.hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var scheduler: any NotificationScheduling = SystemNotificationScheduler()
    @State private var haptics: any HapticPerformer = SystemHaptics()

    var body: some View {
        TabView {
            NavigationStack {
                HomeView(scheduler: scheduler, haptics: haptics)
            }
            .tabItem {
                Label("今日", systemImage: "house")
            }

            NavigationStack {
                SafetyView()
            }
            .tabItem {
                Label("守护", systemImage: "shield")
            }

            NavigationStack {
                HistoryView()
            }
            .tabItem {
                Label("历史", systemImage: "calendar")
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
                systemImage: "house.fill",
                title: "私密的日常确认",
                message: "SoloGuard 不做紧急联系人外发，也不上传你的生活状态。",
                bullets: [
                    "计划与签到只保存在这台 iPhone 上。",
                    "可以选择每日提醒，但仍可手动签到。",
                    "连续记录帮助你观察自己的日常节奏。",
                ],
                primaryTitle: "开始使用"
            ) {
                hasCompletedOnboarding = true
            }
        }
    }
}

private struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CheckInPlanModel.createdAt) private var plans: [CheckInPlanModel]
    @Query private var records: [CheckInRecordModel]
    @State private var showsCreatePlan = false
    @State private var deletingPlan: CheckInPlanModel?
    @State private var editingPlan: CheckInPlanModel?
    private let scheduler: any NotificationScheduling
    private let haptics: any HapticPerformer
    private let calculator = StreakCalculator()
    private let library = SoloGuardLibrary()

    init(scheduler: any NotificationScheduling, haptics: any HapticPerformer) {
        self.scheduler = scheduler
        self.haptics = haptics
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CardContainer {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("今日状态")
                                .font(.headline)
                            Text(plans.isEmpty ? "还没有生活确认计划" : "确认今天的正常生活")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "house.fill")
                            .font(.title)
                            .foregroundStyle(.tint)
                    }
                }

                if plans.isEmpty {
                    EmptyStateView(
                        systemImage: "calendar.badge.checkmark",
                        title: "创建第一个确认计划",
                        message: "从每天一次的简单确认开始，记录你今天一切正常。"
                    )
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(plans) { plan in
                            PlanCard(
                                plan: plan,
                                todayIsCompleted: library.isCompleted(plan: plan, records: records, day: Date()),
                                yesterdayIsMissed: library.missedPreviousDay(plan: plan, records: records, today: Date()),
                                streak: calculator.streak(for: plan.id, records: records, today: Date()),
                                onToggle: { toggle(plan) },
                                onCheckIn: { checkIn(plan) },
                                onEdit: { editingPlan = plan },
                                onDelete: { deletingPlan = plan }
                            )
                        }
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("SoloGuard")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showsCreatePlan = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("新建计划")
            }
        }
        .sheet(isPresented: $showsCreatePlan) {
            CreatePlanSheet(scheduler: scheduler)
        }
        .sheet(item: $editingPlan) { plan in
            EditPlanSheet(plan: plan, scheduler: scheduler)
        }
        .confirmationDialog(
            "删除计划？",
            isPresented: Binding(
                get: { deletingPlan != nil },
                set: {
                    if !$0 {
                        deletingPlan = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            Button("删除计划和签到记录", role: .destructive) {
                if let plan = deletingPlan {
                    delete(plan)
                }
                deletingPlan = nil
            }
            Button("取消", role: .cancel) {
                deletingPlan = nil
            }
        } message: {
            Text("该操作会同时取消本地提醒，且无法恢复。")
        }
    }

    private func checkIn(_ plan: CheckInPlanModel) {
        let day = Calendar.current.startOfDay(for: Date())
        let record = records.first {
            $0.planID == plan.id && Calendar.current.isDate($0.day, inSameDayAs: day)
        }
        record?.completedAt = Date()
        try? modelContext.save()
        haptics.perform(.success)
    }

    private func toggle(_ plan: CheckInPlanModel) {
        plan.isEnabled.toggle()
        try? modelContext.save()

        Task {
            if plan.isEnabled {
                guard await scheduler.requestAuthorization() else { return }
                try? await scheduler.scheduleDailyReminder(
                    id: SoloGuardNotifications.id(for: plan.id),
                    hour: plan.reminderHour,
                    minute: plan.reminderMinute,
                    title: "生活确认",
                    body: "确认一下今天是否正常。"
                )
            } else {
                await scheduler.cancel(ids: [SoloGuardNotifications.id(for: plan.id)])
            }
        }
    }

    private func delete(_ plan: CheckInPlanModel) {
        Task {
            await scheduler.cancel(ids: [SoloGuardNotifications.id(for: plan.id)])
        }
        let planID = plan.id
        records.filter { $0.planID == planID }.forEach(modelContext.delete)
        modelContext.delete(plan)
        try? modelContext.save()
    }
}

private struct HistoryView: View {
    @Query(sort: \CheckInRecordModel.day, order: .reverse) private var records: [CheckInRecordModel]
    @Query(sort: \CheckInPlanModel.createdAt) private var plans: [CheckInPlanModel]
    private let trendCalculator = SoloGuardTrendCalculator()

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                TrendCard(records: records, calculator: trendCalculator)

                if records.isEmpty {
                    EmptyStateView(
                        systemImage: "calendar.day.timeline.left",
                        title: "还没有签到历史",
                        message: "每次确认都会记录在这里，方便回看节奏。"
                    )
                } else {
                    ForEach(Array(records.prefix(60))) { record in
                        HistoryRow(record: record, planTitle: planTitle(for: record.planID))
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("签到历史")
    }

    private func planTitle(for planID: UUID) -> String {
        plans.first { $0.id == planID }?.title ?? "已删除计划"
    }
}

private struct HistoryRow: View {
    let record: CheckInRecordModel
    let planTitle: String

    var body: some View {
        CardContainer {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(planTitle)
                        .font(.headline)
                    Text(record.day.formatted(date: .abbreviated, time: .omitted))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                StatusBarChip(
                    text: record.completedAt == nil ? "未完成" : "已确认",
                    systemImage: record.completedAt == nil ? "xmark.circle" : "checkmark.circle.fill",
                    tint: record.completedAt == nil ? .orange : .green
                )
            }
        }
    }
}

private struct TrendCard: View {
    let records: [CheckInRecordModel]
    let calculator: SoloGuardTrendCalculator

    var body: some View {
        CardContainer {
            TrendBarChart(
                title: "最近 14 天",
                unit: "每日完成计划数",
                data: trendValues
            )
        }
    }

    private var trendValues: [TrendBarChart.TrendValue] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.calendar = Calendar.current
        formatter.dateFormat = "d"

        return calculator.dailySummaries(records: records, today: Date(), days: 14).map {
            TrendBarChart.TrendValue(label: formatter.string(from: $0.day), value: $0.completedCount)
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
                        detail: "计划与签到记录保存在 App 沙盒中。"
                    )
                    SettingRow(
                        systemImage: "eye.slash",
                        title: "不自动外发",
                        detail: "v1 不联系紧急联系人，也不上传状态。"
                    )
                }

                SettingSection(title: "使用建议") {
                    SettingRow(
                        systemImage: "bell",
                        title: "提醒不是安全承诺",
                        detail: "它只是帮助你建立确认习惯的轻量仪式。"
                    )
                    SettingRow(
                        systemImage: "calendar.badge.clock",
                        title: "观察连续记录",
                        detail: "连续计数用于理解节奏，不用于制造焦虑。"
                    )
                }
            }
            .padding(16)
        }
        .navigationTitle("设置")
    }
}

private struct PlanCard: View {
    let plan: CheckInPlanModel
    let todayIsCompleted: Bool
    let yesterdayIsMissed: Bool
    let streak: Int
    let onToggle: () -> Void
    let onCheckIn: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        CardContainer {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(plan.title)
                        .font(.headline)
                    HStack(spacing: 8) {
                        StatusBarChip(
                            text: todayIsCompleted ? "已确认" : "待确认",
                            systemImage: todayIsCompleted ? "checkmark.circle.fill" : "clock.badge.exclamationmark",
                            tint: todayIsCompleted ? .green : .orange
                        )
                        StatusBarChip(text: "连续 \(streak) 天", systemImage: "flame", tint: .red)
                        if yesterdayIsMissed {
                            StatusBarChip(text: "昨日已错过", systemImage: "exclamationmark.triangle", tint: .orange)
                        }
                    }
                }
                Spacer()
                HStack(spacing: 8) {
                    Button {
                        onToggle()
                    } label: {
                        Image(systemName: plan.isEnabled ? "bell.fill" : "bell.slash")
                            .foregroundStyle(plan.isEnabled ? Color.accentColor : Color.secondary)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel(plan.isEnabled ? "关闭提醒" : "开启提醒")

                    Button {
                        onEdit()
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("编辑计划")

                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("删除计划")
                }
            }

            if !plan.isEnabled {
                Text("提醒已关闭，仍可手动签到。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            PrimaryButton(todayIsCompleted ? "今日已确认" : "完成签到") {
                onCheckIn()
            }
            .disabled(todayIsCompleted)
        }
    }
}

private struct CreatePlanSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var reminder = Date()
    let scheduler: any NotificationScheduling

    var body: some View {
        NavigationStack {
            Form {
                TextField("计划名称", text: $title)
                DatePicker("提醒时间", selection: $reminder, displayedComponents: .hourAndMinute)
            }
            .navigationTitle("新建计划")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let components = Calendar.current.dateComponents([.hour, .minute], from: reminder)
                        let planID = UUID()
                        modelContext.insert(
                            CheckInPlanModel(
                                id: planID,
                                title: title.isEmpty ? "日常确认" : title,
                                reminderHour: components.hour ?? 9,
                                reminderMinute: components.minute ?? 0
                            )
                        )
                        dismiss()

                        Task {
                            guard await scheduler.requestAuthorization() else { return }
                            try? await scheduler.scheduleDailyReminder(
                                id: SoloGuardNotifications.id(for: planID),
                                hour: components.hour ?? 9,
                                minute: components.minute ?? 0,
                                title: "生活确认",
                                body: "确认一下今天是否正常。"
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

private struct EditPlanSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var reminder: Date
    let plan: CheckInPlanModel
    let scheduler: any NotificationScheduling

    init(plan: CheckInPlanModel, scheduler: any NotificationScheduling) {
        self.plan = plan
        self.scheduler = scheduler
        var components = DateComponents()
        components.hour = plan.reminderHour
        components.minute = plan.reminderMinute
        _title = State(initialValue: plan.title)
        _reminder = State(initialValue: Calendar.current.date(from: components) ?? Date())
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("计划名称", text: $title)
                DatePicker("提醒时间", selection: $reminder, displayedComponents: .hourAndMinute)
            }
            .navigationTitle("编辑计划")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        plan.title = trimmedTitle.isEmpty ? "日常确认" : trimmedTitle
                        let components = Calendar.current.dateComponents([.hour, .minute], from: reminder)
                        plan.reminderHour = components.hour ?? plan.reminderHour
                        plan.reminderMinute = components.minute ?? plan.reminderMinute
                        try? modelContext.save()

                        Task {
                            if plan.isEnabled {
                                guard await scheduler.requestAuthorization() else { return }
                                try? await scheduler.scheduleDailyReminder(
                                    id: SoloGuardNotifications.id(for: plan.id),
                                    hour: plan.reminderHour,
                                    minute: plan.reminderMinute,
                                    title: "生活确认",
                                    body: "确认一下今天是否正常。"
                                )
                            } else {
                                await scheduler.cancel(ids: [SoloGuardNotifications.id(for: plan.id)])
                            }
                        }
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
