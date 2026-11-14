import SwiftUI

public struct TrendBarChart: View {
    private let title: String
    private let unit: String
    private let data: [TrendValue]

    public struct TrendValue: Identifiable {
        public let label: String
        public let value: Int
        public let id = UUID()

        public init(label: String, value: Int) {
            self.label = label
            self.value = value
        }
    }

    public init(title: String, unit: String, data: [TrendValue]) {
        self.title = title
        self.unit = unit
        self.data = data
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline)
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(data) { item in
                    VStack(spacing: 6) {
                        Text("\(item.value)")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.accentColor.opacity(item.value == maxValue && maxValue > 0 ? 0.85 : 0.32))
                            .frame(height: max(4, CGFloat(item.value) / max(CGFloat(maxValue), 1) * 76))
                        Text(item.label)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 118)
            Text(unit)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var maxValue: Int {
        data.map(\.value).max() ?? 0
    }
}

public struct ProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let title: String
    let detail: String

    public init(progress: Double, lineWidth: CGFloat = 14, title: String, detail: String) {
        self.progress = min(max(progress, 0), 1)
        self.lineWidth = lineWidth
        self.title = title
        self.detail = detail
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(Color.accentColor.opacity(0.18), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 4) {
                Text(title)
                    .font(.title.weight(.semibold))
                    .monospacedDigit()
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
