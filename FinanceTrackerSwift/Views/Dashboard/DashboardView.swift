import SwiftUI

@Observable
class DashboardViewModel {
    var stats: DashboardStatsResponse?
    var balanceHistory: [BalanceHistoryEntry] = []
    var expenseByCategory: [CategoryBreakdownEntry] = []
    var recentTransactions: [TransactionResponse] = []
    var accounts: [AccountResponse] = []
    var isLoading = false
    var isRefreshing = false
    var errorMessage: String?
    var currencyCode: String = "USD"

    func load(currencyCode: String, isManualRefresh: Bool = false) async {
        self.currencyCode = currencyCode
        if isManualRefresh {
            isRefreshing = true
        } else {
            isLoading = true
        }
        errorMessage = nil
        defer {
            isLoading = false
            isRefreshing = false
        }

        async let statsTask = AnalyticsService.shared.getDashboardStats(currencyCode: currencyCode)
        async let historyTask = AnalyticsService.shared.getBalanceHistory(currencyCode: currencyCode)
        async let categoryTask = AnalyticsService.shared.getExpenseByCategory(
            filters: AnalyticsFilters(currencyCode: currencyCode))
        async let transactionsTask = TransactionService.shared.getRecentTransactions(limit: 5)
        async let accountsTask = AccountService.shared.getAccounts()

        stats = try? await statsTask
        balanceHistory = (try? await historyTask) ?? []
        expenseByCategory = (try? await categoryTask) ?? []
        recentTransactions = (try? await transactionsTask) ?? []
        accounts = (try? await accountsTask) ?? []
    }
}

struct DashboardView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(\.selectedTab) private var selectedTab
    @State private var viewModel = DashboardViewModel()
    @State private var showAddTransaction = false
    @State private var currencyCode: String = "USD"

    let availableCurrencies = ["USD", "EUR", "GBP", "UAH", "PLN", "JPY", "CAD", "CHF"]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                DashboardHeaderCard(
                    greeting: "Good \(timeOfDay), \(auth.currentUser?.firstName ?? "Trader")",
                    currencyCode: $currencyCode,
                    availableCurrencies: availableCurrencies,
                    isRefreshing: viewModel.isRefreshing,
                    onRefresh: {
                        Task { await viewModel.load(currencyCode: currencyCode, isManualRefresh: true) }
                    },
                    onAddTransaction: {
                        showAddTransaction = true
                    }
                )

                // Error message banner if any
                if let error = viewModel.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(error).font(.caption)
                    }
                    .foregroundColor(Color(hex: "f87171"))
                    .padding(12)
                    .background(Color(hex: "f87171").opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // Stats Overview (4 cards)
                if let stats = viewModel.stats {
                    DashboardStatsOverviewView(stats: stats)
                } else if viewModel.isLoading {
                    ProgressView()
                        .tint(Color(hex: "a78bfa"))
                        .padding(.vertical, 30)
                }

                // Balance History Chart
                BalanceHistoryChartView(entries: viewModel.balanceHistory, currencyCode: currencyCode)

                // Accounts & Sub-Accounts Widget
                DashboardAccountsWidgetView(
                    accounts: viewModel.accounts,
                    onSeeAll: {
                        selectedTab.wrappedValue = .accounts
                    }
                )

                // Expense by Category Donut Chart
                ExpenseCategoryChartView(entries: viewModel.expenseByCategory, currencyCode: currencyCode)

                // Recent Transactions Widget
                RecentTransactionsView(
                    transactions: viewModel.recentTransactions,
                    currencyCode: currencyCode,
                    onViewAll: {
                        selectedTab.wrappedValue = .transactions
                    }
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(hex: "0d1117").ignoresSafeArea())
        .navigationTitle("Dashboard")
        .refreshable {
            await viewModel.load(currencyCode: currencyCode, isManualRefresh: true)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddTransaction = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(LinearGradient(colors: [Color(hex: "818cf8"), Color(hex: "a78bfa")],
                                                        startPoint: .leading, endPoint: .trailing))
                        .font(.title3)
                }
            }
        }
        .sheet(isPresented: $showAddTransaction, onDismiss: {
            Task { await viewModel.load(currencyCode: currencyCode) }
        }) {
            AddTransactionView(onSuccess: {})
        }
        .task {
            let code = auth.currentUser?.defaultCurrencyCode ?? "USD"
            currencyCode = code
            await viewModel.load(currencyCode: code)
        }
        .onChange(of: currencyCode) { _, new in
            Task { await viewModel.load(currencyCode: new) }
        }
    }

    private var timeOfDay: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "morning"
        case 12..<17: return "afternoon"
        case 17..<21: return "evening"
        default: return "night"
        }
    }
}

// MARK: - Dashboard Header Card
struct DashboardHeaderCard: View {
    let greeting: String
    @Binding var currencyCode: String
    let availableCurrencies: [String]
    let isRefreshing: Bool
    let onRefresh: () -> Void
    let onAddTransaction: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text(greeting)
                    .font(.headline.weight(.bold))
                    .foregroundColor(.white)
                Text("Overview of your financial performance")
                    .font(.caption)
                    .foregroundColor(Color.white.opacity(0.5))
            }

            Spacer()

            HStack(spacing: 8) {
                // Currency Selector Menu
                Menu {
                    ForEach(availableCurrencies, id: \.self) { c in
                        Button {
                            currencyCode = c
                        } label: {
                            HStack {
                                Text(c)
                                if currencyCode == c {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(currencyCode)
                            .font(.caption.weight(.bold))
                            .foregroundColor(.white)
                            .fixedSize()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color(hex: "a78bfa"))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // Refresh button
                Button {
                    onRefresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption.weight(.bold))
                        .foregroundColor(Color(hex: "a78bfa"))
                        .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                        .animation(isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                        .padding(8)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .disabled(isRefreshing)

                // Add Transaction button
                Button {
                    onAddTransaction()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.caption.weight(.bold))
                        Text("Add")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(LinearGradient(colors: [Color(hex: "818cf8"), Color(hex: "a78bfa")],
                                               startPoint: .leading, endPoint: .trailing))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Dashboard Stats Overview (4 Cards matching React)
struct DashboardStatsOverviewView: View {
    let stats: DashboardStatsResponse

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            // Net Worth
            DashboardStatCard(
                title: "Net Worth",
                valueText: stats.netWorth.formatted(currencyCode: stats.currencyCode),
                subtitleLabel: "Assets: \(stats.totalAssets.formatted(currencyCode: stats.currencyCode))",
                subtitleColor: Color(hex: "34d399"),
                iconName: "wallet.pass.fill",
                accentColor: Color(hex: "818cf8")
            )

            // Monthly Income
            DashboardStatCard(
                title: "Monthly Income",
                valueText: stats.income.formatted(currencyCode: stats.currencyCode),
                valueColor: Color(hex: "34d399"),
                subtitleLabel: "Earnings this month",
                subtitleColor: Color.white.opacity(0.4),
                iconName: "arrow.up.right.circle.fill",
                accentColor: Color(hex: "34d399")
            )

            // Monthly Expenses
            DashboardStatCard(
                title: "Monthly Expenses",
                valueText: stats.expenses.formatted(currencyCode: stats.currencyCode),
                valueColor: Color(hex: "f87171"),
                subtitleLabel: "Spending this month",
                subtitleColor: Color.white.opacity(0.4),
                iconName: "arrow.down.right.circle.fill",
                accentColor: Color(hex: "f87171")
            )

            // Savings Rate
            DashboardStatCard(
                title: "Savings Rate",
                valueText: String(format: "%.1f%%", stats.savingsRate),
                valueColor: Color(hex: "a78bfa"),
                subtitleLabel: "Net: \((stats.income - stats.expenses).formatted(currencyCode: stats.currencyCode))",
                subtitleColor: Color.white.opacity(0.5),
                iconName: "percent",
                accentColor: Color(hex: "a78bfa")
            )
        }
    }
}

struct DashboardStatCard: View {
    let title: String
    let valueText: String
    var valueColor: Color = .white
    let subtitleLabel: String
    var subtitleColor: Color = Color.white.opacity(0.5)
    let iconName: String
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundColor(Color.white.opacity(0.6))
                Spacer()
                Image(systemName: iconName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(accentColor)
            }

            Text(valueText)
                .font(.title3.bold())
                .foregroundColor(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(subtitleLabel)
                .font(.caption2)
                .foregroundColor(subtitleColor)
                .lineLimit(1)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(accentColor.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Dashboard Accounts Widget
struct DashboardAccountsWidgetView: View {
    let accounts: [AccountResponse]
    var onSeeAll: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Text("Your Accounts")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                Spacer()
                Button {
                    onSeeAll()
                } label: {
                    HStack(spacing: 4) {
                        Text("See All")
                            .font(.caption.weight(.semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(Color(hex: "a78bfa"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(hex: "a78bfa").opacity(0.12))
                    .clipShape(Capsule())
                }
            }

            if accounts.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "building.columns")
                        .font(.system(size: 32))
                        .foregroundColor(Color.white.opacity(0.2))
                    Text("No accounts added yet")
                        .font(.subheadline)
                        .foregroundColor(Color.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
            } else {
                VStack(spacing: 10) {
                    ForEach(accounts.prefix(4)) { account in
                        VStack(spacing: 8) {
                            // Main account row
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(Color(hex: account.color ?? "818cf8").opacity(0.2))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Image(systemName: account.type.icon)
                                            .font(.caption.bold())
                                            .foregroundColor(Color(hex: account.color ?? "818cf8"))
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(account.name)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.white)
                                    Text(account.type.displayName)
                                        .font(.caption2)
                                        .foregroundColor(Color.white.opacity(0.4))
                                }

                                Spacer()

                                Text(account.totalValue.formatted(currencyCode: account.currencyCode))
                                    .font(.subheadline.weight(.bold))
                                    .foregroundColor(.white)
                            }

                            // Sub-accounts preview
                            if !account.subAccountsList.isEmpty {
                                VStack(spacing: 4) {
                                    ForEach(account.subAccountsList.prefix(2)) { sub in
                                        HStack {
                                            Text(sub.name)
                                                .font(.caption2)
                                                .foregroundColor(Color.white.opacity(0.6))
                                            Spacer()
                                            Text(sub.totalValue.formatted(currencyCode: sub.currencyCode))
                                                .font(.caption2.weight(.medium))
                                                .foregroundColor(Color.white.opacity(0.8))
                                        }
                                        .padding(.leading, 46)
                                    }
                                }
                                .padding(.top, 2)
                            }
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.03))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.05), lineWidth: 1))
                    }
                }
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}
