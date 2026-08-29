import SwiftUI

@Observable
class TransactionsViewModel {
    var pagedResult: PagedResult<TransactionResponse>?
    var isLoading = false
    var errorMessage: String?
    var filters = TransactionFilterParams()

    var transactions: [TransactionResponse] { pagedResult?.items ?? [] }
    var totalCount: Int { pagedResult?.totalCount ?? 0 }
    var totalPages: Int { pagedResult?.totalPages ?? 1 }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            pagedResult = try await TransactionService.shared.getTransactions(filters: filters)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(id: String) async {
        do {
            try await TransactionService.shared.deleteTransaction(id: id)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct TransactionsView: View {
    @State private var viewModel = TransactionsViewModel()
    @State private var showAddTransaction = false
    @State private var showFilters = false

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
                                .foregroundStyle(
                                    LinearGradient(colors: [Color(hex: "818cf8"), Color(hex: "a78bfa")],
                                                   startPoint: .leading, endPoint: .trailing))
                                .font(.title3)
                        }
                    }
                }
                .padding(.horizontal, 4)

                // Filters
                if showFilters {
                    TransactionFiltersView(filters: $viewModel.filters) {
                        Task { await viewModel.load() }
                    }
                }

                // Transactions list
                if viewModel.isLoading {
                    ProgressView().tint(Color(hex: "a78bfa"))
                        .padding(.vertical, 40)
                } else if viewModel.transactions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundColor(Color.white.opacity(0.2))
                        Text("No transactions found")
                            .font(.headline)
                            .foregroundColor(Color.white.opacity(0.4))
                    }
                    .padding(.vertical, 60)
                } else {
                    VStack(spacing: 0) {
                        ForEach(viewModel.transactions) { tx in
                            TransactionRowView(transaction: tx)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        Task { await viewModel.delete(id: tx.id) }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            Divider()
                                .background(Color.white.opacity(0.06))
                        }
                    }
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    // Pagination
                    HStack(spacing: 16) {
                        Button {
                            viewModel.filters.page -= 1
                            Task { await viewModel.load() }
                        } label: {
                            Image(systemName: "chevron.left")
                                .padding(10)
                                .background(Color.white.opacity(0.08))
                                .clipShape(Circle())
                        }
                        .disabled(viewModel.filters.page <= 1)

                        Text("Page \(viewModel.filters.page) of \(viewModel.totalPages)")
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.6))

                        Button {
                            viewModel.filters.page += 1
                            Task { await viewModel.load() }
                        } label: {
                            Image(systemName: "chevron.right")
                                .padding(10)
                                .background(Color.white.opacity(0.08))
                                .clipShape(Circle())
                        }
                        .disabled(viewModel.filters.page >= viewModel.totalPages)
                    }
                    .foregroundColor(Color(hex: "a78bfa"))
                    .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(hex: "0d1117").ignoresSafeArea())
        .sheet(isPresented: $showAddTransaction, onDismiss: {
            Task { await viewModel.load() }
        }) {
            AddTransactionView(onSuccess: {})
        }
        .task { await viewModel.load() }
    }
}
