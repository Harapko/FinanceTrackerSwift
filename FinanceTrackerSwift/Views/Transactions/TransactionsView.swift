import SwiftUI

struct TransactionDateGroup: Identifiable {
    let dateString: String
    let formattedDate: String
    let transactions: [TransactionResponse]
    let totalExpense: Double
    let totalIncome: Double

    var id: String { dateString }
}

@Observable
class TransactionsViewModel {
    var transactions: [TransactionResponse] = []
    var totalCount: Int = 0
    var currentPage: Int = 1
    var totalPages: Int = 1
    var isLoading = false
    var isRefreshing = false
    var errorMessage: String?

    // Filter state
    var searchText: String = ""
    var selectedType: String = ""
    var fromDate: String = ""
    var toDate: String = ""

    var groupedTransactions: [TransactionDateGroup] {
        let grouped = Dictionary(grouping: transactions, by: { $0.date })
        // Sort date keys descending (newest dates first)
        let sortedDates = grouped.keys.sorted(by: >)

        return sortedDates.map { dateKey in
            let rawList = grouped[dateKey] ?? []
            // Sort items on the same day by CreatedAtUtc descending, or time descending
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

    func load(page: Int = 1, isManualRefresh: Bool = false) async {
        if isManualRefresh {
            isRefreshing = true
        } else if page == 1 && transactions.isEmpty {
            isLoading = true
        }
        errorMessage = nil
        defer {
            isLoading = false
            isRefreshing = false
        }
        currentPage = page
        do {
            let result = try await TransactionService.shared.getTransactions(
                page: page,
                pageSize: 30,
                type: selectedType.isEmpty ? nil : selectedType,
                search: searchText.isEmpty ? nil : searchText,
                fromDate: fromDate.isEmpty ? nil : fromDate,
                toDate: toDate.isEmpty ? nil : toDate
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
        } catch {
            errorMessage = error.localizedDescription
            await load(page: 1, isManualRefresh: true)
        }
    }

    func applyFilters() async {
        await load(page: 1, isManualRefresh: true)
    }

    func reset() {
        searchText = ""; selectedType = ""; fromDate = ""; toDate = ""
        Task { await load(page: 1, isManualRefresh: true) }
    }
}

struct TransactionsView: View {
    @State private var viewModel = TransactionsViewModel()
    @State private var showAddTransaction = false
    @State private var initialAddType: TransactionType = .expense
    @State private var showAddCategory = false
    @State private var showFilters = false
    @State private var transactionToDelete: TransactionResponse?
    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Transactions")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                        Text("\(viewModel.totalCount) total")
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                    Spacer()
                    HStack(spacing: 10) {
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                showFilters.toggle()
                            }
                        } label: {
                            Image(systemName: showFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                .foregroundColor(Color(hex: "a78bfa"))
                                .font(.title3)
                        }

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
                                .foregroundStyle(LinearGradient(
                                    colors: [Color(hex: "818cf8"), Color(hex: "a78bfa")],
                                    startPoint: .leading, endPoint: .trailing))
                                .font(.title3)
                        }
                    }
                }
                .padding(.horizontal, 4)

                // Filters panel
                if showFilters {
                    TransactionFiltersView(viewModel: viewModel) {
                        Task { await viewModel.applyFilters() }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Error Banner
                if let error = viewModel.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(error).font(.caption)
                    }
                    .foregroundColor(Color(hex: "f87171"))
                    .padding(12).background(Color(hex: "f87171").opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // Loading State
                if viewModel.isLoading && viewModel.transactions.isEmpty {
                    ProgressView().tint(Color(hex: "a78bfa")).padding(.vertical, 40)
                } else if viewModel.transactions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "arrow.left.arrow.right.square")
                            .font(.system(size: 48)).foregroundColor(Color.white.opacity(0.2))
                        Text("No transactions found").font(.headline).foregroundColor(Color.white.opacity(0.4))
                        if !viewModel.fromDate.isEmpty || !viewModel.toDate.isEmpty || !viewModel.searchText.isEmpty || !viewModel.selectedType.isEmpty {
                            Button("Reset Filters") {
                                viewModel.reset()
                            }
                            .font(.caption.bold())
                            .foregroundColor(Color(hex: "a78bfa"))
                        }
                    }
                    .padding(.vertical, 60)
                } else {
                    // Grouped Transactions by Date
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
                                            Text("+\(group.totalIncome.formatted(currencyCode: group.transactions.first?.currencyCode ?? "USD"))")
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundColor(Color(hex: "34d399"))
                                        }
                                        if group.totalExpense > 0 {
                                            Text("-\(group.totalExpense.formatted(currencyCode: group.transactions.first?.currencyCode ?? "USD"))")
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundColor(Color(hex: "f87171"))
                                        }
                                    }
                                }
                                .padding(.horizontal, 8)

                                // Transactions list in group
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

                    // Load More
                    if viewModel.currentPage < viewModel.totalPages {
                        Button {
                            Task { await viewModel.load(page: viewModel.currentPage + 1) }
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
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(hex: "0d1117").ignoresSafeArea())
        .refreshable {
            await viewModel.load(page: 1, isManualRefresh: true)
        }
        .sheet(isPresented: $showAddTransaction, onDismiss: {
            Task { await viewModel.load(page: 1, isManualRefresh: true) }
        }) {
            AddTransactionView(initialType: initialAddType) {
                Task { await viewModel.load(page: 1, isManualRefresh: true) }
            }
        }
        .sheet(isPresented: $showAddCategory) {
            AddCategoryView()
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
        .task { await viewModel.load() }
        .animation(.default, value: showFilters)
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
            // Background Delete Button
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

            // Foreground Content
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
