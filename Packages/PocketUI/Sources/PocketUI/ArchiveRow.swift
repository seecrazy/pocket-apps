import SwiftUI

public struct ArchiveRow<Content: View>: View {
    private let title: String
    private let detail: String
    private let content: Content

    public init(title: String, detail: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.detail = detail
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body.weight(.medium))
                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            content
        }
        .padding(14)
        .background(.quaternary, in: .rect(cornerRadius: 14))
    }
}
