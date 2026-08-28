import Foundation

struct AnalyticsService {
    static let shared = AnalyticsService()
    private init() {}

    // MARK: Dashboard
    func getDashboardStats(currencyCode: String) async throws -> DashboardStatsResponse {
        try await APIClient.shared.get("/api/analytics/dashboard", params: ["currencyCode": currencyCode])
    }

    func getBalanceHistory(currencyCode: String) async throws -> [BalanceHistoryEntry] {
        try await APIClient.shared.get("/api/analytics/balance-history", params: ["currencyCode": currencyCode])
    }

    func getExpenseByCategory(filters: AnalyticsFilters) async throws -> [CategoryBreakdownEntry] {
        try await APIClient.shared.get("/api/analytics/expenses-by-category", params: filters.toQueryParams())
    }

    // MARK: Cash Flow
    func getCashFlowOverview(filters: AnalyticsFilters) async throws -> CashFlowOverviewResponse {
        try await APIClient.shared.get("/api/analytics/cashflow-overview", params: filters.toQueryParams())
    }

    func getMonthlyCashFlow(filters: AnalyticsFilters) async throws -> [MonthlyCashFlowEntry] {
        try await APIClient.shared.get("/api/analytics/monthly-cashflow", params: filters.toQueryParams())
    }

    func getIncomeByCategory(filters: AnalyticsFilters) async throws -> [CategoryBreakdownEntry] {
        try await APIClient.shared.get("/api/analytics/income-by-category", params: filters.toQueryParams())
    }

    func getTopSpending(filters: AnalyticsFilters) async throws -> [TopSpendingTransactionEntry] {
        try await APIClient.shared.get("/api/analytics/top-spending", params: filters.toQueryParams())
    }

    // MARK: Net Worth
    func getNetWorthOverview(currencyCode: String) async throws -> NetWorthOverviewResponse {
        try await APIClient.shared.get("/api/analytics/net-worth", params: ["currencyCode": currencyCode])
    }

    func getAssetAllocation(currencyCode: String) async throws -> [AssetAllocationEntry] {
        try await APIClient.shared.get("/api/analytics/asset-allocation", params: ["currencyCode": currencyCode])
    }

    func getInvestmentHoldings(currencyCode: String) async throws -> [InvestmentHoldingEntry] {
        try await APIClient.shared.get("/api/analytics/investment-holdings", params: ["currencyCode": currencyCode])
    }

    func getNetWorthBreakdown(currencyCode: String) async throws -> [NetWorthBreakdownEntry] {
        try await APIClient.shared.get("/api/analytics/net-worth-breakdown", params: ["currencyCode": currencyCode])
    }
}
