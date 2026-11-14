import PocketCore
import PocketUI
import SwiftData
import SwiftUI

struct ContentView: View {
    @AppStorage("focusbox.hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("focusbox.defaultMinutes") private var defaultMinutes = 25
    @AppStorage("focusbox.lockMode") private var lockMode = FocusLockMode.overlay.rawValue
    @State private var haptics: any HapticPerformer = SystemHaptics()

    var body: some View {
        TabView {
            NavigationStack {
                FocusView(haptics: haptics, defaultMinutes: defaultMinutes, lockMode: lockMode)
            }
            .tabItem {
                Label("专注", systemImage: "timer")
            }

            NavigationStack {
                StatsView()
            }
            .tabItem {
                Label("统计", systemImage: "chart.bar.xaxis")
            }

            NavigationStack {
                SettingsView(defaultMinutes: $defaultMinutes, lockMode: $lockMode)
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
                systemImage: "brain.head.profile.fill",
                title: "不被打扰的一段专注",
                message: "FocusBox 不会强制锁机，也不会读取你的屏幕使用记录。",
                bullets: [
                    "专注意图帮你明确现在做什么。",
                    "切屏或锁屏后回来，倒计时按真实时间恢复。",
                    "统计只保存在这台 iPhone 上。",
                ],
                primaryTitle: "开始使用"
            ) {
                hasCompletedOnboarding = true
            }
        }
    }
}

private struct FocusView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FocusSessionModel.startedAt, order: .reverse) private var sessions: [FocusSessionModel]
    @State private var selectedMinutes = 25
    @State private var intention = ""
    @State private var activeSession: FocusSessionModel?
    @State private var remainingSeconds: Int = 0
    @State private var timer: Timer?
    private let haptics: any HapticPerformer
    private let durations = [15, 25, 45, 60]
    private let calculator = FocusStatsCalculator()

    private let lockMode: FocusLockMode

    init(haptics: any HapticPerformer, defaultMinutes: Int, lockMode: String) {
        self.haptics = haptics
        self.lockMode = FocusLockMode(rawValue: lockMode) ?? .off
        selectedMinutes = defaultMinutes
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let session = activeSession {
                    ActiveSessionCard(
                        plannedMinutes: session.plannedMinutes,
                        intention: session.intention,
                        remainingSeconds: remainingSeconds,
                        isPaused: session.status == FocusSessionStatus.paused.rawValue,
                        onComplete: completeSession,
                        onTogglePause: {
                            session.status == FocusSessionStatus.paused.rawValue ? resumeSession(session) : pauseSession(session)
                        },
                        onAbandon: abandonSession
                    )
                } else {
                    SessionSetupCard(
                        durations: durations,
                        selectedMinutes: selectedMinutes,
                        intention: $intention,
                        onSelect: { selectedMinutes = $0 },
                        onStart: startSession
                    )
                }

                StreakCard(sessions: sessions)

                TodayCard(sessions: sessions, calculator: calculator)
            }
            .padding(16)
        }
        .navigationTitle("FocusBox")
        .onAppear(perform: recoverSession)
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            refreshRemaining()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .fullScreenCover(isPresented: Binding(
            get: { activeSession != nil && lockMode == .overlay },
            set: { _ in }
        )) {
            if let session = activeSession {
                FocusLockCover(
                    plannedMinutes: session.plannedMinutes,
                    intention: session.intention,
                    remainingSeconds: remainingSeconds,
                    isPaused: session.status == FocusSessionStatus.paused.rawValue,
                    onComplete: completeSession,
                    onTogglePause: {
                        session.status == FocusSessionStatus.paused.rawValue ? resumeSession(session) : pauseSession(session)
                    },
                    onAbandon: abandonSession
                )
            }
        }
    }

    private func startSession() {
        let session = FocusSessionModel(
            startedAt: Date(),
            plannedMinutes: selectedMinutes,
            intention: intention.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : intention
        )
        modelContext.insert(session)
        activeSession = session
        remainingSeconds = FocusSessionTimeline.remainingSeconds(session: session, now: Date())
        startTimer()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            refreshRemaining()
        }
    }

    private func refreshRemaining() {
        guard let session = activeSession, session.status == FocusSessionStatus.running.rawValue else { return }
        remainingSeconds = FocusSessionTimeline.remainingSeconds(session: session, now: Date())
        if remainingSeconds == 0 {
            completeSession()
        }
    }

    private func recoverSession() {
        guard activeSession == nil else { return }
        let now = Date()
        guard let session = sessions.first(where: {
            $0.status == FocusSessionStatus.running.rawValue || $0.status == FocusSessionStatus.paused.rawValue
        }) else { return }

        switch FocusSessionRecovery.decision(session: session, now: now) {
        case let .resume(secondsLeft):
            activeSession = session
            remainingSeconds = secondsLeft
            if session.status == FocusSessionStatus.running.rawValue {
                startTimer()
            }
        case let .complete(date):
            session.completedAt = date
            session.status = FocusSessionStatus.completed.rawValue
            try? modelContext.save()
        case .none:
            break
        }
    }

    private func completeSession() {
        timer?.invalidate()
        activeSession?.completedAt = Date()
        activeSession?.status = FocusSessionStatus.completed.rawValue
        try? modelContext.save()
        activeSession = nil
        haptics.perform(.success)
    }

    private func pauseSession(_ session: FocusSessionModel) {
        timer?.invalidate()
        session.status = FocusSessionStatus.paused.rawValue
        session.pausedAt = Date()
        try? modelContext.save()
    }

    private func resumeSession(_ session: FocusSessionModel) {
        guard let pausedAt = session.pausedAt else {
            session.status = FocusSessionStatus.running.rawValue
            startTimer()
            return
        }
        session.pausedSeconds = FocusSessionPause.totalPausedSeconds(
            current: session.pausedSeconds,
            pausedAt: pausedAt,
            resumedAt: Date()
        )
        session.pausedAt = nil
        session.status = FocusSessionStatus.running.rawValue
        try? modelContext.save()
        startTimer()
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
    @Binding var intention: String
    let onSelect: (Int) -> Void
    let onStart: () -> Void

    var body: some View {
        CardContainer {
            Text("这次专注做什么？")
                .font(.headline)
            TextField("例如：整理项目大纲", text: $intention)
                .textFieldStyle(.roundedBorder)

            Text("专注时长")
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

            Stepper(value: Binding(
                get: { selectedMinutes },
                set: { onSelect($0) }
            ), in: 5 ... 180, step: 5) {
                Text("自定义 \(selectedMinutes) 分钟")
            }

            PrimaryButton("开始专注", systemImage: "play.fill") {
                onStart()
            }
        }
    }
}

struct ActiveSessionCard: View {
    let plannedMinutes: Int
    let intention: String?
    let remainingSeconds: Int
    let isPaused: Bool
    let onComplete: () -> Void
    let onTogglePause: () -> Void
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
                if isPaused {
                    StatusBarChip(text: "已暂停", systemImage: "pause.circle", tint: .orange)
                }
                if let intention {
                    Text(intention)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                Text(timeString)
                    .hidden()
                ProgressRing(
                    progress: progress,
                    title: timeString,
                    detail: "\(Int(progress * 100))%"
                )
                HStack {
                    Button(isPaused ? "继续" : "暂停") {
                        onTogglePause()
                    }
                    .buttonStyle(.bordered)
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

private struct TodayCard: View {
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

private struct StatsView: View {
    @Query(sort: \FocusSessionModel.startedAt, order: .reverse) private var sessions: [FocusSessionModel]
    private let calculator = FocusStatsCalculator()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                TrendCard(sessions: sessions, calculator: calculator)
                StreakCard(sessions: sessions)
                RecentSessionsCard(sessions: Array(sessions.prefix(12)))
            }
            .padding(16)
        }
        .navigationTitle("统计")
    }
}

private struct TrendCard: View {
    let sessions: [FocusSessionModel]
    let calculator: FocusStatsCalculator

    var body: some View {
        CardContainer {
            TrendBarChart(
                title: "最近 7 天",
                unit: "每日已完成专注分钟数",
                data: trendValues
            )
        }
    }

    private var trendValues: [TrendBarChart.TrendValue] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.calendar = Calendar.current
        formatter.dateFormat = "EEE"

        return calculator.completedMinutesForLastDays(sessions: sessions, today: Date(), days: 7).map {
            TrendBarChart.TrendValue(label: formatter.string(from: $0.day), value: $0.minutes)
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
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("\(session.plannedMinutes) 分钟")
                                .font(.body.weight(.medium))
                            Spacer()
                            StatusBarChip(
                                text: session.status,
                                systemImage: session.status == "completed" ? "checkmark.circle" : "xmark.circle",
                                tint: session.status == "completed" ? .green : .red
                            )
                        }
                        if let intention = session.intention {
                            Text(intention)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

private struct StreakCard: View {
    let sessions: [FocusSessionModel]
    private let streakCalculator = FocusStreakCalculator()

    var body: some View {
        CardContainer {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("连续专注")
                        .font(.headline)
                    Text("\(streakCalculator.streak(sessions: sessions, today: Date())) 天")
                        .font(.title2.weight(.semibold))
                }
                Spacer()
                Image(systemName: "flame")
                    .font(.title)
                    .foregroundStyle(.orange)
            }
        }
    }
}

private struct SettingsView: View {
    @Binding var defaultMinutes: Int
    @Binding var lockMode: String

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SettingSection(title: "默认设置") {
                    Stepper(value: $defaultMinutes, in: 5 ... 180, step: 5) {
                        Text("默认时长 \(defaultMinutes) 分钟")
                    }
                }

                SettingSection(title: "专注锁定") {
                    Picker("锁定模式", selection: $lockMode) {
                        ForEach(FocusLockMode.allCases) { mode in
                            Text(mode.title).tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    Text(FocusLockMode(rawValue: lockMode)?.detail ?? "")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                SettingSection(title: "行为边界") {
                    SettingRow(
                        systemImage: "lock",
                        title: "App 内遮罩",
                        detail: "系统级 Screen Time 锁机需要后续 entitlement。"
                    )
                    SettingRow(
                        systemImage: "eye.slash",
                        title: "不读取屏幕使用记录",
                        detail: "专注统计只来自 App 内会话。"
                    )
                }
            }
            .padding(16)
        }
        .navigationTitle("设置")
    }
}
