import Foundation

struct AnalyticsService {
    static let shared = AnalyticsService()
    private init() {}

    // MARK: - Balance History
    func getBalanceHistory(currencyCode: String) async throws -> [BalanceHistoryEntry] {
        try await APIClient.shared.get("/api/analytics/balance-history",
                                      params: ["currencyCode": currencyCode])
    }

    // MARK: - Expense by Category
    func getExpenseByCategory(filters: AnalyticsFilters) async throws -> [CategoryBreakdownEntry] {
        var params: [String: String] = ["currencyCode": filters.currencyCode]
        if let from = filters.fromDate { params["fromDate"] = from }
        if let to = filters.toDate { params["toDate"] = to }
        if let acc = filters.accountId, !acc.isEmpty { params["accountId"] = acc }
        let response: CategoryBreakdownResponse = try await APIClient.shared.get(
            "/api/analytics/expense-by-category", params: params)
        return response.items
    }

    // MARK: - Income by Category
    func getIncomeByCategory(filters: AnalyticsFilters) async throws -> [CategoryBreakdownEntry] {
        var params: [String: String] = ["currencyCode": filters.currencyCode]
        if let from = filters.fromDate { params["fromDate"] = from }
        if let to = filters.toDate { params["toDate"] = to }
        if let acc = filters.accountId, !acc.isEmpty { params["accountId"] = acc }
        let response: CategoryBreakdownResponse = try await APIClient.shared.get(
            "/api/analytics/income-by-category", params: params)
        return response.items
    }

    // MARK: - Monthly Income vs Expense
    func getMonthlyPeriods(filters: AnalyticsFilters) async throws -> [MonthlyPeriodEntry] {
        var params: [String: String] = ["currencyCode": filters.currencyCode]
        if let from = filters.fromDate { params["fromDate"] = from }
        if let to = filters.toDate { params["toDate"] = to }
        if let acc = filters.accountId, !acc.isEmpty { params["accountId"] = acc }
        return try await APIClient.shared.get("/api/analytics/income-vs-expense", params: params)
    }

    // MARK: - Net Worth
    func getNetWorth(currencyCode: String) async throws -> NetWorthResponse {
        try await APIClient.shared.get("/api/analytics/net-worth",
                                      params: ["currencyCode": currencyCode])
    }

    // MARK: - Top Spending
    func getTopSpending(filters: AnalyticsFilters) async throws -> [TopSpendingTransaction] {
        var params: [String: String] = ["currencyCode": filters.currencyCode]
        if let from = filters.fromDate { params["fromDate"] = from }
        if let to = filters.toDate { params["toDate"] = to }
        if let acc = filters.accountId, !acc.isEmpty { params["accountId"] = acc }
        let response: TopSpendingResponse = try await APIClient.shared.get(
            "/api/analytics/top-spending", params: params)
        return response.transactions
    }

    // MARK: - Dashboard composite (combine net-worth + monthly periods)
    func getDashboardStats(currencyCode: String) async throws -> DashboardStats {
        async let nwTask = getNetWorth(currencyCode: currencyCode)
        async let periodsTask = getMonthlyPeriods(filters: AnalyticsFilters(currencyCode: currencyCode))
        let nw = try? await nwTask
        let periods = (try? await periodsTask) ?? []

        let latest = periods.last
        return DashboardStats(
            netWorth: nw?.netWorth ?? 0,
            totalAssets: nw?.totalAssets ?? 0,
            totalLiabilities: nw?.totalLiabilities ?? 0,
            income: latest?.income ?? 0,
            expenses: latest?.expense ?? 0,
            savingsRate: latest?.savingsRate ?? 0,
            currencyCode: currencyCode
        )
    }

    // MARK: - Compat shims used by AnalyticsView ViewModel
    func getCashFlowOverview(filters: AnalyticsFilters) async throws -> CashFlowOverviewResponse {
        let periods = (try? await getMonthlyPeriods(filters: filters)) ?? []
        let totalIncome = periods.reduce(0) { $0 + $1.income }
        let totalExpenses = periods.reduce(0) { $0 + $1.expense }
        let ratio = totalIncome > 0 ? (totalExpenses / totalIncome) * 100 : 0
        return CashFlowOverviewResponse(
            netSavings: totalIncome - totalExpenses,
            totalIncome: totalIncome,
            totalExpenses: totalExpenses,
            expenseRatio: ratio
        )
    }

    func getMonthlyCashFlow(filters: AnalyticsFilters) async throws -> [MonthlyPeriodEntry] {
        (try? await getMonthlyPeriods(filters: filters)) ?? []
    }

    func getNetWorthOverview(currencyCode: String) async throws -> NetWorthOverviewResponse {
        let nw = try await getNetWorth(currencyCode: currencyCode)
        return NetWorthOverviewResponse(
            netWorth: nw.netWorth,
            totalAssets: nw.totalAssets,
            totalLiabilities: nw.totalLiabilities
        )
    }

    func getAssetAllocation(currencyCode: String) async throws -> [AssetAllocationEntry] {
        guard let nw = try? await getNetWorth(currencyCode: currencyCode) else { return [] }
        guard nw.totalAssets > 0 else { return [] }
        return nw.accountBreakdown.filter { $0.value > 0 }.map { acc in
            AssetAllocationEntry(
                label: acc.accountName,
                value: acc.value,
                percentage: (acc.value / nw.totalAssets) * 100
            )
        }
    }

    func getInvestmentHoldings(currencyCode: String) async throws -> [InvestmentHoldingEntry] {
        return []
    }

    func getNetWorthBreakdown(currencyCode: String) async throws -> [NetWorthBreakdownEntry] {
        guard let nw = try? await getNetWorth(currencyCode: currencyCode) else { return [] }
        return nw.accountBreakdown.map { acc in
            NetWorthBreakdownEntry(
                accountId: acc.accountId,
                accountName: acc.accountName,
                totalValue: acc.value
            )
        }
    }
}
