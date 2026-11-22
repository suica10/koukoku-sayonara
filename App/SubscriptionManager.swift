import StoreKit

@MainActor
final class SubscriptionManager: ObservableObject {
    static let productID = "jp.onejpkey.KoukokuSayonara.monthly"

    @Published var product: Product?
    @Published var isEntitled = false
    @Published var statusText = "未加入"
    @Published var isPurchasing = false

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                }
                await self?.refreshEntitlement()
            }
        }
    }

    func load() async {
        product = try? await Product.products(for: [Self.productID]).first
        await refreshEntitlement()
    }

    func refreshEntitlement() async {
        var entitled = false
        var text = "未加入"
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  transaction.productID == Self.productID,
                  let expiration = transaction.expirationDate,
                  expiration > Date() else { continue }
            entitled = true
            text = transaction.offerType == .introductory ? "無料トライアル中" : "加入中"
        }
        isEntitled = entitled
        statusText = text
    }

    func purchase() async -> Bool {
        guard let product, !isPurchasing else { return false }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            if case .success(let verification) = result,
               case .verified(let transaction) = verification {
                await transaction.finish()
                await refreshEntitlement()
                return isEntitled
            }
        } catch {
            // 購入シート側のエラー表示に任せる
        }
        return false
    }

    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlement()
    }
}
