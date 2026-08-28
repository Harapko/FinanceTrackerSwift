import Foundation

// MARK: - Cash Flow
struct CashFlowOverviewResponse: Decodable {
    let totalIncome: Double
    let totalExpenses: Double
    let netSavings: Double
    let expenseRatio: Double
    let currencyCode: String
}

struct MonthlyCashFlowEntry: Decodable, Identifiable {
    let year: Int
    let month: Int
    let income: Double
    let expenses: Double
    let netSavings: Double

    var id: String { "\(year)-\(month)" }

    var monthLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = 1
        let date = Calendar.current.date(from: comps) ?? Date()
        return formatter.string(from: date)
    }
}

struct CategoryBreakdownEntry: Decodable, Identifiable {
    let categoryId: String
    let categoryName: String
    let total: Double
    let count: Int
    let currencyCode: String

    var id: String { categoryId }
}

struct TopSpendingTransactionEntry: Decodable, Identifiable {
    let id: String
    let amount: Double
    let currencyCode: String
    let categoryName: String
    let payee: String
    let date: String
    let description: String?
}

// MARK: - Net Worth
struct NetWorthOverviewResponse: Decodable {
    let totalAssets: Double
    let totalLiabilities: Double
    let netWorth: Double
    let currencyCode: String
}

struct AssetAllocationEntry: Decodable, Identifiable {
    let type: String
    let label: String
    let value: Double
    let percentage: Double
    let currencyCode: String

    var id: String { type }
}

struct InvestmentHoldingEntry: Decodable, Identifiable {
    let instrumentId: String?
    let symbol: String
    let name: String
    let type: String
    let logoUrl: String?
    let totalQuantity: Double
    let totalAmount: Double
    let currentUnitPrice: Double?
    let costBasis: Double?
    let unrealizedPnL: Double?
    let unrealizedPnLPercent: Double?
    let currencyCode: String

    var id: String { symbol }
}

struct NetWorthBreakdownEntry: Decodable, Identifiable {
    let accountId: String
    let accountName: String
    let accountType: String
    let totalValue: Double
    let currencyCode: String

    var id: String { accountId }
}

// MARK: - Dashboard Stats
struct DashboardStatsResponse: Decodable {
    let netWorth: Double
    let totalIncome: Double
    let totalExpenses: Double
    let savingsRate: Double
    let currencyCode: String
}

struct BalanceHistoryEntry: Decodable, Identifiable {
    let date: String
    let balance: Double

    var id: String { date }
}

// MARK: - Analytics Filters
struct AnalyticsFilters {
    var fromDate: String?
    var toDate: String?
    var currencyCode: String

    func toQueryParams() -> [String: String] {
        var params: [String: String] = ["currencyCode": currencyCode]
        if let v = fromDate { params["fromDate"] = v }
        if let v = toDate { params["toDate"] = v }
        return params
    }
}
