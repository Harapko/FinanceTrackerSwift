import Foundation

struct TransactionService {
    static let shared = TransactionService()
    private init() {}

    func getTransactions(filters: TransactionFilterParams) async throws -> PagedResult<TransactionResponse> {
        try await APIClient.shared.get("/api/transactions", params: filters.toQueryParams())
    }

    func getRecentTransactions(limit: Int = 5) async throws -> [TransactionResponse] {
        let paged: PagedResult<TransactionResponse> = try await APIClient.shared.get(
            "/api/transactions",
            params: ["page": "1", "pageSize": "\(limit)"]
        )
        return paged.items
    }

    func createTransaction(_ payload: CreateTransactionPayload) async throws -> TransactionResponse {
        try await APIClient.shared.post("/api/transactions", body: payload)
    }

    func deleteTransaction(id: String) async throws {
        try await APIClient.shared.delete("/api/transactions/\(id)")
    }

    func getCategories() async throws -> [CategoryResponse] {
        try await APIClient.shared.get("/api/categories")
    }
}
