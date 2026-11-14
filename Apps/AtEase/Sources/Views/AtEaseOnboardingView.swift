import PocketUI
import SwiftUI

struct AtEaseOnboardingView: View {
    @State private var page = 0
    @State private var preferredMoods: Set<Int> = []
    let completion: () -> Void

    var body: some View {
        ZStack {
            AtEaseDesignTokens.canvas.ignoresSafeArea()

            VStack(spacing: 32) {
                HStack {
                    Spacer()
                    Button("跳过") {
                        completion()
                    }
                    .font(.subheadline)
                    .foregroundStyle(AtEaseDesignTokens.textSecondary.opacity(0.4))
                    .padding(.trailing, 24)
                }

                TabView(selection: $page) {
                    onboardingPage(
                        title: "每天一分钟，心安一下。",
                        message: "不需要账号，不需要听讲，你可以从一个很小的动作开始。"
                    )
                    .tag(0)

                    onboardingPage(
                        title: "轻轻提醒一次",
                        message: "我们只在你选的时间提醒你，不会用连续签到催促你。当前版本暂不开启通知。"
                    )
                    .tag(1)

                    VStack(alignment: .leading, spacing: 32) {
                        VStack(spacing: 12) {
                            Text("今天更接近哪一种？")
                                .font(.largeTitle.weight(.light))
                                .foregroundStyle(AtEaseDesignTokens.textPrimary)
                            Text("选一个或几个，也可以跳过。")
                                .font(.subheadline)
                                .foregroundStyle(AtEaseDesignTokens.textSecondary)
                        }

                        HStack(spacing: 12) {
                            ForEach(0 ..< 5, id: \.self) { index in
                                VStack(spacing: 6) {
                                    Circle()
                                        .fill(AtEaseDesignTokens.moodColors[index])
                                        .frame(width: 44, height: 44)
                                        .opacity(preferredMoods.contains(index) ? 1 : 0.45)
                                        .scaleEffect(preferredMoods.contains(index) ? 1.08 : 1)
                                    Text(AtEaseDesignTokens.moodTitles[index])
                                        .font(.caption2)
                                        .foregroundStyle(
                                            preferredMoods.contains(index)
                                                ? AtEaseDesignTokens.textPrimary
                                                : AtEaseDesignTokens.textSecondary
                                        )
                                }
                                .contentShape(.rect)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                        if preferredMoods.contains(index) {
                                            preferredMoods.remove(index)
                                        } else {
                                            preferredMoods.insert(index)
                                        }
                                    }
                                }
                                .accessibilityLabel(AtEaseDesignTokens.moodTitles[index])
                            }
                        }

                        Text("从左到右：平静 → 焦躁。选当前更接近的状态。")
                            .font(.caption)
                            .foregroundStyle(AtEaseDesignTokens.textSecondary)
                    }
                    .padding(.horizontal, AtEaseDesignTokens.pagePadding)
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .scrollContentBackground(.hidden)

                HStack(spacing: 8) {
                    ForEach(0 ..< 3, id: \.self) { index in
                        Capsule()
                            .fill(index == page ? AtEaseDesignTokens.accentBreath : AtEaseDesignTokens.textSecondary.opacity(0.18))
                            .frame(width: index == page ? 24 : 8, height: 6)
                    }
                }

                PrimaryButton(page == 2 ? "开始" : "继续") {
                    if page == 2 {
                        completion()
                    } else {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            page += 1
                        }
                    }
                }
                .padding(.horizontal, AtEaseDesignTokens.pagePadding)
                .padding(.bottom, 24)
            }
        }
    }

    private func onboardingPage(title: String, message: String) -> some View {
        VStack(spacing: 24) {
            Spacer()
            BreathingCurve()
                .frame(width: 240, height: 140)
            VStack(spacing: 12) {
                Text(title)
                    .font(.largeTitle.weight(.light))
                    .foregroundStyle(AtEaseDesignTokens.textPrimary)
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(AtEaseDesignTokens.textSecondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding(.horizontal, AtEaseDesignTokens.pagePadding)
    }
}

private struct BreathingCurve: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05)) { context in
            let phase = sin(context.date.timeIntervalSinceReferenceDate * 1.2)
            Circle()
                .stroke(AtEaseDesignTokens.accentBreath, lineWidth: 1.5)
                .frame(width: 120 + phase * 28, height: 120 + phase * 28)
                .opacity(0.75)
        }
    }
}
