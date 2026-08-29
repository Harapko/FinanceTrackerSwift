import Foundation

enum AccountType: String, Codable, CaseIterable {
    case bankAccount = "BankAccount"
    case creditCard = "CreditCard"
    case cash = "Cash"
    case cryptoWallet = "CryptoWallet"
    case investmentAccount = "InvestmentAccount"
    case other = "Other"

    var displayName: String {
        switch self {
        case .bankAccount: return "Bank Account"
        case .creditCard: return "Credit Card"
        case .cash: return "Cash"
        case .cryptoWallet: return "Crypto Wallet"
        case .investmentAccount: return "Investment Account"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .bankAccount: return "building.columns"
        case .creditCard: return "creditcard"
        case .cash: return "banknote"
        case .cryptoWallet: return "bitcoinsign.circle"
        case .investmentAccount: return "chart.line.uptrend.xyaxis"
        case .other: return "briefcase"
        }
    }
}

enum SubAccountType: String, Codable, CaseIterable {
    case checking = "Checking"
    case savings = "Savings"
    case credit = "Credit"
    case investment = "Investment"
    case cash = "Cash"
    case other = "Other"

    var displayName: String {
        switch self {
        case .checking: return "Checking"
        case .savings: return "Savings"
        case .credit: return "Credit"
        case .investment: return "Investment"
        case .cash: return "Cash"
        case .other: return "Other"
        }
    }
}

struct AccountResponse: Decodable, Identifiable {
    let id: String
    let name: String
    let type: AccountType
    let currencyCode: String
    let description: String?
    let icon: String?
    let color: String?
    let balance: Double?
    let holdingsValue: Double?
    let totalValue: Double
    let subAccounts: [SubAccountResponse]?
    let isArchived: Bool?
    let sortOrder: Int?
    let createdAtUtc: String?

    var subAccountsList: [SubAccountResponse] { subAccounts ?? [] }
}

struct SubAccountResponse: Decodable, Identifiable {
    let id: String
    let accountId: String?
    let name: String
    let type: SubAccountType
    let currencyCode: String
    let description: String?
    let isArchived: Bool?
    let sortOrder: Int?
    let cashBalance: Double?
    let holdingsValue: Double?
    let totalValue: Double
    let createdAtUtc: String?
}

struct CreateAccountPayload: Encodable {
    let name: String
    let type: String
    let currencyCode: String
    let description: String?
    let color: String?
}

struct UpdateAccountPayload: Encodable {
    let name: String
    let type: String
    let currencyCode: String
    let description: String?
    let color: String?
}

struct CreateSubAccountPayload: Encodable {
    let name: String
    let type: String
    let currencyCode: String
    let description: String?
}

struct UpdateSubAccountPayload: Encodable {
    let name: String
    let type: String
    let currencyCode: String
    let description: String?
}
