import Foundation

struct HoldingResponse: Decodable, Identifiable {
    let id: String
    let accountId: String
    let subAccountId: String?
    let instrumentId: String
    let instrumentSymbol: String
    let instrumentName: String
    let instrumentType: String
    let quantity: Double
    let averageBuyPrice: Double
    let currentPrice: Double
    let marketValue: Double
    let unrealizedPnL: Double
    let unrealizedPnLPercent: Double
    let currencyCode: String
    let subAccountName: String?
    let accountName: String?
    let convertedMarketValue: Double?
    let targetCurrencyCode: String?
    let notes: String?
}

struct InstrumentResponse: Decodable, Identifiable {
    let id: String
    let symbol: String
    let name: String?
    let type: String?
    let exchange: String?
    let currencyCode: String?
    let latestPrice: Double?
    let currentPrice: Double?
    let logoUrl: String?

    var resolvedPrice: Double {
        latestPrice ?? currentPrice ?? 0.0
    }
}

struct MarketQuote: Decodable {
    let symbol: String
    let name: String?
    let price: Double?
    let currentPrice: Double?
    let currencyCode: String?
    let change: Double?
    let changePercent: Double?
    let type: String?
    let provider: String?

    var resolvedPrice: Double {
        price ?? currentPrice ?? 0.0
    }
}

struct CreateInstrumentTransactionPayload: Encodable {
    let instrumentId: String
    let type: String
    let quantity: Double
    let pricePerUnit: Double
    let subAccountId: String?
    let fee: Double
    let currencyCode: String
    let date: String?
    let time: String?
    let notes: String?
}

struct UpdateHoldingPayload: Encodable {
    let quantity: Double
    let averageBuyPrice: Double
    let subAccountId: String?
    let notes: String?
    let customName: String?
}
