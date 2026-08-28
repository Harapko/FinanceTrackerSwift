import SwiftUI

@Observable
class DashboardViewModel {
    var stats: DashboardStatsResponse?
    var balanceHistory: [BalanceHistoryEntry] = []
    var expenseByCategory: [CategoryBreakdownEntry] = []
    var recentTransactions: [TransactionResponse] = []
    var accounts: [AccountResponse] = []
    var isLoading = false
    var errorMessage: String?
    var currencyCode: String = "USD"

    func load(currencyCode: String) async {
        self.currencyCode = currencyCode
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            async let statsTask = AnalyticsService.shared.getDashboardStats(currencyCode: currencyCode)
            async let historyTask = AnalyticsService.shared.getBalanceHistory(currencyCode: currencyCode)
            async let categoryTask = AnalyticsService.shared.getExpenseByCategory(
                filters: AnalyticsFilters(currencyCode: currencyCode))
            async let transactionsTask = TransactionService.shared.getRecentTransactions(limit: 5)
            async let accountsTask = AccountService.shared.getAccounts()

            let (s, h, c, t, a) = try await (statsTask, historyTask, categoryTask, transactionsTask, accountsTask)
            stats = s
            balanceHistory = h
            expenseByCategory = c
            recentTransactions = t
            accounts = a
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct DashboardView: View {
    @Environment(AuthManager.self) private var auth
    @State private var viewModel = DashboardViewModel()
    @State private var showAddTransaction = false
    @State private var currencyCode: String = "USD"

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header greeting
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Good \(timeOfDay),")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "a78bfa"))
                        Text(auth.currentUser?.firstName ?? "Trader")
                            .font(.title.bold())
                            .foregroundColor(.white)
                    }
                    Spacer()
                    HStack(spacing: 12) {
                        // Currency picker
                        Picker("Currency", selection: $currencyCode) {
                            ForEach(["USD", "EUR", "GBP", "UAH", "PLN"], id: \.self) { c in
                                Text(c).tag(c)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .foregroundColor(.white)

                        Button {
                            Task { await viewModel.load(currencyCode: currencyCode) }
                        } label: {
                            Image(systemName: viewModel.isLoading ? "arrow.clockwise" : "arrow.clockwise")
                                .foregroundColor(Color(hex: "a78bfa"))
                                .padding(8)
                                .background(Color.white.opacity(0.08))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.horizontal, 4)

                // Stats Overview
                if let stats = viewModel.stats {
                    StatsOverviewView(stats: stats)
                } else if viewModel.isLoading {
                    ProgressView().tint(Color(hex: "a78bfa"))
                        .padding(.vertical, 40)
                }

                // Balance History Chart
                if !viewModel.balanceHistory.isEmpty {
                    BalanceHistoryChartView(entries: viewModel.balanceHistory, currencyCode: currencyCode)
                }

                // Accounts
                if !viewModel.accounts.isEmpty {
                    AccountsWidgetView(accounts: viewModel.accounts)
                }

                // Expense by Category
                if !viewModel.expenseByCategory.isEmpty {
                    ExpenseCategoryChartView(entries: viewModel.expenseByCategory, currencyCode: currencyCode)
                }

                // Recent Transactions
                if !viewModel.recentTransactions.isEmpty {
                    RecentTransactionsView(transactions: viewModel.recentTransactions, currencyCode: currencyCode)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(hex: "0d1117").ignoresSafeArea())
        .navigationTitle("Dashboard")
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
        .sheet(isPresented: $showAddTransaction) {
            AddTransactionView {
                Task { await viewModel.load(currencyCode: currencyCode) }
            }
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

// MARK: - Stats Overview
struct StatsOverviewView: View {
    let stats: DashboardStatsResponse

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(title: "Net Worth", value: stats.netWorth, currency: stats.currencyCode,
                     icon: "arrow.up.arrow.down.circle.fill", color: Color(hex: "818cf8"))
            StatCard(title: "Income", value: stats.totalIncome, currency: stats.currencyCode,
                     icon: "arrow.down.circle.fill", color: Color(hex: "34d399"))
            StatCard(title: "Expenses", value: stats.totalExpenses, currency: stats.currencyCode,
                     icon: "arrow.up.circle.fill", color: Color(hex: "f87171"))
            StatCard(title: "Savings Rate", value: stats.savingsRate, currency: nil,
                     icon: "percent", color: Color(hex: "fbbf24"), isPercent: true)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: Double
    let currency: String?
    let icon: String
    let color: Color
    var isPercent: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Spacer()
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(Color.white.opacity(0.6))
                if isPercent {
                    Text(String(format: "%.1f%%", value))
                        .font(.title3.bold())
                        .foregroundColor(.white)
                } else if let currency = currency {
                    Text(value.formatted(currencyCode: currency))
                        .font(.title3.bold())
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.3), lineWidth: 1))
    }
}

// MARK: - Accounts Widget
struct AccountsWidgetView: View {
    let accounts: [AccountResponse]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Accounts")
                .font(.headline.bold())
                .foregroundColor(.white)

            ForEach(accounts.prefix(4)) { account in
                HStack {
                    Circle()
                        .fill(Color(hex: account.color ?? "818cf8"))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: account.type.icon)
                                .font(.caption.bold())
                                .foregroundColor(.white)
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(account.name).font(.subheadline.weight(.semibold)).foregroundColor(.white)
                        Text(account.type.displayName).font(.caption).foregroundColor(Color.white.opacity(0.5))
                    }
                    Spacer()
                    Text(account.totalValue.formatted(currencyCode: account.currencyCode))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                }
                .padding(12)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
