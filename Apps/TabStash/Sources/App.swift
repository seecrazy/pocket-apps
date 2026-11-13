import PocketUI
import SwiftData
import SwiftUI

@main
struct TabStashApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [StashCollectionModel.self, StashedTabModel.self])
        }
    }
}
