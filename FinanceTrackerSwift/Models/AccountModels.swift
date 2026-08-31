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
        case .bankAccount: return L10n.Accounts.typeBankAccount
        case .creditCard: return L10n.Accounts.typeCreditCard
        case .cash: return L10n.Accounts.typeCash
        case .cryptoWallet: return L10n.Accounts.typeCryptoWallet
        case .investmentAccount: return L10n.Accounts.typeInvestmentAccount
        case .other: return L10n.Accounts.typeOther
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
        case .checking: return L10n.Accounts.subTypeChecking
        case .savings: return L10n.Accounts.subTypeSavings
        case .credit: return L10n.Accounts.subTypeCredit
        case .investment: return L10n.Accounts.subTypeInvestment
        case .cash: return L10n.Accounts.subTypeCash
        case .other: return L10n.Accounts.typeOther
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
