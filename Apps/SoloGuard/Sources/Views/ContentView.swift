import PocketCore
import PocketUI
import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CheckInPlanModel.createdAt) private var plans: [CheckInPlanModel]
    @Query private var records: [CheckInRecordModel]
    @State private var showsCreatePlan = false
    @State private var scheduler: any NotificationScheduling = SystemNotificationScheduler()
    @State private var deletingPlan: CheckInPlanModel?

    private let calculator = StreakCalculator()
    private let library = SoloGuardLibrary()

    var body: some View {
        NavigationStack {
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
                }
            }
            .sheet(isPresented: $showsCreatePlan) {
                CreatePlanSheet(scheduler: scheduler)
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
    }

    private func checkIn(_ plan: CheckInPlanModel) {
        let day = Calendar.current.startOfDay(for: Date())
        let record = records.first {
            $0.planID == plan.id && Calendar.current.isDate($0.day, inSameDayAs: day)
        }
        record?.completedAt = Date()
        try? modelContext.save()
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

private struct PlanCard: View {
    let plan: CheckInPlanModel
    let todayIsCompleted: Bool
    let yesterdayIsMissed: Bool
    let streak: Int
    let onToggle: () -> Void
    let onCheckIn: () -> Void
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
