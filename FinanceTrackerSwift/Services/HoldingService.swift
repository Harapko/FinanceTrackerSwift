import Foundation

struct HoldingService {
    static let shared = HoldingService()
    private init() {}

    func getAccountHoldings(accountId: String) async throws -> [HoldingResponse] {
        try await APIClient.shared.get("/api/holdings/accounts/\(accountId)")
    }

    func getSubAccountHoldings(subAccountId: String) async throws -> [HoldingResponse] {
        try await APIClient.shared.get("/api/holdings/sub-accounts/\(subAccountId)")
    }

    func getHoldingById(id: String) async throws -> HoldingResponse {
        try await APIClient.shared.get("/api/holdings/\(id)")
    }

    func updateHolding(id: String, payload: UpdateHoldingPayload) async throws -> HoldingResponse {
        try await APIClient.shared.put("/api/holdings/\(id)", body: payload)
    }

    func deleteHolding(id: String) async throws {
        try await APIClient.shared.delete("/api/holdings/\(id)")
    }

    func searchInstruments(query: String, type: String? = nil) async throws -> [InstrumentResponse] {
        var params: [String: String] = ["query": query]
        if let type, !type.isEmpty { params["type"] = type }
        return try await APIClient.shared.get("/api/instruments", params: params)
    }

    func getLiveQuote(symbol: String, type: String? = nil) async throws -> MarketQuote {
        var params: [String: String]? = nil
        if let type, !type.isEmpty { params = ["type": type] }
        let encoded = symbol.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? symbol
        return try await APIClient.shared.get("/api/instruments/quote/\(encoded)", params: params)
    }

    func ensureInstrument(symbol: String, type: String? = nil) async throws -> InstrumentResponse {
        var params: [String: String] = ["symbol": symbol]
        if let type, !type.isEmpty { params["type"] = type }
        return try await APIClient.shared.post("/api/instruments/ensure", params: params)
    }

    func createInstrumentTransaction(
        accountId: String,
        subAccountId: String? = nil,
        payload: CreateInstrumentTransactionPayload
    ) async throws {
        if let subAccountId, !subAccountId.isEmpty {
            let _: EmptyResponse = try await APIClient.shared.post(
                "/api/subaccounts/\(subAccountId)/instrument-transactions",
                body: payload
            )
        } else {
            let _: EmptyResponse = try await APIClient.shared.post(
                "/api/accounts/\(accountId)/instrument-transactions",
                body: payload
            )
        }
    }
}
