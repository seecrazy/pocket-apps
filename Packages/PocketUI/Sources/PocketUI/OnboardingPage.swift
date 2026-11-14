import SwiftUI

public struct OnboardingPage: View {
    private let systemImage: String
    private let title: String
    private let message: String
    private let bullets: [String]
    private let primaryTitle: String
    private let action: () -> Void

    public init(
        systemImage: String,
        title: String,
        message: String,
        bullets: [String],
        primaryTitle: String,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.bullets = bullets
        self.primaryTitle = primaryTitle
        self.action = action
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Image(systemName: systemImage)
                    .font(.system(size: 46, weight: .medium))
                    .foregroundStyle(.tint)
                    .frame(maxWidth: .infinity, alignment: .center)

                Text(title)
                    .font(.largeTitle.weight(.bold))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)

                CardContainer {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(bullets, id: \.self) { bullet in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.tint)
                                Text(bullet)
                                    .font(.body)
                            }
                        }
                    }
                }

                PrimaryButton(primaryTitle) {
                    action()
                }
            }
            .padding(20)
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}
