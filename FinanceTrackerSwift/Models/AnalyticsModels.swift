import Foundation

// MARK: - Balance History
// GET /api/analytics/balance-history → [BalanceHistoryEntry]
struct BalanceHistoryEntry: Decodable, Identifiable {
    let date: String
    let balance: Double
    let accountId: String?
    let accountName: String?
    let currencyCode: String

    var id: String { date + (accountId ?? "") }
}

// MARK: - Expense / Income by Category
// GET /api/analytics/expense-by-category → CategoryBreakdownResponse
// GET /api/analytics/income-by-category  → CategoryBreakdownResponse
struct CategoryBreakdownResponse: Decodable {
    let items: [CategoryBreakdownEntry]
    let totalAmount: Double
    let currencyCode: String
}

struct CategoryBreakdownEntry: Decodable, Identifiable {
    let categoryId: String
    let categoryName: String
    let amount: Double
    let percentage: Double
    let color: String?

    var id: String { categoryId }
    var total: Double { amount }
}

// MARK: - Income vs Expense (monthly)
// GET /api/analytics/income-vs-expense → [MonthlyPeriodEntry]
struct MonthlyPeriodEntry: Decodable, Identifiable {
    let period: String       // "2026-08"
    let income: Double
    let expense: Double
    let net: Double
    let savingsRate: Double
    let currencyCode: String

    var id: String { period }
    // Alias for chart use
    var monthLabel: String { String(period.suffix(5).prefix(5)) }
    var expenses: Double { expense }
    var netSavings: Double { net }
}

// MARK: - Net Worth
// GET /api/analytics/net-worth → NetWorthResponse
struct NetWorthResponse: Decodable {
    let totalAssets: Double
    let totalLiabilities: Double
    let netWorth: Double
    let accountBreakdown: [NetWorthAccountBreakdown]
    let currencyCode: String
}

struct NetWorthAccountBreakdown: Decodable, Identifiable {
    let accountId: String
    let accountName: String
    let accountType: String
    let value: Double
    let currencyCode: String

    var id: String { accountId }
}

// MARK: - Cash Flow
// GET /api/analytics/cash-flow → CashFlowResponse
struct CashFlowResponse: Decodable {
    let items: [CashFlowEntry]
}

struct CashFlowEntry: Decodable, Identifiable {
    let date: String
    let income: Double
    let expense: Double
    let netFlow: Double
    let cumulativeFlow: Double

    var id: String { date }
}

// MARK: - Top Spending
// GET /api/analytics/top-spending → TopSpendingResponse
struct TopSpendingResponse: Decodable {
    let transactions: [TopSpendingTransaction]
}

struct TopSpendingTransaction: Decodable, Identifiable {
    let id: String
    let date: String
    let payee: String
    let categoryId: String
    let categoryName: String
    let accountId: String
    let accountName: String
    let subAccountId: String?
    let subAccountName: String?
    let amount: Double
    let currencyCode: String
}

// MARK: - Dashboard composite (built in AnalyticsService from multiple calls)
struct DashboardStats {
    var netWorth: Double = 0
    var totalAssets: Double = 0
    var totalLiabilities: Double = 0
    var income: Double = 0
    var expenses: Double = 0
    var savingsRate: Double = 0
    var currencyCode: String = "USD"

    var totalIncome: Double { income }
    var totalExpenses: Double { expenses }
}

// Legacy aliases kept for view compatibility
typealias DashboardStatsResponse = DashboardStats
typealias MonthlyCashFlowEntry = MonthlyPeriodEntry
typealias TopSpendingTransactionEntry = TopSpendingTransaction

// Net Worth overview alias
struct NetWorthOverviewResponse {
    var netWorth: Double
    var totalAssets: Double
    var totalLiabilities: Double
}

struct AssetAllocationEntry: Decodable, Identifiable {
    let label: String
    let value: Double
    let percentage: Double
    var id: String { label }
}

struct InvestmentHoldingEntry: Decodable, Identifiable {
    let symbol: String
    let name: String
    let type: String
    let totalAmount: Double
    let unrealizedPnLPercent: Double?
    var id: String { symbol }
}

struct NetWorthBreakdownEntry: Identifiable {
    let accountId: String
    let accountName: String
    let totalValue: Double
    var id: String { accountId }
}

struct CashFlowOverviewResponse {
    var netSavings: Double = 0
    var totalIncome: Double = 0
    var totalExpenses: Double = 0
    var expenseRatio: Double = 0
}

struct AnalyticsFilters {
    var fromDate: String?
    var toDate: String?
    var currencyCode: String = "USD"
}
