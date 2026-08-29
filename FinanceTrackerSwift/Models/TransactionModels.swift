import Foundation

enum TransactionType: String, Codable, CaseIterable {
    case expense = "Expense"
    case income = "Income"
    case transfer = "Transfer"

    var displayName: String {
        switch self {
        case .expense: return "Expense"
        case .income: return "Income"
        case .transfer: return "Transfer"
        }
    }

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
    let accountName: String?
    let subAccountId: String?
    let subAccountName: String?
    let categoryId: String?
    let categoryName: String?
    let type: TransactionType
    let amount: Double
    let currencyCode: String
    let exchangeRate: Double?
    let description: String?
    let date: String
    let time: String?
    let payee: String?
    let location: String?
    let tags: [String]?
    let createdAtUtc: String?
}

// GET /api/transactions returns { items: [...], totalCount, page, pageSize }
struct PagedTransactions: Decodable {
    let items: [TransactionResponse]
    let totalCount: Int?
    let page: Int?
    let pageSize: Int?
}

struct CategoryResponse: Decodable, Identifiable {
    let id: String
    let name: String
    let type: String?
    let color: String?
    let icon: String?
}

struct CreateTransactionPayload: Encodable {
    let accountId: String
    let subAccountId: String?
    let categoryId: String?
    let type: String
    let amount: Double
    let currencyCode: String
    let description: String?
    let date: String
    let time: String?
    let payee: String?
    let tags: [String]?

    init(
        accountId: String,
        subAccountId: String? = nil,
        categoryId: String? = nil,
        type: String,
        amount: Double,
        currencyCode: String,
        description: String? = nil,
        date: String,
        time: String? = nil,
        payee: String? = nil,
        tags: [String]? = nil
    ) {
        self.accountId = accountId
        self.subAccountId = subAccountId
        self.categoryId = categoryId
        self.type = type
        self.amount = amount
        self.currencyCode = currencyCode
        self.description = description
        self.date = date
        self.time = time
        self.payee = payee
        self.tags = tags
    }
}
