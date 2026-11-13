import SwiftUI

@main
struct TemplateApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.grid.2x2")
                .font(.largeTitle)
            Text("Pocket Apps Template")
                .font(.title2.weight(.semibold))
            Text("复制本目录后替换 App 名称、Bundle ID 与入口视图。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
    }
}
