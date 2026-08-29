import SwiftUI

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
                pageSize: 20,
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
            let ps = result.pageSize ?? 20
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
            await load(page: 1)
        }
    }

    func applyFilters() async {
        await load(page: 1)
    }

    func reset() {
        searchText = ""; selectedType = ""; fromDate = ""; toDate = ""
        Task { await load(page: 1) }
    }
}

struct TransactionsView: View {
    @State private var viewModel = TransactionsViewModel()
    @State private var showAddTransaction = false
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
                        Button { showFilters.toggle() } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .foregroundColor(Color(hex: "a78bfa"))
                                .font(.title3)
                        }
                        Button { showAddTransaction = true } label: {
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
                        Text("No transactions").font(.headline).foregroundColor(Color.white.opacity(0.4))
                    }
                    .padding(.vertical, 60)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.transactions) { tx in
                            SwipeableTransactionRow(transaction: tx) {
                                transactionToDelete = tx
                                showDeleteConfirmation = true
                            }

                            if tx.id != viewModel.transactions.last?.id {
                                Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 16)
                            }
                        }
                    }
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 18))

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
            Task { await viewModel.load(page: 1) }
        }) {
            AddTransactionView(onSuccess: {})
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
