import PocketUI
import SwiftData
import SwiftUI

@main
struct SlowCardApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: SlowCardModel.self)
        }
    }
}
