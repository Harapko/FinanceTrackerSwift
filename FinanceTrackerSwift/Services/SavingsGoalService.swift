import Foundation

struct SavingsGoalService {
    static let shared = SavingsGoalService()
    private init() {}

    func getGoals() async throws -> [SavingsGoalResponse] {
        try await APIClient.shared.get("/api/savingsgoals")
    }

    func getGoal(id: String) async throws -> SavingsGoalResponse {
        try await APIClient.shared.get("/api/savingsgoals/\(id)")
    }

    func createGoal(_ payload: CreateSavingsGoalPayload) async throws -> SavingsGoalResponse {
        try await APIClient.shared.post("/api/savingsgoals", body: payload)
    }

    func updateGoal(id: String, payload: UpdateSavingsGoalPayload) async throws -> SavingsGoalResponse {
        try await APIClient.shared.put("/api/savingsgoals/\(id)", body: payload)
    }

    func deleteGoal(id: String) async throws {
        try await APIClient.shared.delete("/api/savingsgoals/\(id)")
    }

    func contribute(goalId: String, payload: ContributeSavingsGoalPayload) async throws -> SavingsGoalResponse {
        try await APIClient.shared.post("/api/savingsgoals/\(goalId)/contribute", body: payload)
    }

    func withdraw(goalId: String, payload: WithdrawSavingsGoalPayload) async throws -> SavingsGoalResponse {
        try await APIClient.shared.post("/api/savingsgoals/\(goalId)/withdraw", body: payload)
    }

    func removeInstrument(goalId: String, instrumentId: String) async throws -> SavingsGoalResponse {
        try await APIClient.shared.request(
            path: "/api/savingsgoals/\(goalId)/instruments/\(instrumentId)",
            method: "DELETE"
        )
    }

    func removeCash(goalId: String, amount: Double? = nil) async throws -> SavingsGoalResponse {
        var params: [String: String]? = nil
        if let amount { params = ["amount": String(amount)] }
        return try await APIClient.shared.request(
            path: "/api/savingsgoals/\(goalId)/cash",
            method: "DELETE",
            params: params
        )
    }

    func deleteContribution(goalId: String, contributionId: String) async throws -> SavingsGoalResponse {
        try await APIClient.shared.request(
            path: "/api/savingsgoals/\(goalId)/contributions/\(contributionId)",
            method: "DELETE"
        )
    }
}
