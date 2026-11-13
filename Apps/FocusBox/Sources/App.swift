import PocketUI
import SwiftData
import SwiftUI

@main
struct FocusBoxApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: FocusSessionModel.self)
        }
    }
}
