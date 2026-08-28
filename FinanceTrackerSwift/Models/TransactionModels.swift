import Foundation

enum TransactionType: String, Codable, CaseIterable {
    case income = "Income"
    case expense = "Expense"
    case transfer = "Transfer"

    var displayName: String { rawValue }

    var icon: String {
        switch self {
        case .income: return "arrow.down.circle.fill"
        case .expense: return "arrow.up.circle.fill"
        case .transfer: return "arrow.left.arrow.right.circle.fill"
        }
    }
}

struct TransactionResponse: Decodable, Identifiable {
    let id: String
    let accountId: String
    let accountName: String
    let subAccountId: String?
    let subAccountName: String?
    let categoryId: String
    let categoryName: String
    let categoryType: String
    let type: TransactionType
    let amount: Double
    let currencyCode: String
    let exchangeRate: Double?
    let description: String?
    let date: String
    let time: String
    let payee: String
    let transferDestAccountId: String?
    let transferDestAccountName: String?
    let transferDestSubAccountId: String?
    let transferDestSubAccountName: String?
    let createdAtUtc: String
}

struct PagedResult<T: Decodable>: Decodable {
    let items: [T]
    let pageNumber: Int
    let pageSize: Int
    let totalPages: Int
    let totalCount: Int
    let hasPreviousPage: Bool
    let hasNextPage: Bool
}

struct TransactionFilterParams {
    var accountId: String?
    var subAccountId: String?
    var categoryId: String?
    var type: String?
    var fromDate: String?
    var toDate: String?
    var minAmount: Double?
    var maxAmount: Double?
    var search: String?
    var page: Int = 1
    var pageSize: Int = 12

    func toQueryParams() -> [String: String] {
        var params: [String: String] = [
            "page": "\(page)",
            "pageSize": "\(pageSize)"
        ]
        if let v = accountId { params["accountId"] = v }
        if let v = subAccountId { params["subAccountId"] = v }
        if let v = categoryId { params["categoryId"] = v }
        if let v = type { params["type"] = v }
        if let v = fromDate { params["fromDate"] = v }
        if let v = toDate { params["toDate"] = v }
        if let v = minAmount { params["minAmount"] = "\(v)" }
        if let v = maxAmount { params["maxAmount"] = "\(v)" }
        if let v = search { params["search"] = v }
        return params
    }
}

struct CreateTransactionPayload: Encodable {
    let accountId: String
    let subAccountId: String?
    let categoryId: String
    let type: String
    let amount: Double
    let currencyCode: String
    let description: String?
    let date: String
    let time: String
    let payee: String
}

struct CategoryResponse: Decodable, Identifiable {
    let id: String
    let name: String
    let type: String
    let icon: String?
    let color: String?
}
