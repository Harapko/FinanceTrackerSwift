import SwiftUI
import Charts

enum TransactionsViewMode: String, CaseIterable {
    case breakdown = "Breakdown"
    case history = "History"
}

// MARK: - Transaction Period Helper
struct TransactionPeriodHelper {
    static let isoFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone.current
        return f
    }()

    static func dateRange(
        mode: TransactionPeriodMode,
        anchorDate: Date,
        customFrom: Date? = nil,
        customTo: Date? = nil
    ) -> (fromDate: String, toDate: String) {
        let calendar = Calendar.current

        switch mode {
        case .period:
            let from = customFrom ?? anchorDate
            let to = customTo ?? anchorDate
            return (isoFormatter.string(from: from), isoFormatter.string(from: to))

        case .day:
            let str = isoFormatter.string(from: anchorDate)
            return (str, str)

        case .week:
            var start = Date()
            var interval: TimeInterval = 0
            if calendar.dateInterval(of: .weekOfYear, start: &start, interval: &interval, for: anchorDate) {
                let end = start.addingTimeInterval(interval - 1)
                return (isoFormatter.string(from: start), isoFormatter.string(from: end))
            }
            let str = isoFormatter.string(from: anchorDate)
            return (str, str)

        case .month:
            let components = calendar.dateComponents([.year, .month], from: anchorDate)
            guard let startOfMonth = calendar.date(from: components),
                  let range = calendar.range(of: .day, in: .month, for: startOfMonth) else {
                let str = isoFormatter.string(from: anchorDate)
                return (str, str)
            }
            var endComponents = components
            endComponents.day = range.count
            let endOfMonth = calendar.date(from: endComponents) ?? startOfMonth
            return (isoFormatter.string(from: startOfMonth), isoFormatter.string(from: endOfMonth))

        case .year:
            let year = calendar.component(.year, from: anchorDate)
            let start = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) ?? anchorDate
            let end = calendar.date(from: DateComponents(year: year, month: 12, day: 31)) ?? anchorDate
            return (isoFormatter.string(from: start), isoFormatter.string(from: end))
        }
    }

    static func navigate(
        anchorDate: Date,
        mode: TransactionPeriodMode,
        direction: Int
    ) -> Date {
        let calendar = Calendar.current
        switch mode {
        case .day:
            return calendar.date(byAdding: .day, value: direction, to: anchorDate) ?? anchorDate
        case .week:
            return calendar.date(byAdding: .weekOfYear, value: direction, to: anchorDate) ?? anchorDate
        case .month:
            return calendar.date(byAdding: .month, value: direction, to: anchorDate) ?? anchorDate
        case .year:
            return calendar.date(byAdding: .year, value: direction, to: anchorDate) ?? anchorDate
        case .period:
            return anchorDate
        }
    }

    static func formatTitle(
        mode: TransactionPeriodMode,
        anchorDate: Date,
        customFrom: Date? = nil,
        customTo: Date? = nil
    ) -> String {
        let calendar = Calendar.current

        switch mode {
        case .period:
            let f = DateFormatter()
            f.dateFormat = "MMM d, yyyy"
            let fromStr = f.string(from: customFrom ?? anchorDate)
            let toStr = f.string(from: customTo ?? anchorDate)
            if fromStr == toStr { return fromStr }
            return "\(fromStr) — \(toStr)"

        case .day:
            if calendar.isDateInToday(anchorDate) {
                let f = DateFormatter()
                f.dateFormat = "MMM d, yyyy"
                return "Today • \(f.string(from: anchorDate))"
            }
            let f = DateFormatter()
            f.dateFormat = "MMMM d, yyyy"
            return f.string(from: anchorDate)

        case .week:
            let (fromStr, toStr) = dateRange(mode: .week, anchorDate: anchorDate)
            if let fDate = isoFormatter.date(from: fromStr),
               let tDate = isoFormatter.date(from: toStr) {
                let f = DateFormatter()
                f.dateFormat = "MMM d"
                let t = DateFormatter()
                t.dateFormat = "MMM d, yyyy"
                return "\(f.string(from: fDate)) — \(t.string(from: tDate))"
            }
            return "This Week"

        case .month:
            let f = DateFormatter()
            f.dateFormat = "MMMM yyyy"
            return f.string(from: anchorDate)

        case .year:
            let f = DateFormatter()
            f.dateFormat = "yyyy"
            return f.string(from: anchorDate)
        }
    }
}

// MARK: - Category Icon Mapper for SF Symbols
struct CategoryIconHelper {
    static func sfSymbol(forIcon icon: String?, categoryName: String) -> String {
        if let icon = icon, !icon.isEmpty {
            switch icon {
            case "bag.fill", "ShoppingBag": return "bag.fill"
            case "cart.fill", "ShoppingCart": return "cart.fill"
            case "fork.knife", "Utensils": return "fork.knife"
            case "cup.and.saucer.fill", "Coffee": return "cup.and.saucer.fill"
            case "house.fill", "Home": return "house.fill"
            case "car.fill", "Car": return "car.fill"
            case "heart.fill", "Heart": return "heart.fill"
            case "briefcase.fill", "Briefcase": return "briefcase.fill"
            case "graduationcap.fill", "GraduationCap": return "graduationcap.fill"
            case "gift.fill", "Gift": return "gift.fill"
            case "airplane", "Plane": return "airplane"
            case "film.fill", "Film": return "film.fill"
            case "music.note", "Music": return "music.note"
            case "dumbbell.fill", "Dumbbell": return "dumbbell.fill"
            case "cross.case.fill", "Shield": return "shield.fill"
            case "creditcard.fill", "Wallet": return "creditcard.fill"
            case "banknote.fill", "DollarSign": return "dollarsign.circle.fill"
            case "chart.line.uptrend.xyaxis", "TrendingUp": return "chart.line.uptrend.xyaxis"
            case "wrench.and.screwdriver.fill", "Wrench": return "wrench.fill"
            case "sparkles", "Sparkles": return "sparkles"
            case "iphone", "Smartphone": return "iphone"
            case "building.columns.fill", "Landmark": return "building.columns.fill"
            case "gamecontroller.fill", "Gamepad2": return "gamecontroller.fill"
            default:
                if UIImage(systemName: icon) != nil {
                    return icon
                }
            }
        }

        let cat = categoryName.lowercased()
        if cat.contains("vacation") || cat.contains("travel") || cat.contains("trip") || cat.contains("flight") {
            return "airplane"
        }
        if cat.contains("home") || cat.contains("house") || cat.contains("rent") || cat.contains("mortgage") {
            return "house.fill"
        }
        if cat.contains("grocer") || cat.contains("food") || cat.contains("market") {
            return "cart.fill"
        }
        if cat.contains("tech") || cat.contains("computer") || cat.contains("gadget") || cat.contains("laptop") {
            return "laptopcomputer"
        }
        if cat.contains("lesson") || cat.contains("school") || cat.contains("english") || cat.contains("study") || cat.contains("education") {
            return "graduationcap.fill"
        }
        if cat.contains("family") || cat.contains("kids") || cat.contains("child") {
            return "person.2.fill"
        }
        if cat.contains("health") || cat.contains("doctor") || cat.contains("med") {
            return "cross.case.fill"
        }
        if cat.contains("car") || cat.contains("transport") || cat.contains("gas") || cat.contains("fuel") {
            return "car.fill"
        }
        if cat.contains("salary") || cat.contains("income") || cat.contains("bonus") || cat.contains("wage") {
            return "dollarsign.circle.fill"
        }

        return "tag.fill"
    }
}

// MARK: - Transaction Breakdown Donut Chart View
struct TransactionBreakdownChartView: View {
    let items: [CategoryBreakdownEntry]
    let totalAmount: Double
    let currencyCode: String
    let activeType: TransactionType
    let selectedCategoryId: String?
    let onSelectCategory: (String?) -> Void
    let onQuickAdd: () -> Void

    private let fallbackPalette: [Color] = [
        Color(hex: "ef4444"), // Red
        Color(hex: "f97316"), // Orange
        Color(hex: "fbbf24"), // Amber
        Color(hex: "84cc16"), // Lime
        Color(hex: "10b981"), // Emerald
        Color(hex: "06b6d4"), // Cyan
        Color(hex: "3b82f6"), // Blue
        Color(hex: "8b5cf6"), // Violet
        Color(hex: "ec4899"), // Pink
        Color(hex: "14b8a6")  // Teal
    ]

    var displayItems: [CategoryBreakdownEntry] {
        items.filter { $0.amount > 0 }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Card container
            VStack(spacing: 12) {
                if displayItems.isEmpty {
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.08), style: StrokeStyle(lineWidth: 18, dash: [6, 4]))
                                .frame(width: 170, height: 170)

                            VStack(spacing: 2) {
                                Text(activeType == .expense ? "TOTAL EXPENSES" : "TOTAL INCOME")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Color.white.opacity(0.4))
                                Text(0.0.formatted(currencyCode: currencyCode))
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.vertical, 14)

                        Text("No activity logged for this period")
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 230)
                } else {
                    ZStack {
                        // Donut Chart
                        Chart {
                            ForEach(Array(displayItems.enumerated()), id: \.element.id) { index, entry in
                                let isSelected = selectedCategoryId == entry.categoryId
                                let sliceColor = entry.color != nil ? Color(hex: entry.color!) : fallbackPalette[index % fallbackPalette.count]

                                SectorMark(
                                    angle: .value("Amount", entry.amount),
                                    innerRadius: .ratio(0.66),
                                    angularInset: 1.5
                                )
                                .foregroundStyle(sliceColor)
                                .opacity(selectedCategoryId == nil ? 1.0 : (isSelected ? 1.0 : 0.3))
                                .cornerRadius(3)
                            }
                        }
                        .frame(width: 210, height: 210)

                        // Center content overlay
                        VStack(spacing: 2) {
                            Text(activeType == .expense ? "TOTAL EXPENSES" : "TOTAL INCOME")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(Color.white.opacity(0.45))
                                .tracking(0.5)

                            Text(totalAmount.formatted(currencyCode: currencyCode))
                                .font(.system(size: 20, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                                .minimumScaleFactor(0.7)
                                .lineLimit(1)
                                .padding(.horizontal, 16)
                        }
                        .frame(width: 140)
                    }
                    .frame(height: 230)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 14)
            .background(Color(hex: "161b22"))
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )

            // Floating "+" Action Button (matching template)
            Button {
                onQuickAdd()
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "f59e0b"), Color(hex: "fbbf24")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .shadow(color: Color(hex: "f59e0b").opacity(0.45), radius: 8, x: 0, y: 4)

                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.black)
                }
            }
            .padding(.trailing, 16)
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Category Breakdown List View
struct CategoryBreakdownListView: View {
    let items: [CategoryBreakdownEntry]
    let currencyCode: String
    let selectedCategoryId: String?
    let onSelectCategory: (CategoryBreakdownEntry) -> Void

    private let fallbackPalette: [Color] = [
        Color(hex: "ef4444"),
        Color(hex: "f97316"),
        Color(hex: "fbbf24"),
        Color(hex: "84cc16"),
        Color(hex: "10b981"),
        Color(hex: "06b6d4"),
        Color(hex: "3b82f6"),
        Color(hex: "8b5cf6"),
        Color(hex: "ec4899"),
        Color(hex: "14b8a6")
    ]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                let itemColor = item.color != nil ? Color(hex: item.color!) : fallbackPalette[index % fallbackPalette.count]
                let isSelected = selectedCategoryId == item.categoryId
                let symbol = CategoryIconHelper.sfSymbol(forIcon: item.icon, categoryName: item.categoryName)

                Button {
                    onSelectCategory(item)
                } label: {
                    HStack(spacing: 14) {
                        // Category Icon Badge in colored circle
                        ZStack {
                            Circle()
                                .fill(itemColor)
                                .frame(width: 42, height: 42)
                                .shadow(color: itemColor.opacity(0.35), radius: 6, x: 0, y: 3)

                            Image(systemName: symbol)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }

                        // Category Name & mini progress bar
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.categoryName)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)

                            // Mini Progress Bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.white.opacity(0.08))
                                        .frame(height: 3)

                                    Capsule()
                                        .fill(itemColor)
                                        .frame(width: max(3, geo.size.width * CGFloat(min(1.0, item.percentage / 100.0))), height: 3)
                                }
                            }
                            .frame(height: 3)
                            .frame(maxWidth: 120)
                        }

                        Spacer()

                        // Percentage
                        Text("\(Int(round(item.percentage)))%")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.6))
                            .frame(minWidth: 40, alignment: .trailing)

                        // Amount
                        Text(item.amount.formatted(currencyCode: currencyCode))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(minWidth: 80, alignment: .trailing)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.25))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(isSelected ? Color.white.opacity(0.1) : Color(hex: "161b22"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? itemColor : Color.white.opacity(0.06), lineWidth: isSelected ? 1.5 : 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Category Transactions Drill-Down Sheet
struct CategoryTransactionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let category: CategoryBreakdownEntry
    let currencyCode: String
    let fromDate: String
    let toDate: String
    let accountId: String?
    let onDelete: (String) -> Void

    @State private var transactions: [TransactionResponse] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?
    @State private var transactionToDelete: TransactionResponse?
    @State private var showDeleteConfirmation: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0d1117").ignoresSafeArea()

                if isLoading {
                    ProgressView().tint(.white)
                } else if let error = errorMessage {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(Color(hex: "f87171"))
                        Text(error)
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.6))
                    }
                } else if transactions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 40))
                            .foregroundColor(Color.white.opacity(0.2))
                        Text("No transactions found in this period")
                            .font(.subheadline)
                            .foregroundColor(Color.white.opacity(0.4))
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Category Summary Header
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(category.color != nil ? Color(hex: category.color!) : Color(hex: "818cf8"))
                                        .frame(width: 44, height: 44)

                                    Image(systemName: CategoryIconHelper.sfSymbol(forIcon: category.icon, categoryName: category.categoryName))
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(category.categoryName)
                                        .font(.title3.bold())
                                        .foregroundColor(.white)
                                    Text("\(transactions.count) transactions")
                                        .font(.caption)
                                        .foregroundColor(Color.white.opacity(0.5))
                                }

                                Spacer()

                                Text(category.amount.formatted(currencyCode: currencyCode))
                                    .font(.title3.bold())
                                    .foregroundColor(.white)
                            }
                            .padding(16)
                            .background(Color(hex: "161b22"))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))

                            // Transactions List
                            VStack(spacing: 0) {
                                ForEach(transactions) { tx in
                                    SwipeableTransactionRow(transaction: tx) {
                                        transactionToDelete = tx
                                        showDeleteConfirmation = true
                                    }

                                    if tx.id != transactions.last?.id {
                                        Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 16)
                                    }
                                }
                            }
                            .background(Color(hex: "161b22"))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle(category.categoryName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "a78bfa"))
                }
            }
            .confirmationDialog("Delete Transaction", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let tx = transactionToDelete {
                        transactions.removeAll { $0.id == tx.id }
                        onDelete(tx.id)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                if let tx = transactionToDelete {
                    Text("Delete transaction for \(tx.amount.formatted(currencyCode: tx.currencyCode))?")
                }
            }
            .task {
                await loadCategoryTransactions()
            }
        }
    }

    private func loadCategoryTransactions() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await TransactionService.shared.getTransactions(
                page: 1,
                pageSize: 100,
                type: nil,
                search: nil,
                fromDate: fromDate,
                toDate: toDate
            )
            transactions = result.items.filter { tx in
                let matchesCategory = tx.categoryId == category.categoryId
                if let acc = accountId, !acc.isEmpty {
                    return matchesCategory && tx.accountId == acc
                }
                return matchesCategory
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - View Model
@Observable
final class TransactionsViewModel {
    // Accounts & Scope
    var accounts: [AccountResponse] = []
    var selectedAccountId: String? = nil
    var totalScopeBalance: Double = 0
    var totalScopeCurrency: String = "USD"

    // Mode & Period
    var activeType: TransactionType = .expense
    var periodMode: TransactionPeriodMode = .month
    var anchorDate: Date = Date()
    var customFromDate: Date = Date()
    var customToDate: Date = Date()
    var viewMode: TransactionsViewMode = .breakdown

    // Analytics Breakdown Data
    var expenseBreakdown: [CategoryBreakdownEntry] = []
    var incomeBreakdown: [CategoryBreakdownEntry] = []
    var totalExpenseAmount: Double = 0
    var totalIncomeAmount: Double = 0
    var isBreakdownLoading: Bool = false

    // History Transactions Data
    var transactions: [TransactionResponse] = []
    var totalCount: Int = 0
    var currentPage: Int = 1
    var totalPages: Int = 1
    var isLoading: Bool = false
    var isRefreshing: Bool = false
    var errorMessage: String?

    // Filter state for history feed
    var searchText: String = ""
    var selectedType: String = ""
    var fromDate: String = ""
    var toDate: String = ""

    var currentBreakdown: [CategoryBreakdownEntry] {
        activeType == .expense ? expenseBreakdown : incomeBreakdown
    }

    var currentBreakdownTotal: Double {
        activeType == .expense ? totalExpenseAmount : totalIncomeAmount
    }

    var selectedAccount: AccountResponse? {
        guard let id = selectedAccountId else { return nil }
        return accounts.first { $0.id == id }
    }

    var currentCurrency: String {
        selectedAccount?.currencyCode ?? totalScopeCurrency
    }

    var formattedPeriodTitle: String {
        TransactionPeriodHelper.formatTitle(
            mode: periodMode,
            anchorDate: anchorDate,
            customFrom: customFromDate,
            customTo: customToDate
        )
    }

    var currentDateRange: (fromDate: String, toDate: String) {
        TransactionPeriodHelper.dateRange(
            mode: periodMode,
            anchorDate: anchorDate,
            customFrom: customFromDate,
            customTo: customToDate
        )
    }

    var groupedTransactions: [TransactionDateGroup] {
        let grouped = Dictionary(grouping: transactions, by: { $0.date })
        let sortedDates = grouped.keys.sorted(by: >)

        return sortedDates.map { dateKey in
            let rawList = grouped[dateKey] ?? []
            let sortedItems = rawList.sorted { a, b in
                if let aCreated = a.createdAtUtc, let bCreated = b.createdAtUtc, aCreated != bCreated {
                    return aCreated > bCreated
                }
                if let aTime = a.time, let bTime = b.time, aTime != bTime {
                    return aTime > bTime
                }
                return a.id > b.id
            }

            let exp = sortedItems.filter { $0.type == .expense }.reduce(0.0) { $0 + $1.amount }
            let inc = sortedItems.filter { $0.type == .income }.reduce(0.0) { $0 + $1.amount }

            return TransactionDateGroup(
                dateString: dateKey,
                formattedDate: formatSectionDate(dateKey),
                transactions: sortedItems,
                totalExpense: exp,
                totalIncome: inc
            )
        }
    }

    private func formatSectionDate(_ dateStr: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateStr) else { return dateStr }

        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d"
            return "Today • \(displayFormatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d"
            return "Yesterday • \(displayFormatter.string(from: date))"
        } else {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "EEEE, MMM d, yyyy"
            return displayFormatter.string(from: date)
        }
    }

    // MARK: - Data Loading
    func loadAll(isManualRefresh: Bool = false) async {
        if isManualRefresh {
            isRefreshing = true
        }
        defer {
            isRefreshing = false
        }

        async let accsTask: () = loadAccounts()
        async let breakdownTask: () = loadBreakdown()
        async let txsTask: () = loadTransactions(page: 1)

        _ = await (accsTask, breakdownTask, txsTask)
    }

    func loadAccounts() async {
        do {
            accounts = try await AccountService.shared.getAccounts()
            totalScopeBalance = accounts.reduce(0.0) { $0 + $1.totalValue }
            if let first = accounts.first {
                totalScopeCurrency = first.currencyCode
            }
        } catch {
            print("Failed to load accounts: \(error.localizedDescription)")
        }
    }

    func loadBreakdown() async {
        isBreakdownLoading = true
        defer { isBreakdownLoading = false }

        let range = currentDateRange
        let filters = AnalyticsFilters(
            fromDate: range.fromDate,
            toDate: range.toDate,
            accountId: selectedAccountId,
            currencyCode: currentCurrency
        )

        do {
            async let expTask = AnalyticsService.shared.getExpenseByCategory(filters: filters)
            async let incTask = AnalyticsService.shared.getIncomeByCategory(filters: filters)

            let expItems = (try? await expTask) ?? []
            let incItems = (try? await incTask) ?? []

            expenseBreakdown = expItems
            incomeBreakdown = incItems
            totalExpenseAmount = expItems.reduce(0.0) { $0 + $1.amount }
            totalIncomeAmount = incItems.reduce(0.0) { $0 + $1.amount }
        }
    }

    func loadTransactions(page: Int = 1) async {
        if page == 1 && transactions.isEmpty {
            isLoading = true
        }
        errorMessage = nil
        defer {
            isLoading = false
        }
        currentPage = page

        let range = currentDateRange
        let reqType: String? = !selectedType.isEmpty
            ? selectedType
            : (viewMode == .breakdown ? activeType.rawValue : nil)
        let reqFrom = !fromDate.isEmpty ? fromDate : range.fromDate
        let reqTo = !toDate.isEmpty ? toDate : range.toDate

        do {
            let result = try await TransactionService.shared.getTransactions(
                page: page,
                pageSize: 30,
                type: reqType,
                search: searchText.isEmpty ? nil : searchText,
                fromDate: reqFrom,
                toDate: reqTo
            )
            if page == 1 {
                transactions = result.items
            } else {
                transactions.append(contentsOf: result.items)
            }
            totalCount = result.totalCount ?? result.items.count
            let ps = result.pageSize ?? 30
            totalPages = ps > 0 ? ((totalCount + ps - 1) / ps) : 1
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(id: String) async {
        withAnimation(.easeInOut(duration: 0.25)) {
            transactions.removeAll { $0.id == id }
            totalCount = max(0, totalCount - 1)
        }
        do {
            try await TransactionService.shared.deleteTransaction(id: id)
            await loadBreakdown()
            await loadAccounts()
        } catch {
            errorMessage = error.localizedDescription
            await loadAll(isManualRefresh: true)
        }
    }

    func navigatePeriod(direction: Int) {
        if periodMode == .period { return }
        anchorDate = TransactionPeriodHelper.navigate(
            anchorDate: anchorDate,
            mode: periodMode,
            direction: direction
        )
        Task {
            await loadBreakdown()
            await loadTransactions(page: 1)
        }
    }

    func selectPeriodMode(_ mode: TransactionPeriodMode) {
        periodMode = mode
        Task {
            await loadBreakdown()
            await loadTransactions(page: 1)
        }
    }

    func selectType(_ type: TransactionType) {
        activeType = type
        Task {
            await loadBreakdown()
            if viewMode == .breakdown {
                await loadTransactions(page: 1)
            }
        }
    }

    func selectAccount(_ id: String?) {
        selectedAccountId = id
        Task {
            await loadBreakdown()
            await loadTransactions(page: 1)
        }
    }

    func applyCustomRange(from: Date, to: Date) {
        customFromDate = from
        customToDate = to
        periodMode = .period
        Task {
            await loadBreakdown()
            await loadTransactions(page: 1)
        }
    }

    func reset() {
        searchText = ""
        selectedType = ""
        fromDate = ""
        toDate = ""
        Task { await loadTransactions(page: 1) }
    }

    func applyFilters() async {
        await loadTransactions(page: 1)
    }
}

// MARK: - Main Transactions View
struct TransactionsView: View {
    @State private var viewModel = TransactionsViewModel()
    @State private var showAddTransaction = false
    @State private var initialAddType: TransactionType = .expense
    @State private var showAddCategory = false
    @State private var showDatePicker = false
    @State private var showHistoryFilters = false
    @State private var selectedCategoryForSheet: CategoryBreakdownEntry?
    @State private var transactionToDelete: TransactionResponse?
    @State private var showDeleteConfirmation = false

    // Custom date pickers
    @State private var tempStartDate: Date = Date()
    @State private var tempEndDate: Date = Date()

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // 1. Top Header Bar (Account Scope Selector, View Toggle, Actions)
                topHeaderSection

                // 2. EXPENSES / INCOME Segmented Toggle Tabs
                typeSegmentedControl

                // 3. Period Range Pills (Day | Week | Month | Year | Period)
                periodPillsSection

                // 4. Date Stepper (< August 2026 >)
                dateStepperSection

                // Error message banner
                if let error = viewModel.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(error).font(.caption)
                    }
                    .foregroundColor(Color(hex: "f87171"))
                    .padding(12)
                    .background(Color(hex: "f87171").opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // 5. Main Content: Breakdown View vs History Feed
                if viewModel.viewMode == .breakdown {
                    breakdownContentSection
                } else {
                    historyContentSection
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(hex: "0d1117").ignoresSafeArea())
        .refreshable {
            await viewModel.loadAll(isManualRefresh: true)
        }
        .sheet(isPresented: $showAddTransaction, onDismiss: {
            Task { await viewModel.loadAll(isManualRefresh: true) }
        }) {
            AddTransactionView(initialType: initialAddType) {
                Task { await viewModel.loadAll(isManualRefresh: true) }
            }
        }
        .sheet(isPresented: $showAddCategory) {
            AddCategoryView(initialType: viewModel.activeType == .income ? .income : .expense) { _ in
                Task { await viewModel.loadBreakdown() }
            }
        }
        .sheet(item: $selectedCategoryForSheet) { cat in
            CategoryTransactionsSheet(
                category: cat,
                currencyCode: viewModel.currentCurrency,
                fromDate: viewModel.currentDateRange.fromDate,
                toDate: viewModel.currentDateRange.toDate,
                accountId: viewModel.selectedAccountId,
                onDelete: { id in
                    Task { await viewModel.delete(id: id) }
                }
            )
        }
        .sheet(isPresented: $showDatePicker) {
            customDatePickerSheet
        }
        .confirmationDialog(
            "Delete Transaction",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let tx = transactionToDelete {
                    Task { await viewModel.delete(id: tx.id) }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let tx = transactionToDelete {
                Text("Are you sure you want to delete this transaction for \(tx.amount.formatted(currencyCode: tx.currencyCode))?")
            }
        }
        .task {
            await viewModel.loadAll()
        }
    }

    // MARK: - 1. Top Header Section
    private var topHeaderSection: some View {
        HStack(alignment: .center) {
            // Account Scope Menu
            Menu {
                Button {
                    viewModel.selectAccount(nil)
                } label: {
                    HStack {
                        Text("💰 Total (All Accounts)")
                        if viewModel.selectedAccountId == nil {
                            Image(systemName: "checkmark")
                        }
                    }
                }

                Divider()

                ForEach(viewModel.accounts) { acc in
                    Button {
                        viewModel.selectAccount(acc.id)
                    } label: {
                        HStack {
                            Text("\(acc.name) (\(acc.currencyCode))")
                            if viewModel.selectedAccountId == acc.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "banknote.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.6))
                        Text(viewModel.selectedAccount?.name ?? "Total")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.7))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.5))
                    }

                    Text(viewModel.selectedAccount?.totalValue.formatted(currencyCode: viewModel.selectedAccount?.currencyCode ?? viewModel.totalScopeCurrency) ?? viewModel.totalScopeBalance.formatted(currencyCode: viewModel.totalScopeCurrency))
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                }
            }

            Spacer()

            // View mode toggle, Filters & Add menu
            HStack(spacing: 12) {
                // View Switcher (Donut vs Feed)
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        viewModel.viewMode = (viewModel.viewMode == .breakdown) ? .history : .breakdown
                    }
                } label: {
                    Image(systemName: viewModel.viewMode == .breakdown ? "list.bullet.rectangle.portrait" : "chart.pie.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "a78bfa"))
                        .padding(8)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }

                if viewModel.viewMode == .history {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showHistoryFilters.toggle()
                        }
                    } label: {
                        Image(systemName: showHistoryFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: "818cf8"))
                            .padding(8)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                }

                // Plus Menu
                Menu {
                    Button {
                        initialAddType = .expense
                        showAddTransaction = true
                    } label: {
                        Label("New Transaction", systemImage: "plus.circle")
                    }
                    Button {
                        initialAddType = .transfer
                        showAddTransaction = true
                    } label: {
                        Label("Transfer Funds", systemImage: "arrow.left.arrow.right.circle")
                    }
                    Button {
                        showAddCategory = true
                    } label: {
                        Label("New Category", systemImage: "tag")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "818cf8"), Color(hex: "a78bfa")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .font(.system(size: 24, weight: .bold))
                }
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - 2. EXPENSES / INCOME Segmented Control
    private var typeSegmentedControl: some View {
        HStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    viewModel.selectType(.expense)
                }
            } label: {
                VStack(spacing: 6) {
                    Text("EXPENSES")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(viewModel.activeType == .expense ? .white : Color.white.opacity(0.4))
                        .tracking(1)

                    Rectangle()
                        .fill(viewModel.activeType == .expense ? Color(hex: "34d399") : Color.clear)
                        .frame(height: 3)
                        .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    viewModel.selectType(.income)
                }
            } label: {
                VStack(spacing: 6) {
                    Text("INCOME")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(viewModel.activeType == .income ? .white : Color.white.opacity(0.4))
                        .tracking(1)

                    Rectangle()
                        .fill(viewModel.activeType == .income ? Color(hex: "34d399") : Color.clear)
                        .frame(height: 3)
                        .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
    }

    // MARK: - 3. Period Pills Section
    private var periodPillsSection: some View {
        HStack(spacing: 8) {
            ForEach(TransactionPeriodMode.allCases) { mode in
                let isSelected = viewModel.periodMode == mode
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        if mode == .period {
                            tempStartDate = viewModel.customFromDate
                            tempEndDate = viewModel.customToDate
                            showDatePicker = true
                        } else {
                            viewModel.selectPeriodMode(mode)
                        }
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(mode.rawValue)
                            .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                            .foregroundColor(isSelected ? Color(hex: "34d399") : Color.white.opacity(0.5))

                        if isSelected {
                            Capsule()
                                .fill(Color(hex: "34d399"))
                                .frame(width: 16, height: 2.5)
                        } else {
                            Capsule()
                                .fill(Color.clear)
                                .frame(width: 16, height: 2.5)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - 4. Date Stepper Section
    private var dateStepperSection: some View {
        HStack {
            Button {
                viewModel.navigatePeriod(direction: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.6))
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.04))
                    .clipShape(Circle())
            }
            .disabled(viewModel.periodMode == .period)

            Spacer()

            Button {
                tempStartDate = viewModel.customFromDate
                tempEndDate = viewModel.customToDate
                showDatePicker = true
            } label: {
                Text(viewModel.formattedPeriodTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .underline(viewModel.periodMode == .period, color: Color(hex: "34d399"))
            }

            Spacer()

            Button {
                viewModel.navigatePeriod(direction: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.6))
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.04))
                    .clipShape(Circle())
            }
            .disabled(viewModel.periodMode == .period)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - 5A. Breakdown Content Section
    private var breakdownContentSection: some View {
        VStack(spacing: 16) {
            // Donut Chart Widget
            TransactionBreakdownChartView(
                items: viewModel.currentBreakdown,
                totalAmount: viewModel.currentBreakdownTotal,
                currencyCode: viewModel.currentCurrency,
                activeType: viewModel.activeType,
                selectedCategoryId: nil,
                onSelectCategory: { _ in },
                onQuickAdd: {
                    initialAddType = viewModel.activeType
                    showAddTransaction = true
                }
            )

            // Category Breakdown List
            CategoryBreakdownListView(
                items: viewModel.currentBreakdown,
                currencyCode: viewModel.currentCurrency,
                selectedCategoryId: nil,
                onSelectCategory: { category in
                    selectedCategoryForSheet = category
                }
            )
        }
    }

    // MARK: - 5B. History Content Section
    private var historyContentSection: some View {
        VStack(spacing: 16) {
            // Filter Bar
            if showHistoryFilters {
                TransactionFiltersView(viewModel: viewModel) {
                    Task { await viewModel.loadTransactions(page: 1) }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if viewModel.isLoading {
                ProgressView().tint(.white).padding(.vertical, 40)
            } else if viewModel.transactions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "arrow.left.arrow.right.square")
                        .font(.system(size: 48)).foregroundColor(Color.white.opacity(0.2))
                    Text("No transactions found").font(.headline).foregroundColor(Color.white.opacity(0.4))
                    if !viewModel.searchText.isEmpty || !viewModel.selectedType.isEmpty || !viewModel.fromDate.isEmpty || !viewModel.toDate.isEmpty {
                        Button("Reset Filters") {
                            viewModel.reset()
                        }
                        .font(.caption.bold())
                        .foregroundColor(Color(hex: "a78bfa"))
                    }
                }
                .padding(.vertical, 60)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.groupedTransactions) { group in
                        VStack(alignment: .leading, spacing: 8) {
                            // Section Header
                            HStack {
                                Text(group.formattedDate.uppercased())
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color.white.opacity(0.5))

                                Spacer()

                                HStack(spacing: 8) {
                                    if group.totalIncome > 0 {
                                        Text("+\(group.totalIncome.formatted(currencyCode: group.transactions.first?.currencyCode ?? viewModel.currentCurrency))")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(Color(hex: "34d399"))
                                    }
                                    if group.totalExpense > 0 {
                                        Text("-\(group.totalExpense.formatted(currencyCode: group.transactions.first?.currencyCode ?? viewModel.currentCurrency))")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(Color(hex: "f87171"))
                                    }
                                }
                            }
                            .padding(.horizontal, 8)

                            // Transactions in group
                            VStack(spacing: 0) {
                                ForEach(group.transactions) { tx in
                                    SwipeableTransactionRow(transaction: tx) {
                                        transactionToDelete = tx
                                        showDeleteConfirmation = true
                                    }

                                    if tx.id != group.transactions.last?.id {
                                        Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 16)
                                    }
                                }
                            }
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                    }
                }

                // Load More Button
                if viewModel.currentPage < viewModel.totalPages {
                    Button {
                        Task { await viewModel.loadTransactions(page: viewModel.currentPage + 1) }
                    } label: {
                        Text("Load More")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color(hex: "a78bfa"))
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
        }
    }

    // MARK: - Custom Date Picker Sheet
    private var customDatePickerSheet: some View {
        NavigationStack {
            Form {
                Section("Date Range") {
                    DatePicker("From Date", selection: $tempStartDate, displayedComponents: .date)
                    DatePicker("To Date", selection: $tempEndDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Select Custom Period")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showDatePicker = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        viewModel.applyCustomRange(from: tempStartDate, to: tempEndDate)
                        showDatePicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Swipeable Transaction Row
struct SwipeableTransactionRow: View {
    let transaction: TransactionResponse
    let onDelete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var isRevealed = false

    var body: some View {
        ZStack(alignment: .trailing) {
            HStack {
                Spacer()
                Button(role: .destructive) {
                    withAnimation(.spring(response: 0.3)) {
                        offset = 0
                        isRevealed = false
                    }
                    onDelete()
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 70, height: 60)
                        .background(Color(hex: "ef4444"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.trailing, 8)
            }

            TransactionRowView(transaction: transaction, onDelete: onDelete)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(hex: "161b22"))
                .offset(x: offset)
                .gesture(
                    DragGesture(minimumDistance: 20, coordinateSpace: .local)
                        .onChanged { value in
                            if value.translation.width < 0 {
                                offset = max(value.translation.width, -80)
                            } else if isRevealed {
                                offset = min(0, -80 + value.translation.width)
                            }
                        }
                        .onEnded { value in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                if value.translation.width < -40 {
                                    offset = -80
                                    isRevealed = true
                                } else {
                                    offset = 0
                                    isRevealed = false
                                }
                            }
                        }
                )
        }
    }
}
