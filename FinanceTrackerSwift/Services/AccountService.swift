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

    func updateAccount(id: String, payload: UpdateAccountPayload) async throws -> AccountResponse {
        try await APIClient.shared.put("/api/accounts/\(id)", body: payload)
    }

    func deleteAccount(id: String) async throws {
        try await APIClient.shared.delete("/api/accounts/\(id)")
    }

    func createSubAccount(accountId: String, payload: CreateSubAccountPayload) async throws -> SubAccountResponse {
        try await APIClient.shared.post("/api/accounts/\(accountId)/subaccounts", body: payload)
    }

    func updateSubAccount(accountId: String, subAccountId: String, payload: UpdateSubAccountPayload) async throws -> SubAccountResponse {
        try await APIClient.shared.put("/api/accounts/\(accountId)/subaccounts/\(subAccountId)", body: payload)
    }

    func deleteSubAccount(accountId: String, subAccountId: String) async throws {
        try await APIClient.shared.delete("/api/accounts/\(accountId)/subaccounts/\(subAccountId)")
    }

    func reorderAccounts(accountIds: [String]) async throws {
        try await APIClient.shared.postVoid("/api/accounts/reorder", body: ReorderAccountsPayload(accountIds: accountIds))
    }

    func reorderSubAccounts(accountId: String, subAccountIds: [String]) async throws {
        try await APIClient.shared.postVoid("/api/accounts/\(accountId)/subaccounts/reorder", body: ReorderSubAccountsPayload(subAccountIds: subAccountIds))
    }
}
