import Foundation

struct TransactionService {
    static let shared = TransactionService()
    private init() {}

    func getTransactions(page: Int = 1, pageSize: Int = 20,
                         type: String? = nil, search: String? = nil,
                         fromDate: String? = nil, toDate: String? = nil) async throws -> PagedTransactions {
        var params: [String: String] = ["page": "\(page)", "pageSize": "\(pageSize)"]
        if let t = type { params["type"] = t }
        if let s = search, !s.isEmpty { params["search"] = s }
        if let f = fromDate { params["fromDate"] = f }
        if let t = toDate { params["toDate"] = t }
        return try await APIClient.shared.get("/api/transactions", params: params)
    }

    func getRecentTransactions(limit: Int = 5) async throws -> [TransactionResponse] {
        let paged = try await getTransactions(pageSize: limit)
        return paged.items
    }

    func createTransaction(_ payload: CreateTransactionPayload) async throws -> TransactionResponse {
        try await APIClient.shared.post("/api/transactions", body: payload)
    }

    func createTransfer(_ payload: CreateTransferPayload) async throws -> TransactionResponse {
        try await APIClient.shared.post("/api/transactions/transfer", body: payload)
    }

    func updateTransaction(id: String, payload: UpdateTransactionPayload) async throws -> TransactionResponse {
        try await APIClient.shared.put("/api/transactions/\(id)", body: payload)
    }

    func deleteTransaction(id: String) async throws {
        try await APIClient.shared.delete("/api/transactions/\(id)")
    }

    func getCategories() async throws -> [CategoryResponse] {
        try await APIClient.shared.get("/api/categories")
    }
}
