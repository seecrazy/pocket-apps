import PocketUI
import SwiftUI

struct AtEaseSubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscription: AtEaseSubscriptionService

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AtEaseDesignTokens.sectionSpacing) {
                header
                productsSection
                restoreSection

                if let message = subscription.errorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(AtEaseDesignTokens.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.35), in: .rect(cornerRadius: 16))
                }
            }
            .padding(.horizontal, AtEaseDesignTokens.pagePadding)
            .padding(.top, 24)
            .padding(.bottom, 48)
        }
        .background(AtEaseDesignTokens.canvas)
        .navigationTitle("订阅")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("完成") {
                    dismiss()
                }
                .font(.body)
                .foregroundStyle(AtEaseDesignTokens.textSecondary.opacity(0.65))
            }
        }
        .task {
            await subscription.refresh()
            await subscription.loadProducts()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(subscription.isSubscribed ? "订阅中" : "订阅内容")
                .font(.largeTitle.weight(.light))
                .foregroundStyle(AtEaseDesignTokens.textPrimary)

            Text(subscription.isSubscribed ? "睡眠故事与多周课程已解锁。你的练习记录仍然只保存在本机。" : "呼吸、计时器和 5 条基础冥想保持免费。订阅解锁后续睡眠故事与多周课程。")
                .font(.body)
                .foregroundStyle(AtEaseDesignTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var productsSection: some View {
        if subscription.products.isEmpty {
            CardContainer {
                if subscription.isLoadingProducts {
                    Text("正在读取订阅方案")
                        .font(.body)
                        .foregroundStyle(AtEaseDesignTokens.textSecondary)
                } else {
                    Text("暂时无法读取订阅方案。")
                        .font(.body)
                        .foregroundStyle(AtEaseDesignTokens.textSecondary)
                }
            }
            .background(Color.white.opacity(0.55), in: .rect(cornerRadius: 16))
        } else {
            VStack(alignment: .leading, spacing: 16) {
                Text("方案")
                    .font(.title2.weight(.light))
                    .foregroundStyle(AtEaseDesignTokens.textPrimary)

                ForEach(subscription.products) { product in
                    productCard(product)
                }
            }
        }
    }

    private func productCard(_ product: SubscriptionProduct) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(product.displayName)
                            .font(.headline.weight(.medium))
                            .foregroundStyle(AtEaseDesignTokens.textPrimary)
                        Text(product.displayPrice)
                            .font(.body)
                            .foregroundStyle(AtEaseDesignTokens.textSecondary)

                        if let offer = product.offerLabel {
                            Text(offer)
                                .font(.footnote)
                                .foregroundStyle(AtEaseDesignTokens.textSecondary.opacity(0.8))
                        }
                    }

                    Spacer()
                }

                if subscription.isSubscribed {
                    Text("当前已订阅")
                        .font(.footnote)
                        .foregroundStyle(AtEaseDesignTokens.textSecondary)
                } else {
                    PrimaryButton("选择", systemImage: "checkmark") {
                        Task {
                            await subscription.purchase(product)
                        }
                    }
                    .disabled(subscription.isWorking)
                }
            }
        }
        .background(Color.white.opacity(0.55), in: .rect(cornerRadius: 16))
    }

    private var restoreSection: some View {
        CardContainer {
            Button {
                Task {
                    await subscription.restore()
                }
            } label: {
                HStack {
                    Text("恢复购买")
                    if subscription.isWorking {
                        Spacer()
                        ProgressView()
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .font(.body)
            .foregroundStyle(AtEaseDesignTokens.textPrimary)
            .disabled(subscription.isWorking)

            Text("购买由 App Store 管理，可通过系统设置取消续期。")
                .font(.footnote)
                .foregroundStyle(AtEaseDesignTokens.textSecondary)
                .padding(.top, 4)
        }
        .background(Color.white.opacity(0.55), in: .rect(cornerRadius: 16))
    }
}
