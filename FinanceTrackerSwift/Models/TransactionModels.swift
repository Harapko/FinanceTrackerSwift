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

struct TagResponse: Decodable, Identifiable, Hashable {
    let id: String
    let name: String
    let color: String?

    enum CodingKeys: String, CodingKey {
        case id, name, color
    }

    init(id: String, name: String, color: String? = nil) {
        self.id = id
        self.name = name
        self.color = color
    }

    init(from decoder: Decoder) throws {
        // Can decode either from TagResponse object { id, name, color } or raw String
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
            name = (try? container.decode(String.self, forKey: .name)) ?? ""
            color = try? container.decode(String.self, forKey: .color)
        } else if let singleValue = try? decoder.singleValueContainer(), let str = try? singleValue.decode(String.self) {
            id = str
            name = str
            color = nil
        } else {
            id = UUID().uuidString
            name = ""
            color = nil
        }
    }
}

struct TransactionResponse: Decodable, Identifiable, Hashable {
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
    let tags: [TagResponse]?
    let createdAtUtc: String?

    enum CodingKeys: String, CodingKey {
        case id, accountId, accountName, subAccountId, subAccountName
        case categoryId, categoryName, type, amount, currencyCode, exchangeRate
        case description, date, time, payee, location, tags, createdAtUtc
    }

    init(
        id: String,
        accountId: String,
        accountName: String? = nil,
        subAccountId: String? = nil,
        subAccountName: String? = nil,
        categoryId: String? = nil,
        categoryName: String? = nil,
        type: TransactionType = .expense,
        amount: Double,
        currencyCode: String = "USD",
        exchangeRate: Double? = nil,
        description: String? = nil,
        date: String,
        time: String? = nil,
        payee: String? = nil,
        location: String? = nil,
        tags: [TagResponse]? = nil,
        createdAtUtc: String? = nil
    ) {
        self.id = id
        self.accountId = accountId
        self.accountName = accountName
        self.subAccountId = subAccountId
        self.subAccountName = subAccountName
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.type = type
        self.amount = amount
        self.currencyCode = currencyCode
        self.exchangeRate = exchangeRate
        self.description = description
        self.date = date
        self.time = time
        self.payee = payee
        self.location = location
        self.tags = tags
        self.createdAtUtc = createdAtUtc
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        accountId = (try? container.decode(String.self, forKey: .accountId)) ?? ""
        accountName = try? container.decode(String.self, forKey: .accountName)
        subAccountId = try? container.decode(String.self, forKey: .subAccountId)
        subAccountName = try? container.decode(String.self, forKey: .subAccountName)
        categoryId = try? container.decode(String.self, forKey: .categoryId)
        categoryName = try? container.decode(String.self, forKey: .categoryName)

        if let t = try? container.decode(TransactionType.self, forKey: .type) {
            type = t
        } else if let typeStr = try? container.decode(String.self, forKey: .type) {
            type = TransactionType(rawValue: typeStr) ?? .expense
        } else {
            type = .expense
        }

        amount = (try? container.decode(Double.self, forKey: .amount)) ?? 0.0
        currencyCode = (try? container.decode(String.self, forKey: .currencyCode)) ?? "USD"
        exchangeRate = try? container.decode(Double.self, forKey: .exchangeRate)
        description = try? container.decode(String.self, forKey: .description)
        date = (try? container.decode(String.self, forKey: .date)) ?? ""
        time = try? container.decode(String.self, forKey: .time)
        payee = try? container.decode(String.self, forKey: .payee)
        location = try? container.decode(String.self, forKey: .location)
        tags = try? container.decode([TagResponse].self, forKey: .tags)
        createdAtUtc = try? container.decode(String.self, forKey: .createdAtUtc)
    }
}

// GET /api/transactions returns { items: [...], totalCount, page, pageSize, totalPages }
struct PagedTransactions: Decodable {
    let items: [TransactionResponse]
    let totalCount: Int?
    let page: Int?
    let pageSize: Int?
    let totalPages: Int?

    enum CodingKeys: String, CodingKey {
        case items, totalCount, page, pageSize, totalPages
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = (try? container.decode([TransactionResponse].self, forKey: .items)) ?? []
        totalCount = try? container.decode(Int.self, forKey: .totalCount)
        page = try? container.decode(Int.self, forKey: .page)
        pageSize = try? container.decode(Int.self, forKey: .pageSize)
        totalPages = try? container.decode(Int.self, forKey: .totalPages)
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
    let time: String?
    let payee: String?
    let tags: [String]?

    init(
        accountId: String,
        subAccountId: String? = nil,
        categoryId: String,
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
