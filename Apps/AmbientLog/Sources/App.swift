import PocketUI
import SwiftData
import SwiftUI

@main
struct AmbientLogApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: AmbientRecordingModel.self)
        }
    }
}
