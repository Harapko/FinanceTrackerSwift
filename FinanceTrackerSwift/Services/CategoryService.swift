import Foundation

struct CategoryService {
    static let shared = CategoryService()
    private init() {}

    func getCategories(type: String? = nil) async throws -> [CategoryResponse] {
        var params: [String: String] = [:]
        if let type = type {
            params["type"] = type
        }
        return try await APIClient.shared.get("/api/categories", params: params.isEmpty ? nil : params)
    }

    func createCategory(_ payload: CreateCategoryPayload) async throws -> CategoryResponse {
        try await APIClient.shared.post("/api/categories", body: payload)
    }

    func updateCategory(id: String, payload: CreateCategoryPayload) async throws -> CategoryResponse {
        try await APIClient.shared.put("/api/categories/\(id)", body: payload)
    }

    func deleteCategory(id: String) async throws {
        try await APIClient.shared.delete("/api/categories/\(id)")
    }
}
