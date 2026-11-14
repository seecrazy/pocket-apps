import PocketCore
import PocketUI
import SwiftData
import SwiftUI

struct AtEaseProgressView: View {
    @Query(sort: \PracticeSessionModel.startedAt) private var sessions: [PracticeSessionModel]
    private let mindfulService = MindfulMinutesService()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AtEaseDesignTokens.sectionSpacing) {
                weekSection
                heatmapSection
                noteSection
            }
            .padding(.horizontal, AtEaseDesignTokens.pagePadding)
            .padding(.top, 24)
            .padding(.bottom, 48)
        }
        .background(AtEaseDesignTokens.canvas)
        .navigationTitle("进度")
        .navigationBarTitleDisplayMode(.large)
    }

    private var weekSection: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 12) {
                Text("\(mindfulService.weekTotalSeconds(sessions: sessions) / 60)")
                    .font(.system(size: 32, weight: .light))
                    .monospacedDigit()
                    .foregroundStyle(AtEaseDesignTokens.textPrimary)
                Text("本周正念分钟")
                    .font(.body)
                    .foregroundStyle(AtEaseDesignTokens.textSecondary)
                Text("连续 \(mindfulService.consecutiveDays(sessions: sessions)) 天")
                    .font(.footnote)
                    .foregroundStyle(AtEaseDesignTokens.textSecondary)
            }
        }
        .background(Color.white.opacity(0.55), in: .rect(cornerRadius: 16))
    }

    private var heatmapSection: some View {
        CardContainer {
            Text("最近 35 天")
                .font(.headline.weight(.medium))
                .foregroundStyle(AtEaseDesignTokens.textPrimary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                ForEach(mindfulService.lastDays(sessions: sessions)) { summary in
                    ZStack {
                        if summary.hasPractice {
                            Circle()
                                .fill(AtEaseDesignTokens.accentBreath.opacity(opacity(for: summary.seconds)))
                        } else {
                            Circle()
                                .stroke(AtEaseDesignTokens.textSecondary.opacity(0.15), lineWidth: 1)
                        }
                    }
                    .frame(height: 32)
                    .overlay(alignment: .bottom) {
                        if calendar.isDateInToday(summary.day) {
                            Circle()
                                .fill(AtEaseDesignTokens.textPrimary.opacity(0.35))
                                .frame(width: 4, height: 4)
                                .offset(y: 9)
                        }
                    }
                }
            }
        }
        .background(Color.white.opacity(0.55), in: .rect(cornerRadius: 16))
    }

    private var noteSection: some View {
        Text("完成一分钟就会记录。断开几天也没有关系，今天重新开始也很好。")
            .font(.footnote)
            .foregroundStyle(AtEaseDesignTokens.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var calendar: Calendar {
        .current
    }

    private func opacity(for seconds: Int) -> Double {
        let minutes = seconds / 60
        switch minutes {
        case ..<1: return 0.15
        case 1 ..< 10: return 0.2
        case 10 ..< 30: return 0.6
        default: return 1
        }
    }
}
