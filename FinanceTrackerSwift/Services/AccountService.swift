import Foundation

struct AccountService {
    static let shared = AccountService()
    private init() {}

    func getAccounts() async throws -> [AccountResponse] {
        try await APIClient.shared.get("/api/accounts")
    }

    func getAccount(id: String) async throws -> AccountResponse {
        try await APIClient.shared.get("/api/accounts/\(id)")
    }

    func createAccount(_ payload: CreateAccountPayload) async throws -> AccountResponse {
        try await APIClient.shared.post("/api/accounts", body: payload)
    }

    func updateAccount(id: String, payload: CreateAccountPayload) async throws -> AccountResponse {
        try await APIClient.shared.put("/api/accounts/\(id)", body: payload)
    }

    func deleteAccount(id: String) async throws {
        try await APIClient.shared.delete("/api/accounts/\(id)")
    }

    func createSubAccount(accountId: String, payload: CreateSubAccountPayload) async throws -> SubAccountResponse {
        try await APIClient.shared.post("/api/accounts/\(accountId)/subaccounts", body: payload)
    }

    func deleteSubAccount(accountId: String, subAccountId: String) async throws {
        try await APIClient.shared.delete("/api/accounts/\(accountId)/subaccounts/\(subAccountId)")
    }
}
