import PocketCore
import PocketUI
import SwiftData
import SwiftUI

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selectedMood: Int?
    let recommendations: [AtEaseRecommendation]
    let hapticPlayer: any AtEaseHapticPlayer

    @Query(sort: \PracticeSessionModel.startedAt, order: .reverse) private var sessions: [PracticeSessionModel]
    @State private var showsBreath = false
    @State private var activeRecommendation: AtEaseRecommendation?
    @State private var isCollapsed = false

    private let mindfulService = MindfulMinutesService()
    private let recommendationEngine = RecommendationEngine()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AtEaseDesignTokens.sectionSpacing) {
                moodSection
                recommendationSection
                mindfulMinutesSection
            }
            .padding(.horizontal, AtEaseDesignTokens.pagePadding)
            .padding(.top, 24)
            .padding(.bottom, 48)
        }
        .background(AtEaseDesignTokens.canvas)
        .navigationTitle("心安")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("直接呼吸") {
                    showsBreath = true
                }
                .font(.subheadline)
                .foregroundStyle(AtEaseDesignTokens.textSecondary)
            }
        }
        .fullScreenCover(isPresented: $showsBreath) {
            AtEaseBreathView(pattern: .sos, practiceKind: .sos)
        }
        .fullScreenCover(item: $activeRecommendation) { recommendation in
            destination(for: recommendation)
        }
    }

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("今天感觉如何？")
                .font(.largeTitle.weight(.light))
                .foregroundStyle(AtEaseDesignTokens.textPrimary)

            HStack(spacing: 12) {
                ForEach(0 ..< 5, id: \.self) { index in
                    Circle()
                        .fill(AtEaseDesignTokens.moodColors[index])
                        .frame(width: 44, height: 44)
                        .opacity(isMoodSelected(index))
                        .scaleEffect(selectedMood == index ? 1.08 : 1)
                        .onTapGesture {
                            selectMood(index)
                        }
                        .accessibilityLabel(AtEaseDesignTokens.moodTitles[index])
                }
            }

            if selectedMood != nil {
                Text("已经记下。不需要解释。")
                    .font(.footnote)
                    .foregroundStyle(AtEaseDesignTokens.textSecondary)
            } else {
                Text("选一个，或直接开始呼吸。")
                    .font(.footnote)
                    .foregroundStyle(AtEaseDesignTokens.textSecondary)
            }
        }
    }

    private var recommendationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("可以从这里开始")
                .font(.title2.weight(.light))
                .foregroundStyle(AtEaseDesignTokens.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(recommendations) { recommendation in
                        Button {
                            activeRecommendation = recommendation
                        } label: {
                            RecommendationCard(recommendation: recommendation)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AtEaseDesignTokens.pagePadding - 20)
            }
            .padding(-4)
        }
    }

    private var mindfulMinutesSection: some View {
        CardContainer {
            HStack(alignment: .firstTextBaseline, spacing: 16) {
                Text("\(mindfulService.secondsToday(sessions: sessions) / 60)")
                    .font(.system(size: 32, weight: .light))
                    .monospacedDigit()
                    .foregroundStyle(AtEaseDesignTokens.textPrimary)

                VStack(alignment: .leading, spacing: 4) {
                    Text("今日正念分钟")
                        .font(.body)
                        .foregroundStyle(AtEaseDesignTokens.textPrimary)
                    Text("连续 \(mindfulService.consecutiveDays(sessions: sessions)) 天")
                        .font(.footnote)
                        .foregroundStyle(AtEaseDesignTokens.textSecondary)
                }

                Spacer()
            }
        }
        .background(Color.white.opacity(0.55), in: .rect(cornerRadius: 16))
    }

    private func isMoodSelected(_ index: Int) -> Double {
        if selectedMood == nil {
            return 1
        }
        return selectedMood == index ? 1 : 0.4
    }

    private func selectMood(_ index: Int) {
        hapticPlayer.phaseChange()
        selectedMood = index
        let mood = MoodCheckInModel(moodLevel: index)
        modelContext.insert(mood)
        try? modelContext.save()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.35)) {
                isCollapsed = true
            }
        }
    }

    @ViewBuilder
    private func destination(for recommendation: AtEaseRecommendation) -> some View {
        switch recommendation.kind {
        case .breath, .sos:
            AtEaseBreathView(
                pattern: recommendation.pattern ?? .relaxing,
                practiceKind: recommendation.kind,
                moodLevel: selectedMood
            )
        case .timer:
            AtEaseTimerView(minutes: recommendation.minutes, moodLevel: selectedMood)
        case .guided, .thoughtDistancing:
            AtEasePlaceholderView(title: recommendation.title, message: "这个练习正在准备中。当前版本先从呼吸开始。")
        }
    }
}

private struct RecommendationCard: View {
    let recommendation: AtEaseRecommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(recommendation.title)
                .font(.headline.weight(.medium))
                .foregroundStyle(AtEaseDesignTokens.textPrimary)
            Text(recommendation.durationLabel)
                .font(.footnote)
                .foregroundStyle(AtEaseDesignTokens.textSecondary)
            Text(recommendation.description)
                .font(.footnote)
                .foregroundStyle(AtEaseDesignTokens.textSecondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(AtEaseDesignTokens.cardPadding)
        .frame(width: UIScreen.main.bounds.width * 0.72, height: 180, alignment: .topLeading)
        .background(
            AtEaseDesignTokens.moodColors[2].opacity(0.32),
            in: .rect(cornerRadius: 16)
        )
    }
}
