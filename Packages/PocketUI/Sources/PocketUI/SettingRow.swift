import SwiftUI

public struct SettingRow: View {
    private let systemImage: String
    private let title: String
    private let detail: String
    private let systemImageColor: Color

    public init(systemImage: String, title: String, detail: String, systemImageColor: Color = .accentColor) {
        self.systemImage = systemImage
        self.title = title
        self.detail = detail
        self.systemImageColor = systemImageColor
    }

    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .frame(width: 26)
                .foregroundStyle(systemImageColor)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body.weight(.medium))
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
