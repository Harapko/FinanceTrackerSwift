import SwiftUI
import Charts

enum AnalyticsTab: String, CaseIterable {
    case cashflow = "Cash Flow"
    case networth = "Net Worth"
}

@Observable
class AnalyticsViewModel {
    // Cash Flow
    var cashFlowOverview: CashFlowOverviewResponse?
    var monthlyCashFlow: [MonthlyCashFlowEntry] = []
    var expenseByCategory: [CategoryBreakdownEntry] = []
    var incomeByCategory: [CategoryBreakdownEntry] = []
    var topSpending: [TopSpendingTransactionEntry] = []

    // Net Worth
    var netWorthOverview: NetWorthOverviewResponse?
    var assetAllocation: [AssetAllocationEntry] = []
    var investmentHoldings: [InvestmentHoldingEntry] = []
    var netWorthBreakdown: [NetWorthBreakdownEntry] = []

    var isLoading = false
    var errorMessage: String?

    func loadCashFlow(filters: AnalyticsFilters) async {
        isLoading = true; defer { isLoading = false }
        do {
            async let overview = AnalyticsService.shared.getCashFlowOverview(filters: filters)
            async let monthly = AnalyticsService.shared.getMonthlyCashFlow(filters: filters)
            async let expCat = AnalyticsService.shared.getExpenseByCategory(filters: filters)
            async let incCat = AnalyticsService.shared.getIncomeByCategory(filters: filters)
            async let top = AnalyticsService.shared.getTopSpending(filters: filters)
            let (o, m, e, i, t) = try await (overview, monthly, expCat, incCat, top)
            cashFlowOverview = o; monthlyCashFlow = m; expenseByCategory = e; incomeByCategory = i; topSpending = t
        } catch { errorMessage = error.localizedDescription }
    }

    func loadNetWorth(currencyCode: String) async {
        isLoading = true; defer { isLoading = false }
        do {
            async let nw = AnalyticsService.shared.getNetWorthOverview(currencyCode: currencyCode)
            async let alloc = AnalyticsService.shared.getAssetAllocation(currencyCode: currencyCode)
            async let hold = AnalyticsService.shared.getInvestmentHoldings(currencyCode: currencyCode)
            async let breakdown = AnalyticsService.shared.getNetWorthBreakdown(currencyCode: currencyCode)
            let (n, a, h, b) = try await (nw, alloc, hold, breakdown)
            netWorthOverview = n; assetAllocation = a; investmentHoldings = h; netWorthBreakdown = b
        } catch { errorMessage = error.localizedDescription }
    }
}

struct AnalyticsView: View {
    @Environment(AuthManager.self) private var auth
    @State private var viewModel = AnalyticsViewModel()
    @State private var activeTab: AnalyticsTab = .cashflow
    @State private var currencyCode = "USD"
    @State private var fromDate = ""
    @State private var toDate = ""

    var filters: AnalyticsFilters {
        AnalyticsFilters(fromDate: fromDate.isEmpty ? nil : fromDate,
                         toDate: toDate.isEmpty ? nil : toDate,
                         currencyCode: currencyCode)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 12) {
                    HStack {
                        Text("Analytics")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                        Spacer()
                        Menu {
                            ForEach(["USD", "EUR", "GBP", "UAH", "PLN"], id: \.self) { c in
                                Button(c) { currencyCode = c }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(currencyCode)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.white)
                                    .fixedSize()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption2)
                                    .foregroundColor(Color(hex: "a78bfa"))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }

                    // Date filters
                    HStack(spacing: 10) {
                        HStack {
                            Text("From:").font(.caption).foregroundColor(Color.white.opacity(0.5))
                            TextField("YYYY-MM-DD", text: $fromDate)
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .padding(10)
                        .background(Color.white.opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                        HStack {
                            Text("To:").font(.caption).foregroundColor(Color.white.opacity(0.5))
                            TextField("YYYY-MM-DD", text: $toDate)
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .padding(10)
                        .background(Color.white.opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                        Button("Apply") { reload() }
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color(hex: "818cf8"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.horizontal, 4)

                // Tab selector
                HStack(spacing: 0) {
                    ForEach(AnalyticsTab.allCases, id: \.self) { tab in
                        Button {
                            activeTab = tab
                            reload()
                        } label: {
                            Text(tab.rawValue)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(activeTab == tab ? .white : Color.white.opacity(0.4))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    activeTab == tab ?
                                        LinearGradient(colors: [Color(hex: "818cf8"), Color(hex: "a78bfa")],
                                                       startPoint: .leading, endPoint: .trailing) :
                                        LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing)
                                )
                        }
                    }
                }
                .background(Color.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                if viewModel.isLoading {
                    ProgressView().tint(Color(hex: "a78bfa")).padding(.vertical, 40)
                } else if activeTab == .cashflow {
                    CashFlowTabView(viewModel: viewModel, currencyCode: currencyCode)
                } else {
                    NetWorthTabView(viewModel: viewModel, currencyCode: currencyCode)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(hex: "0d1117").ignoresSafeArea())
        .task {
            currencyCode = auth.currentUser?.defaultCurrencyCode ?? "USD"
            reload()
        }
        .onChange(of: currencyCode) { _, _ in reload() }
    }

    private func reload() {
        Task {
            if activeTab == .cashflow {
                await viewModel.loadCashFlow(filters: filters)
            } else {
                await viewModel.loadNetWorth(currencyCode: currencyCode)
            }
        }
    }
}

// MARK: - Cash Flow Tab
struct CashFlowTabView: View {
    let viewModel: AnalyticsViewModel
    let currencyCode: String

    var body: some View {
        VStack(spacing: 16) {
            // Overview cards
            if let overview = viewModel.cashFlowOverview {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatCard(title: "Net Savings", value: overview.netSavings, currency: currencyCode,
                             icon: "arrow.up.right.circle.fill", color: Color(hex: "818cf8"))
                    StatCard(title: "Income", value: overview.totalIncome, currency: currencyCode,
                             icon: "arrow.down.circle.fill", color: Color(hex: "34d399"))
                    StatCard(title: "Expenses", value: overview.totalExpenses, currency: currencyCode,
                             icon: "arrow.up.circle.fill", color: Color(hex: "f87171"))
                    StatCard(title: "Expense Ratio", value: overview.expenseRatio, currency: nil,
                             icon: "percent", color: Color(hex: "fbbf24"), isPercent: true)
                }
            }

            // Monthly cash flow chart
            if !viewModel.monthlyCashFlow.isEmpty {
                CashFlowTimelineView(entries: viewModel.monthlyCashFlow)
            }

            // Category breakdowns side by side
            HStack(alignment: .top, spacing: 12) {
                if !viewModel.expenseByCategory.isEmpty {
                    MiniCategoryPie(title: "Expenses", entries: viewModel.expenseByCategory, currencyCode: currencyCode)
                }
                if !viewModel.incomeByCategory.isEmpty {
                    MiniCategoryPie(title: "Income", entries: viewModel.incomeByCategory, currencyCode: currencyCode)
                }
            }

            // Top spending
            if !viewModel.topSpending.isEmpty {
                TopSpendingView(entries: viewModel.topSpending, currencyCode: currencyCode)
            }
        }
    }
}

// MARK: - Net Worth Tab
struct NetWorthTabView: View {
    let viewModel: AnalyticsViewModel
    let currencyCode: String

    var body: some View {
        VStack(spacing: 16) {
            if let nw = viewModel.netWorthOverview {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatCard(title: "Net Worth", value: nw.netWorth, currency: currencyCode,
                             icon: "chart.bar.fill", color: Color(hex: "818cf8"))
                    StatCard(title: "Total Assets", value: nw.totalAssets, currency: currencyCode,
                             icon: "arrow.up.circle.fill", color: Color(hex: "34d399"))
                    StatCard(title: "Liabilities", value: nw.totalLiabilities, currency: currencyCode,
                             icon: "arrow.down.circle.fill", color: Color(hex: "f87171"))
                }
            }

            if !viewModel.assetAllocation.isEmpty {
                AssetAllocationView(entries: viewModel.assetAllocation, currencyCode: currencyCode)
            }

            if !viewModel.investmentHoldings.isEmpty {
                InvestmentHoldingsView(entries: viewModel.investmentHoldings, currencyCode: currencyCode)
            }

            if !viewModel.netWorthBreakdown.isEmpty {
                NetWorthBreakdownView(entries: viewModel.netWorthBreakdown, currencyCode: currencyCode)
            }
        }
    }
}

// MARK: - Cash Flow Timeline Chart
struct CashFlowTimelineView: View {
    let entries: [MonthlyCashFlowEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cash Flow Timeline")
                .font(.headline.bold())
                .foregroundColor(.white)

            Chart {
                ForEach(entries) { entry in
                    BarMark(x: .value("Month", entry.monthLabel),
                            y: .value("Income", entry.income))
                        .foregroundStyle(Color(hex: "34d399"))
                        .position(by: .value("Type", "Income"))
                    BarMark(x: .value("Month", entry.monthLabel),
                            y: .value("Expenses", entry.expenses))
                        .foregroundStyle(Color(hex: "f87171"))
                        .position(by: .value("Type", "Expenses"))
                    LineMark(x: .value("Month", entry.monthLabel),
                             y: .value("Net", entry.netSavings))
                        .foregroundStyle(Color(hex: "818cf8"))
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel().foregroundStyle(Color.white.opacity(0.5)).font(.caption2)
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3)).foregroundStyle(Color.white.opacity(0.1))
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel().foregroundStyle(Color.white.opacity(0.5)).font(.caption2)
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3)).foregroundStyle(Color.white.opacity(0.1))
                }
            }
            .frame(height: 200)
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - Mini Category Pie
struct MiniCategoryPie: View {
    let title: String
    let entries: [CategoryBreakdownEntry]
    let currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.subheadline.bold()).foregroundColor(.white)
            Chart {
                ForEach(Array(entries.prefix(6).enumerated()), id: \.element.id) { idx, entry in
                    SectorMark(angle: .value("Amount", entry.total), innerRadius: .ratio(0.5), angularInset: 1.5)
                        .foregroundStyle(categoryColors[idx % categoryColors.count])
                        .cornerRadius(3)
                }
            }
            .frame(height: 100)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(entries.prefix(3).enumerated()), id: \.element.id) { idx, entry in
                    HStack(spacing: 6) {
                        Circle().fill(categoryColors[idx % categoryColors.count]).frame(width: 7, height: 7)
                        Text(entry.categoryName).font(.caption2).foregroundColor(Color.white.opacity(0.7)).lineLimit(1)
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Top Spending
struct TopSpendingView: View {
    let entries: [TopSpendingTransactionEntry]
    let currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Spending").font(.headline.bold()).foregroundColor(.white)
            ForEach(entries.prefix(5)) { entry in
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(entry.payee.isEmpty ? entry.categoryName : entry.payee)
                            .font(.subheadline.weight(.semibold)).foregroundColor(.white).lineLimit(1)
                        Text(entry.categoryName).font(.caption).foregroundColor(Color.white.opacity(0.5))
                    }
                    Spacer()
                    Text(entry.amount.formatted(currencyCode: entry.currencyCode))
                        .font(.subheadline.bold()).foregroundColor(Color(hex: "f87171"))
                }
                .padding(.vertical, 6)
                if entry.id != entries.prefix(5).last?.id {
                    Divider().background(Color.white.opacity(0.06))
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - Asset Allocation
struct AssetAllocationView: View {
    let entries: [AssetAllocationEntry]
    let currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Asset Allocation").font(.headline.bold()).foregroundColor(.white)
            HStack(alignment: .center, spacing: 20) {
                Chart {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { idx, entry in
                        SectorMark(angle: .value("Value", entry.value), innerRadius: .ratio(0.55), angularInset: 2)
                            .foregroundStyle(categoryColors[idx % categoryColors.count])
                            .cornerRadius(4)
                    }
                }
                .frame(width: 120, height: 120)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { idx, entry in
                        HStack(spacing: 8) {
                            Circle().fill(categoryColors[idx % categoryColors.count]).frame(width: 8, height: 8)
                            Text(entry.label).font(.caption).foregroundColor(Color.white.opacity(0.8))
                            Spacer()
                            Text(String(format: "%.1f%%", entry.percentage))
                                .font(.caption2).foregroundColor(Color.white.opacity(0.5))
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - Investment Holdings
struct InvestmentHoldingsView: View {
    let entries: [InvestmentHoldingEntry]
    let currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Investment Holdings").font(.headline.bold()).foregroundColor(.white)
            ForEach(entries) { entry in
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(entry.symbol).font(.subheadline.bold()).foregroundColor(.white)
                            Text(entry.type).font(.caption)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color(hex: "818cf8").opacity(0.2))
                                .foregroundColor(Color(hex: "818cf8"))
                                .clipShape(Capsule())
                        }
                        Text(entry.name).font(.caption).foregroundColor(Color.white.opacity(0.5)).lineLimit(1)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(entry.totalAmount.formatted(currencyCode: currencyCode))
                            .font(.subheadline.bold()).foregroundColor(.white)
                        if let pnl = entry.unrealizedPnLPercent {
                            Text(String(format: "%+.2f%%", pnl))
                                .font(.caption)
                                .foregroundColor(pnl >= 0 ? Color(hex: "34d399") : Color(hex: "f87171"))
                        }
                    }
                }
                .padding(.vertical, 6)
                if entry.id != entries.last?.id {
                    Divider().background(Color.white.opacity(0.06))
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - Net Worth Breakdown
struct NetWorthBreakdownView: View {
    let entries: [NetWorthBreakdownEntry]
    let currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Account Breakdown").font(.headline.bold()).foregroundColor(.white)
            ForEach(Array(entries.enumerated()), id: \.element.id) { idx, entry in
                HStack {
                    Circle().fill(categoryColors[idx % categoryColors.count]).frame(width: 10, height: 10)
                    Text(entry.accountName).font(.subheadline).foregroundColor(.white)
                    Spacer()
                    Text(entry.totalValue.formatted(currencyCode: currencyCode))
                        .font(.subheadline.bold()).foregroundColor(.white)
                }
                .padding(.vertical, 4)
                if entry.id != entries.last?.id {
                    Divider().background(Color.white.opacity(0.06))
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - Stat Card
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
