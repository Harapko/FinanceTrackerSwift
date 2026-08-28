import Foundation

struct SavingsGoalService {
    static let shared = SavingsGoalService()
    private init() {}

    func getGoals() async throws -> [SavingsGoalResponse] {
        try await APIClient.shared.get("/api/savings-goals")
    }

    func getGoal(id: String) async throws -> SavingsGoalResponse {
        try await APIClient.shared.get("/api/savings-goals/\(id)")
    }

    func createGoal(_ payload: CreateSavingsGoalPayload) async throws -> SavingsGoalResponse {
        try await APIClient.shared.post("/api/savings-goals", body: payload)
    }

    func updateGoal(id: String, payload: UpdateSavingsGoalPayload) async throws -> SavingsGoalResponse {
        try await APIClient.shared.put("/api/savings-goals/\(id)", body: payload)
    }

    func deleteGoal(id: String) async throws {
        try await APIClient.shared.delete("/api/savings-goals/\(id)")
    }

    func contribute(goalId: String, payload: ContributeSavingsGoalPayload) async throws -> SavingsGoalResponse {
        try await APIClient.shared.post("/api/savings-goals/\(goalId)/contribute", body: payload)
    }
}
