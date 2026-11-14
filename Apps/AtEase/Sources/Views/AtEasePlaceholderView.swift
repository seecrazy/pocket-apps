import PocketUI
import SwiftUI

struct AtEasePlaceholderView: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let message: String

    var body: some View {
        ZStack {
            AtEaseDesignTokens.canvas.ignoresSafeArea()
            VStack(spacing: 20) {
                Spacer()
                Text(title)
                    .font(.largeTitle.weight(.light))
                    .foregroundStyle(AtEaseDesignTokens.textPrimary)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(AtEaseDesignTokens.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                PrimaryButton("返回") {
                    dismiss()
                }
                .padding(.horizontal, 48)
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}
