import ActivityKit
import SwiftUI
import WidgetKit

@main
struct AtEaseWidgetBundle: WidgetBundle {
    var body: some Widget {
        BreathActivityWidget()
    }
}

struct BreathActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BreathActivityAttributes.self) { context in
            BreathActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(context.state.phaseTitle)
                            .font(.headline.weight(.medium))
                        Text(context.attributes.patternTitle)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: Date() ... Date().addingTimeInterval(Double(context.state.remainingSeconds)), countsDown: true)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: context.state.progress)
                        .tint(Color(red: 0.659, green: 0.773, blue: 0.820))
                }
            } compactLeading: {
                Image(systemName: "leaf")
                    .foregroundStyle(Color(red: 0.659, green: 0.773, blue: 0.820))
            } compactTrailing: {
                Text(timerInterval: Date() ... Date().addingTimeInterval(Double(context.state.remainingSeconds)), countsDown: true)
                    .font(.caption2.monospacedDigit())
            } minimal: {
                Image(systemName: "leaf")
                    .foregroundStyle(Color(red: 0.659, green: 0.773, blue: 0.820))
            }
        }
    }
}

private struct BreathActivityView: View {
    let context: ActivityViewContext<BreathActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(context.state.phaseTitle)
                    .font(.headline.weight(.medium))
                Spacer()
                Text(context.attributes.patternTitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: context.state.progress)
                .tint(Color(red: 0.659, green: 0.773, blue: 0.820))

            HStack {
                Text(context.state.isPaused ? "已暂停" : "保持节奏")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(timerInterval: Date() ... Date().addingTimeInterval(Double(context.state.remainingSeconds)), countsDown: true)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
    }
}
