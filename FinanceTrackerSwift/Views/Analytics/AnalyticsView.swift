import SwiftUI
import Charts

enum AnalyticsTab: String, CaseIterable {
    case cashflow = "Cash Flow"
    case networth = "Net Worth"

    var displayName: String {
        switch self {
        case .cashflow: return L10n.Analytics.tabCashFlow
        case .networth: return L10n.Analytics.tabNetWorth
        }
    }
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
    @State private var showDateRangeSheet = false
    @State private var tempStartDate = Date()
    @State private var tempEndDate = Date()

    private var isoFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }

    private var displayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = LocalizationManager.shared.currentLocale
        formatter.dateStyle = .medium
        return formatter
    }

    var hasActiveDateFilter: Bool {
        !fromDate.isEmpty || !toDate.isEmpty
    }

    var dateRangeDisplayText: String {
        if fromDate.isEmpty && toDate.isEmpty {
            return L10n.Analytics.allTime
        }
        if !fromDate.isEmpty && !toDate.isEmpty {
            if fromDate == toDate {
                if let d = isoFormatter.date(from: fromDate) {
                    return displayFormatter.string(from: d)
                }
                return fromDate
            }
            let fromStr = isoFormatter.date(from: fromDate).map { displayFormatter.string(from: $0) } ?? fromDate
            let toStr = isoFormatter.date(from: toDate).map { displayFormatter.string(from: $0) } ?? toDate
            return "\(fromStr) — \(toStr)"
        }
        if !fromDate.isEmpty {
            let fromStr = isoFormatter.date(from: fromDate).map { displayFormatter.string(from: $0) } ?? fromDate
            return L10n.Analytics.fromFormatted(fromStr)
        }
        if !toDate.isEmpty {
            let toStr = isoFormatter.date(from: toDate).map { displayFormatter.string(from: $0) } ?? toDate
            return L10n.Analytics.untilFormatted(toStr)
        }
        return L10n.Analytics.selectDateRange
    }

    var filters: AnalyticsFilters {
        AnalyticsFilters(fromDate: fromDate.isEmpty ? nil : fromDate,
                         toDate: toDate.isEmpty ? nil : toDate,
                         currencyCode: currencyCode)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerSection
                tabSelectorSection

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
        .sheet(isPresented: $showDateRangeSheet) {
            dateRangeSheet
        }
        .task {
            currencyCode = auth.currentUser?.defaultCurrencyCode ?? "USD"
            reload()
        }
        .onChange(of: currencyCode) { _, _ in reload() }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text(L10n.Analytics.title)
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

            // Interactive Date Range Selector Pill
            Button {
                if let d1 = isoFormatter.date(from: fromDate) {
                    tempStartDate = d1
                } else {
                    tempStartDate = Date()
                }
                if let d2 = isoFormatter.date(from: toDate) {
                    tempEndDate = d2
                } else {
                    tempEndDate = Date()
                }
                showDateRangeSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.subheadline)
                        .foregroundColor(hasActiveDateFilter ? Color(hex: "818cf8") : Color.white.opacity(0.6))

                    Text(dateRangeDisplayText)
                        .font(.subheadline.weight(hasActiveDateFilter ? .semibold : .regular))
                        .foregroundColor(hasActiveDateFilter ? .white : Color.white.opacity(0.8))
                        .lineLimit(1)

                    Spacer()

                    if hasActiveDateFilter {
                        Button {
                            fromDate = ""
                            toDate = ""
                            reload()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(Color.white.opacity(0.5))
                        }
                        .buttonStyle(.plain)
                    }

                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .foregroundColor(Color.white.opacity(0.4))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(hasActiveDateFilter ? Color(hex: "818cf8").opacity(0.15) : Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(hasActiveDateFilter ? Color(hex: "818cf8").opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal, 4)
    }

    private var tabSelectorSection: some View {
        HStack(spacing: 0) {
            ForEach(AnalyticsTab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private func tabButton(for tab: AnalyticsTab) -> some View {
        let isSelected = activeTab == tab
        Button {
            activeTab = tab
            reload()
        } label: {
            Text(tab.displayName)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(isSelected ? .white : Color.white.opacity(0.4))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    isSelected ?
                        LinearGradient(colors: [Color(hex: "818cf8"), Color(hex: "a78bfa")],
                                       startPoint: .leading, endPoint: .trailing) :
                        LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing)
                )
        }
    }

    private func applyPreset(_ preset: String) {
        let calendar = Calendar.current
        let now = Date()

        switch preset {
        case "Today":
            tempStartDate = now
            tempEndDate = now
        case "Yesterday":
            if let y = calendar.date(byAdding: .day, value: -1, to: now) {
                tempStartDate = y
                tempEndDate = y
            }
        case "Last 7 Days":
            if let d = calendar.date(byAdding: .day, value: -6, to: now) {
                tempStartDate = d
                tempEndDate = now
            }
        case "Last 30 Days":
            if let d = calendar.date(byAdding: .day, value: -29, to: now) {
                tempStartDate = d
                tempEndDate = now
            }
        case "This Month":
            let comps = calendar.dateComponents([.year, .month], from: now)
            if let start = calendar.date(from: comps),
               let range = calendar.range(of: .day, in: .month, for: now),
               let end = calendar.date(byAdding: .day, value: range.count - 1, to: start) {
                tempStartDate = start
                tempEndDate = end
            }
        case "Last Month":
            if let prevMonth = calendar.date(byAdding: .month, value: -1, to: now) {
                let comps = calendar.dateComponents([.year, .month], from: prevMonth)
                if let start = calendar.date(from: comps),
                   let range = calendar.range(of: .day, in: .month, for: prevMonth),
                   let end = calendar.date(byAdding: .day, value: range.count - 1, to: start) {
                    tempStartDate = start
                    tempEndDate = end
                }
            }
        case "Last 90 Days":
            if let d = calendar.date(byAdding: .day, value: -89, to: now) {
                tempStartDate = d
                tempEndDate = now
            }
        case "This Year":
            let comps = calendar.dateComponents([.year], from: now)
            if let start = calendar.date(from: comps),
               let nextYear = calendar.date(byAdding: .year, value: 1, to: start),
               let end = calendar.date(byAdding: .day, value: -1, to: nextYear) {
                tempStartDate = start
                tempEndDate = end
            }
        case "Last Year":
            if let prevYear = calendar.date(byAdding: .year, value: -1, to: now) {
                let comps = calendar.dateComponents([.year], from: prevYear)
                if let start = calendar.date(from: comps),
                   let thisYearStart = calendar.date(byAdding: .year, value: 1, to: start),
                   let end = calendar.date(byAdding: .day, value: -1, to: thisYearStart) {
                    tempStartDate = start
                    tempEndDate = end
                }
            }
        default:
            break
        }
    }

    private var dateRangeSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Quick Presets
                    VStack(alignment: .leading, spacing: 10) {
                        Text(LocalizationManager.shared.isUkrainian ? "ШВИДКІ ПРЕСЕТИ" : "QUICK PRESETS")
                            .font(.caption.bold())
                            .foregroundColor(Color.white.opacity(0.5))

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(["This Month", "Last Month", "Last 30 Days", "Last 90 Days", "This Year", "Last Year", "Today"], id: \.self) { preset in
                                    Button {
                                        applyPreset(preset)
                                    } label: {
                                        Text(preset)
                                            .font(.caption.weight(.medium))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Color.white.opacity(0.1))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)

                    // Date Pickers
                    VStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(L10n.Transactions.fromDate)
                                .font(.caption.bold())
                                .foregroundColor(Color.white.opacity(0.6))
                            DatePicker(L10n.Transactions.fromDate, selection: $tempStartDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text(L10n.Transactions.toDate)
                                .font(.caption.bold())
                                .foregroundColor(Color.white.opacity(0.6))
                            DatePicker(L10n.Transactions.toDate, selection: $tempEndDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal)

                    // Actions
                    HStack(spacing: 12) {
                        Button {
                            fromDate = ""
                            toDate = ""
                            showDateRangeSheet = false
                            reload()
                        } label: {
                            Text("\(L10n.Transactions.resetAll) (\(L10n.Analytics.allTime))")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(Color.white.opacity(0.8))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Button {
                            fromDate = isoFormatter.string(from: tempStartDate)
                            toDate = isoFormatter.string(from: tempEndDate)
                            showDateRangeSheet = false
                            reload()
                        } label: {
                            Text(L10n.Transactions.applyFilters)
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(hex: "818cf8"))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
            .background(Color(hex: "0d1117").ignoresSafeArea())
            .navigationTitle(L10n.Analytics.selectDateRange)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.close) {
                        showDateRangeSheet = false
                    }
                    .foregroundColor(Color(hex: "a78bfa"))
                }
            }
        }
        .presentationDetents([.medium, .large])
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
                    StatCard(title: L10n.Dashboard.netSavings, value: overview.netSavings, currency: currencyCode,
                             icon: "arrow.up.right.circle.fill", color: Color(hex: "818cf8"))
                    StatCard(title: L10n.Dashboard.income, value: overview.totalIncome, currency: currencyCode,
                             icon: "arrow.down.circle.fill", color: Color(hex: "34d399"))
                    StatCard(title: L10n.Dashboard.expense, value: overview.totalExpenses, currency: currencyCode,
                             icon: "arrow.up.circle.fill", color: Color(hex: "f87171"))
                    StatCard(title: L10n.Analytics.expenseRatio, value: overview.expenseRatio, currency: nil,
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
                    MiniCategoryPie(title: L10n.Dashboard.expense, entries: viewModel.expenseByCategory, currencyCode: currencyCode)
                }
                if !viewModel.incomeByCategory.isEmpty {
                    MiniCategoryPie(title: L10n.Dashboard.income, entries: viewModel.incomeByCategory, currencyCode: currencyCode)
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
                    StatCard(title: L10n.Analytics.netWorth, value: nw.netWorth, currency: currencyCode,
                             icon: "chart.bar.fill", color: Color(hex: "818cf8"))
                    StatCard(title: L10n.Analytics.totalAssets, value: nw.totalAssets, currency: currencyCode,
                             icon: "arrow.up.circle.fill", color: Color(hex: "34d399"))
                    StatCard(title: L10n.Analytics.liabilities, value: nw.totalLiabilities, currency: currencyCode,
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
            Text(L10n.Analytics.monthlyCashFlow)
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
            Text(L10n.Analytics.topSpending).font(.headline.bold()).foregroundColor(.white)
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
            Text(L10n.Analytics.assetAllocation).font(.headline.bold()).foregroundColor(.white)
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
            Text(L10n.Analytics.investmentHoldings).font(.headline.bold()).foregroundColor(.white)
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
            Text(L10n.Analytics.accountBreakdown).font(.headline.bold()).foregroundColor(.white)
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
