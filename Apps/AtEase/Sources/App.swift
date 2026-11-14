import PocketUI
import SwiftData
import SwiftUI

@main
struct AtEaseApp: App {
    var body: some Scene {
        WindowGroup {
            AtEaseRootView()
                .modelContainer(for: [MoodCheckInModel.self, PracticeSessionModel.self, GuidedContentStateModel.self])
                .tint(AtEaseDesignTokens.accentBreath)
        }
    }
}
