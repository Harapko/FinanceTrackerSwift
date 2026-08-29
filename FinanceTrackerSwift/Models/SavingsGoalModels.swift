import Foundation

struct SavingsGoalContributionResponse: Decodable, Identifiable {
    let id: String
    let savingsGoalId: String
    let instrumentId: String?
    let instrumentSymbol: String?
    let instrumentName: String?
    let instrumentType: String?
    let instrumentLogoUrl: String?
    let amount: Double
    let quantity: Double?
    let unitPrice: Double?
    let assetCurrencyCode: String?
    let note: String?
    let createdAtUtc: String
}

struct SavedInstrumentSummary: Decodable, Identifiable {
    let instrumentId: String?
    let symbol: String
    let name: String
    let type: String
    let logoUrl: String?
    let totalQuantity: Double
    let totalAmount: Double
    let currentUnitPrice: Double?
    let costBasis: Double?
    let unrealizedPnL: Double?
    let unrealizedPnLPercent: Double?

    var id: String { instrumentId ?? symbol }
}

struct SavingsGoalResponse: Decodable, Identifiable {
    let id: String
    let name: String
    let targetAmount: Double
    let currentAmount: Double
    let currencyCode: String
    let accountId: String?
    let accountName: String?
    let accountIcon: String?
    let accountColor: String?
    let subAccountId: String?
    let subAccountName: String?
    let instrumentId: String?
    let instrumentSymbol: String?
    let instrumentName: String?
    let instrumentType: String?
    let instrumentLogoUrl: String?
    let deadline: String?
    let description: String?
    let icon: String?
    let color: String?
    let progressPercent: Double?
    let isCompleted: Bool
    let contributions: [SavingsGoalContributionResponse]?
    let savedInstruments: [SavedInstrumentSummary]?

    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(currentAmount / targetAmount, 1.0)
    }

    var contributionsList: [SavingsGoalContributionResponse] { contributions ?? [] }
    var savedInstrumentsList: [SavedInstrumentSummary] { savedInstruments ?? [] }
}

struct ContributionItemPayload: Encodable {
    let instrumentId: String?
    let symbol: String?
    let name: String?
    let type: String?
    let amount: Double
    let quantity: Double?
    let unitPrice: Double?
    let assetCurrencyCode: String?
    let note: String?
}

struct ContributeSavingsGoalPayload: Encodable {
    let amount: Double
    let instrumentId: String?
    let quantity: Double?
    let note: String?
    let items: [ContributionItemPayload]?
}

struct WithdrawSavingsGoalPayload: Encodable {
    let amount: Double
    let note: String?
}

struct CreateSavingsGoalPayload: Encodable {
    let name: String
    let targetAmount: Double?
    let currencyCode: String
    let deadline: String?
    let description: String?
    let icon: String?
    let color: String?
    let accountId: String?
    let subAccountId: String?
    let instrumentId: String?
}

struct UpdateSavingsGoalPayload: Encodable {
    let name: String?
    let targetAmount: Double?
    let currencyCode: String?
    let deadline: String?
    let description: String?
    let icon: String?
    let color: String?
    let accountId: String?
    let subAccountId: String?
    let instrumentId: String?
}
