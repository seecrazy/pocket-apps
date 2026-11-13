import PocketUI
import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CheckInPlanModel.createdAt) private var plans: [CheckInPlanModel]
    @Query private var records: [CheckInRecordModel]
    @State private var showsCreatePlan = false

    private let calculator = StreakCalculator()

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
                            Image(systemName: "house.badge.shield.checkmark")
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
                                    todayIsCompleted: hasCompleted(plan: plan),
                                    streak: calculator.streak(for: plan.id, records: records, today: Date()),
                                    onCheckIn: { checkIn(plan) }
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
                CreatePlanSheet()
            }
        }
    }

    private func hasCompleted(plan: CheckInPlanModel) -> Bool {
        let day = Calendar.current.startOfDay(for: Date())
        return records.contains {
            $0.planID == plan.id
                && Calendar.current.isDate($0.day, inSameDayAs: day)
                && $0.completedAt != nil
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
}

private struct PlanCard: View {
    let plan: CheckInPlanModel
    let todayIsCompleted: Bool
    let streak: Int
    let onCheckIn: () -> Void

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
                    }
                }
                Spacer()
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
                        modelContext.insert(
                            CheckInPlanModel(
                                title: title.isEmpty ? "日常确认" : title,
                                reminderHour: components.hour ?? 9,
                                reminderMinute: components.minute ?? 0
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
