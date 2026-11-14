import PocketCore
import PocketUI
import SwiftData
import SwiftUI
import UIKit

struct SafetyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SafetyContactModel.createdAt) private var contacts: [SafetyContactModel]
    @Query(sort: \CheckInRecordModel.day, order: .reverse) private var records: [CheckInRecordModel]
    @Query(sort: \CheckInPlanModel.createdAt) private var plans: [CheckInPlanModel]
    @State private var showsAddContact = false
    @State private var deletingContact: SafetyContactModel?
    @State private var copied = false
    @State private var haptics: any HapticPerformer = SystemHaptics()
    private let calculator = StreakCalculator()
    private let library = SoloGuardLibrary()

    private var primaryContact: SafetyContactModel? {
        contacts.first { $0.isPrimary } ?? contacts.first
    }

    private var safetyStatus: SoloGuardSafetyStatus {
        let today = Date()
        let plan = plans.first
        let streak = plan.map { calculator.streak(for: $0.id, records: records, today: today) } ?? 0
        let needsAttention = plan.map { library.missedPreviousDay(plan: $0, records: records, today: today) } ?? false
        return SoloGuardSafetyStatus(
            contactName: primaryContact?.name,
            planTitle: plan?.title,
            lastCheckInAt: records.first { $0.completedAt != nil }?.completedAt,
            streak: streak,
            needsAttention: needsAttention,
            generatedAt: Date()
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                statusCard
                actionsCard
                contactsCard
            }
            .padding(16)
        }
        .navigationTitle("守护")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showsAddContact = true
                } label: {
                    Image(systemName: "person.badge.plus")
                }
                .accessibilityLabel("添加守护联系人")
            }
        }
        .sheet(isPresented: $showsAddContact) {
            ContactSheet()
        }
        .confirmationDialog(
            "删除守护联系人？",
            isPresented: Binding(
                get: { deletingContact != nil },
                set: {
                    if !$0 {
                        deletingContact = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            Button("删除", role: .destructive) {
                if let contact = deletingContact {
                    modelContext.delete(contact)
                    try? modelContext.save()
                }
                deletingContact = nil
            }
            Button("取消", role: .cancel) { deletingContact = nil }
        } message: {
            Text("联系人只保存在本机，删除后无法恢复。")
        }
        .alert("已复制状态", isPresented: $copied) {
            Button("好", role: .cancel) {}
        }
    }

    private var statusCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("安全状态卡")
                        .font(.headline)
                    Spacer()
                    StatusBarChip(
                        text: safetyStatus.needsAttention ? "需要查看" : "状态正常",
                        systemImage: safetyStatus.needsAttention ? "exclamationmark.triangle" : "checkmark.shield",
                        tint: safetyStatus.needsAttention ? .orange : .green
                    )
                }

                if let plan = plans.first {
                    SettingRow(systemImage: "calendar", title: plan.title, detail: "连续确认 \(safetyStatus.streak) 天")
                } else {
                    SettingRow(systemImage: "calendar.badge.exclamationmark", title: "暂无守护计划", detail: "先创建一个生活确认计划")
                }

                if let last = safetyStatus.lastCheckInAt {
                    SettingRow(
                        systemImage: "clock.badge.checkmark",
                        title: "最近确认",
                        detail: last.formatted(date: .abbreviated, time: .shortened)
                    )
                } else {
                    SettingRow(systemImage: "clock.badge.exclamationmark", title: "最近确认", detail: "暂无完成记录")
                }

                Text(SoloGuardSafetyMessage.statusText(safetyStatus))
                    .font(.footnote.monospaced())
                    .padding(12)
                    .background(.quaternary, in: .rect(cornerRadius: 12))
            }
        }
    }

    private var actionsCard: some View {
        CardContainer {
            Text("快速行动")
                .font(.headline)

            if let contact = primaryContact {
                PrimaryButton("呼叫 \(contact.name)", systemImage: "phone.fill") {
                    call(contact.phone)
                }

                Button("发送安全状态短信") {
                    send(contact)
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
            } else {
                EmptyStateView(
                    systemImage: "person.crop.circle.badge.questionmark",
                    title: "还没有守护联系人",
                    message: "添加一个本机守护联系人后，可以快速呼叫或打开短信。"
                )
            }

            ShareLink(item: SoloGuardSafetyMessage.statusText(safetyStatus)) {
                Label("分享安全状态", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.bordered)

            Button("呼叫紧急号码 110", role: .destructive) {
                call("110")
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
        }
    }

    private var contactsCard: some View {
        CardContainer {
            Text("守护联系人")
                .font(.headline)

            if contacts.isEmpty {
                Text("联系人只保存在本机，不会上传。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(contacts) { contact in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(contact.name)
                                    .font(.body.weight(.medium))
                                if contact.isPrimary {
                                    StatusBarChip(text: "主要", systemImage: "star.fill", tint: .yellow)
                                }
                            }
                            Text("\(contact.phone) · \(contact.relationship)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            call(contact.phone)
                        } label: {
                            Image(systemName: "phone.fill")
                        }
                        .buttonStyle(.bordered)
                        Button(role: .destructive) {
                            deletingContact = contact
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func call(_ phone: String) {
        guard let url = SoloGuardSafetyMessage.callURL(phone: phone) else { return }
        UIApplication.shared.open(url)
    }

    private func send(_ contact: SafetyContactModel) {
        let message = SoloGuardSafetyMessage.statusText(safetyStatus)
        guard let url = SoloGuardSafetyMessage.smsURL(phone: contact.phone, body: message) else { return }
        UIApplication.shared.open(url)
    }
}

private struct ContactSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var phone = ""
    @State private var relationship = "守护联系人"
    @State private var notes = ""
    @State private var isPrimary = false

    var body: some View {
        NavigationStack {
            Form {
                TextField("姓名", text: $name)
                TextField("电话", text: $phone)
                    .keyboardType(.phonePad)
                TextField("关系", text: $relationship)
                TextField("备注", text: $notes)
                Toggle("设为主要联系人", isOn: $isPrimary)
            }
            .navigationTitle("守护联系人")
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
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !trimmedPhone.isEmpty else { return }
        if isPrimary {
            let existing = try? modelContext.fetch(FetchDescriptor<SafetyContactModel>())
            existing?.forEach { $0.isPrimary = false }
        }
        modelContext.insert(
            SafetyContactModel(
                name: trimmedName,
                phone: trimmedPhone,
                relationship: relationship.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "守护联系人" : relationship,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes,
                isPrimary: isPrimary || (try? modelContext.fetch(FetchDescriptor<SafetyContactModel>()))?.isEmpty ?? true
            )
        )
        try? modelContext.save()
        dismiss()
    }
}
