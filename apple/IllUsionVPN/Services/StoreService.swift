import Foundation
import StoreKit

/// Управление подписками через StoreKit 2.
@MainActor
final class StoreService: ObservableObject {
    /// Идентификаторы продуктов (должны совпадать с App Store Connect / .storekit).
    enum ProductID: String, CaseIterable {
        case monthly = "com.illusion.vpn.premium.monthly"
        case yearly = "com.illusion.vpn.premium.yearly"
    }

    @Published private(set) var products: [Product] = []
    @Published private(set) var isPremium = false
    @Published var isPurchasing = false
    @Published var lastError: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        // Слушаем обновления транзакций (renewals, refunds, покупки с других устройств).
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(transactionResult: result)
            }
        }
    }

    deinit { updatesTask?.cancel() }

    func loadProducts() async {
        do {
            let loaded = try await Product.products(for: ProductID.allCases.map(\.rawValue))
            products = loaded.sorted { $0.price < $1.price }
            await refreshEntitlements()
        } catch {
            lastError = "Не удалось загрузить продукты: \(error.localizedDescription)"
            Log.app.error("StoreKit load failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func purchase(_ product: Product) async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshEntitlements()
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Пересчитывает активные права на основе текущих прав (entitlements).
    func refreshEntitlements() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               ProductID(rawValue: transaction.productID) != nil,
               transaction.revocationDate == nil {
                active = true
            }
        }
        isPremium = active
    }

    private func handle(transactionResult: VerificationResult<Transaction>) async {
        guard let transaction = try? checkVerified(transactionResult) else { return }
        await transaction.finish()
        await refreshEntitlements()
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe): return safe
        case .unverified: throw StoreError.failedVerification
        }
    }

    enum StoreError: LocalizedError {
        case failedVerification
        var errorDescription: String? { "Не удалось проверить покупку" }
    }
}
