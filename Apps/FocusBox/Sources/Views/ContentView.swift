import PocketUI
import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FocusSessionModel.startedAt, order: .reverse) private var sessions: [FocusSessionModel]
    @State private var selectedMinutes = 25
    @State private var activeSession: FocusSessionModel?
    @State private var remainingSeconds: Int = 0
    @State private var timer: Timer?

    private let durations = [15, 25, 45, 60]
    private let calculator = FocusStatsCalculator()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let session = activeSession {
                        ActiveSessionCard(
                            plannedMinutes: session.plannedMinutes,
                            remainingSeconds: remainingSeconds,
                            onComplete: completeSession,
                            onAbandon: abandonSession
                        )
                    } else {
                        SessionSetupCard(
                            durations: durations,
                            selectedMinutes: selectedMinutes,
                            onSelect: { selectedMinutes = $0 },
                            onStart: startSession
                        )
                    }

                    StatsCard(sessions: sessions, calculator: calculator)

                    RecentSessionsCard(sessions: Array(sessions.prefix(5)))
                }
                .padding(16)
            }
            .navigationTitle("FocusBox")
            .onDisappear {
                timer?.invalidate()
            }
        }
    }

    private func startSession() {
        let session = FocusSessionModel(startedAt: Date(), plannedMinutes: selectedMinutes)
        modelContext.insert(session)
        activeSession = session
        remainingSeconds = selectedMinutes * 60
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            } else {
                completeSession()
            }
        }
    }

    private func completeSession() {
        timer?.invalidate()
        activeSession?.completedAt = Date()
        activeSession?.status = FocusSessionStatus.completed.rawValue
        try? modelContext.save()
        activeSession = nil
    }

    private func abandonSession() {
        timer?.invalidate()
        activeSession?.completedAt = Date()
        activeSession?.status = FocusSessionStatus.abandoned.rawValue
        try? modelContext.save()
        activeSession = nil
    }
}

private struct SessionSetupCard: View {
    let durations: [Int]
    let selectedMinutes: Int
    let onSelect: (Int) -> Void
    let onStart: () -> Void

    var body: some View {
        CardContainer {
            Text("选择专注时长")
                .font(.headline)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                ForEach(durations, id: \.self) { minutes in
                    Button {
                        onSelect(minutes)
                    } label: {
                        Text("\(minutes)m")
                            .font(.subheadline.weight(.medium))
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                                selectedMinutes == minutes ? Color.accentColor.opacity(0.18) : Color.primary.opacity(0.05)
                            )
                            .foregroundStyle(selectedMinutes == minutes ? Color.accentColor : .primary)
                            .clipShape(.rect(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            PrimaryButton("开始专注", systemImage: "play.fill") {
                onStart()
            }
        }
    }
}

private struct ActiveSessionCard: View {
    let plannedMinutes: Int
    let remainingSeconds: Int
    let onComplete: () -> Void
    let onAbandon: () -> Void

    private var progress: Double {
        let total = plannedMinutes * 60
        return total == 0 ? 0 : Double(total - remainingSeconds) / Double(total)
    }

    var body: some View {
        CardContainer {
            VStack(spacing: 14) {
                Text("专注中")
                    .font(.headline)
                Text(timeString)
                    .font(.system(size: 52, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                ProgressView(value: progress)
                HStack {
                    Button("放弃", role: .destructive, action: onAbandon)
                        .buttonStyle(.bordered)
                    PrimaryButton("完成", systemImage: "checkmark") {
                        onComplete()
                    }
                }
            }
        }
    }

    private var timeString: String {
        String(format: "%02d:%02d", remainingSeconds / 60, remainingSeconds % 60)
    }
}

private struct StatsCard: View {
    let sessions: [FocusSessionModel]
    let calculator: FocusStatsCalculator

    var body: some View {
        CardContainer {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("今日专注")
                        .font(.headline)
                    Text("\(calculator.completedMinutesToday(sessions: sessions, today: Date())) 分钟")
                        .font(.title2.weight(.semibold))
                }
                Spacer()
                Image(systemName: "brain.head.profile")
                    .font(.title)
                    .foregroundStyle(.tint)
            }
        }
    }
}

private struct RecentSessionsCard: View {
    let sessions: [FocusSessionModel]

    var body: some View {
        CardContainer {
            Text("最近会话")
                .font(.headline)
            if sessions.isEmpty {
                Text("还没有专注记录")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(sessions) { session in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(session.plannedMinutes) 分钟")
                                .font(.body.weight(.medium))
                            Text(session.startedAt, style: .date)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        StatusBarChip(
                            text: session.status,
                            systemImage: session.status == "completed" ? "checkmark.circle" : "xmark.circle",
                            tint: session.status == "completed" ? .green : .red
                        )
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}
