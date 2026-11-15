import PocketCore
import PocketUI
import SwiftData
import SwiftUI

struct AtEaseRootView: View {
    @AppStorage("atease.hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("atease.hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("atease.defaultMinutes") private var defaultMinutes = 5
    @AppStorage("atease.autoPredownloadEnabled") private var autoPredownloadEnabled = false
    @State private var selectedMood: Int?
    @State private var recommendationEngine = RecommendationEngine()
    @State private var hapticPlayer: any AtEaseHapticPlayer = SystemAtEaseHapticPlayer()
    @StateObject private var subscription = AtEaseSubscriptionService()
    @StateObject private var audioDownloadManager = MeditationAudioDownloadManager(downloadService: ContentDownloadService())

    var body: some View {
        TabView {
            NavigationStack {
                TodayView(
                    selectedMood: $selectedMood,
                    recommendations: recommendationEngine.recommendations(for: selectedMood ?? 2),
                    hapticPlayer: hapticPlayer
                )
            }
            .tabItem {
                Label("今日", systemImage: "sun.min")
            }

            NavigationStack {
                PracticeView(
                    hapticsEnabled: hapticsEnabled,
                    defaultMinutes: defaultMinutes,
                    isSubscribed: subscription.isSubscribed
                )
            }
            .tabItem {
                Label("练习", systemImage: "leaf")
            }

            NavigationStack {
                AtEaseProgressView()
            }
            .tabItem {
                Label("进度", systemImage: "calendar")
            }

            NavigationStack {
                AtEaseSettingsView()
            }
            .tabItem {
                Label("设置", systemImage: "gearshape")
            }
        }
        .scrollContentBackground(.hidden)
        .background(AtEaseDesignTokens.canvas)
        .environmentObject(subscription)
        .environmentObject(audioDownloadManager)
        .task {
            await subscription.refresh()
            if autoPredownloadEnabled {
                await audioDownloadManager.predownloadUnlocked(isSubscribed: subscription.isSubscribed)
            }
        }
        .onChange(of: subscription.isSubscribed) { _, subscribed in
            if autoPredownloadEnabled {
                Task {
                    await audioDownloadManager.predownloadUnlocked(isSubscribed: subscribed)
                }
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
            AtEaseOnboardingView {
                hasCompletedOnboarding = true
            }
        }
    }
}
