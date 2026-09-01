import Foundation

enum TransactionType: String, Codable, CaseIterable {
    case expense = "Expense"
    case income = "Income"
    case transfer = "Transfer"

    var displayName: String {
        switch self {
        case .expense: return L10n.Transactions.typeExpense
        case .income: return L10n.Transactions.typeIncome
        case .transfer: return L10n.Transactions.typeTransfer
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
    let categoryIcon: String?
    let categoryColor: String?
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
    let transferDestAccountId: String?
    let transferDestAccountName: String?
    let transferDestSubAccountId: String?
    let transferDestSubAccountName: String?

    enum CodingKeys: String, CodingKey {
        case id, accountId, accountName, subAccountId, subAccountName
        case categoryId, categoryName, categoryIcon, categoryColor
        case type, amount, currencyCode, exchangeRate
        case description, date, time, payee, location, tags, createdAtUtc
        case transferDestAccountId, transferDestAccountName
        case transferDestSubAccountId, transferDestSubAccountName
    }

    init(
        id: String,
        accountId: String,
        accountName: String? = nil,
        subAccountId: String? = nil,
        subAccountName: String? = nil,
        categoryId: String? = nil,
        categoryName: String? = nil,
        categoryIcon: String? = nil,
        categoryColor: String? = nil,
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
        createdAtUtc: String? = nil,
        transferDestAccountId: String? = nil,
        transferDestAccountName: String? = nil,
        transferDestSubAccountId: String? = nil,
        transferDestSubAccountName: String? = nil
    ) {
        self.id = id
        self.accountId = accountId
        self.accountName = accountName
        self.subAccountId = subAccountId
        self.subAccountName = subAccountName
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.categoryIcon = categoryIcon
        self.categoryColor = categoryColor
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
        self.transferDestAccountId = transferDestAccountId
        self.transferDestAccountName = transferDestAccountName
        self.transferDestSubAccountId = transferDestSubAccountId
        self.transferDestSubAccountName = transferDestSubAccountName
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
        categoryIcon = try? container.decode(String.self, forKey: .categoryIcon)
        categoryColor = try? container.decode(String.self, forKey: .categoryColor)

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
        transferDestAccountId = try? container.decode(String.self, forKey: .transferDestAccountId)
        transferDestAccountName = try? container.decode(String.self, forKey: .transferDestAccountName)
        transferDestSubAccountId = try? container.decode(String.self, forKey: .transferDestSubAccountId)
        transferDestSubAccountName = try? container.decode(String.self, forKey: .transferDestSubAccountName)
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

struct CreateTransferPayload: Encodable {
    let sourceAccountId: String
    let sourceSubAccountId: String?
    let destAccountId: String
    let destSubAccountId: String?
    let amount: Double
    let currencyCode: String
    let exchangeRate: Double?
    let description: String?
    let date: String
    let payee: String?

    init(
        sourceAccountId: String,
        sourceSubAccountId: String? = nil,
        destAccountId: String,
        destSubAccountId: String? = nil,
        amount: Double,
        currencyCode: String,
        exchangeRate: Double? = nil,
        description: String? = nil,
        date: String,
        payee: String? = nil
    ) {
        self.sourceAccountId = sourceAccountId
        self.sourceSubAccountId = sourceSubAccountId
        self.destAccountId = destAccountId
        self.destSubAccountId = destSubAccountId
        self.amount = amount
        self.currencyCode = currencyCode
        self.exchangeRate = exchangeRate
        self.description = description
        self.date = date
        self.payee = payee
    }
}

struct UpdateTransactionPayload: Encodable {
    let accountId: String?
    let subAccountId: String?
    let categoryId: String?
    let type: String?
    let amount: Double?
    let currencyCode: String?
    let exchangeRate: Double?
    let description: String?
    let date: String?
    let time: String?
    let payee: String?
    let transferDestAccountId: String?
    let transferDestSubAccountId: String?

    init(
        accountId: String? = nil,
        subAccountId: String? = nil,
        categoryId: String? = nil,
        type: String? = nil,
        amount: Double? = nil,
        currencyCode: String? = nil,
        exchangeRate: Double? = nil,
        description: String? = nil,
        date: String? = nil,
        time: String? = nil,
        payee: String? = nil,
        transferDestAccountId: String? = nil,
        transferDestSubAccountId: String? = nil
    ) {
        self.accountId = accountId
        self.subAccountId = subAccountId
        self.categoryId = categoryId
        self.type = type
        self.amount = amount
        self.currencyCode = currencyCode
        self.exchangeRate = exchangeRate
        self.description = description
        self.date = date
        self.time = time
        self.payee = payee
        self.transferDestAccountId = transferDestAccountId
        self.transferDestSubAccountId = transferDestSubAccountId
    }
}

// MARK: - Transaction Period & Date Grouping
enum TransactionPeriodMode: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"
    case period = "Period"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .day: return L10n.Transactions.day
        case .week: return L10n.Transactions.week
        case .month: return L10n.Transactions.month
        case .year: return L10n.Transactions.year
        case .period: return L10n.Transactions.period
        }
    }
}

struct TransactionDateGroup: Identifiable {
    var id: String { dateString }
    let dateString: String
    let formattedDate: String
    let transactions: [TransactionResponse]
    let totalExpense: Double
    let totalIncome: Double
}
