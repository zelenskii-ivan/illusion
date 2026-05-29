import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject private var store: StoreService
    @Environment(\.dismiss) private var dismiss
    @State private var selected: Product?

    private let benefits: [(String, LocalizedStringKey)] = [
        ("globe", "Все премиум-локации"),
        ("arrow.triangle.swap", "Multi-hop (Double VPN)"),
        ("theatermasks.fill", "Обфускация трафика"),
        ("bolt.fill", "Максимальная скорость"),
        ("play.rectangle.fill", "Стриминг без блокировок")
    ]

    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    header
                    benefitsList
                    plans
                    purchaseButton
                    footer
                }
                .padding(24)
            }
            .scrollIndicators(.hidden)

            closeButton
        }
        .onAppear { selected = store.products.first }
        .onChange(of: store.isPremium) { premium in
            if premium { dismiss() }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "crown.fill")
                .font(.system(size: 52))
                .foregroundStyle(Theme.accentGradient)
            Text("IllUsion Premium")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
            Text("Разблокируйте все возможности")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.top, 40)
    }

    private var benefitsList: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(benefits, id: \.0) { icon, text in
                HStack(spacing: 14) {
                    Image(systemName: icon)
                        .frame(width: 28)
                        .foregroundStyle(Theme.accent)
                    Text(text).foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.success)
                }
            }
        }
        .glassCard()
    }

    private var plans: some View {
        VStack(spacing: 12) {
            ForEach(store.products, id: \.id) { product in
                Button { selected = product } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(product.displayName).font(.headline).foregroundStyle(.white)
                            Text(product.description).font(.caption).foregroundStyle(.white.opacity(0.6))
                        }
                        Spacer()
                        Text(product.displayPrice).font(.headline).foregroundStyle(.white)
                    }
                    .padding(16)
                    .background(selected?.id == product.id ? Theme.accent.opacity(0.15) : Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(selected?.id == product.id ? Theme.accent : Theme.cardStroke, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
            }

            if store.products.isEmpty {
                ProgressView().tint(.white).padding()
            }
        }
    }

    private var purchaseButton: some View {
        Button {
            guard let selected else { return }
            Task { await store.purchase(selected) }
        } label: {
            HStack {
                if store.isPurchasing { ProgressView().tint(.white) }
                Text("Оформить подписку").font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.accentGradient)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .disabled(selected == nil || store.isPurchasing)
    }

    private var footer: some View {
        VStack(spacing: 8) {
            Button("Восстановить покупки") { Task { await store.restore() } }
                .font(.footnote)
                .foregroundStyle(Theme.accent)
            Text("Подписка продлевается автоматически. Отмена в настройках App Store.")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
    }

    private var closeButton: some View {
        VStack {
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            Spacer()
        }
        .padding()
    }
}
