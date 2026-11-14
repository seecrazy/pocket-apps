import PocketUI
import SwiftData
import SwiftUI

@main
struct SoloGuardApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [
                    CheckInPlanModel.self,
                    CheckInRecordModel.self,
                    SafetyContactModel.self,
                ])
        }
    }
}
