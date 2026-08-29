import SwiftUI

@Observable
class TransactionsViewModel {
    var transactions: [TransactionResponse] = []
    var totalCount: Int = 0
    var currentPage: Int = 1
    var totalPages: Int = 1
    var isLoading = false
    var errorMessage: String?

    // Filter state
    var searchText: String = ""
    var selectedType: String = ""
    var fromDate: String = ""
    var toDate: String = ""

    func load(page: Int = 1) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
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
        do {
            try await TransactionService.shared.deleteTransaction(id: id)
            await load()
        } catch {
            errorMessage = error.localizedDescription
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

                // Error
                if let error = viewModel.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(error).font(.caption)
                    }
                    .foregroundColor(Color(hex: "f87171"))
                    .padding(12).background(Color(hex: "f87171").opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // Loading
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
                            TransactionRowView(transaction: tx)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        Task { await viewModel.delete(id: tx.id) }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
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
        .sheet(isPresented: $showAddTransaction, onDismiss: {
            Task { await viewModel.load() }
        }) {
            AddTransactionView(onSuccess: {})
        }
        .task { await viewModel.load() }
        .animation(.default, value: showFilters)
    }
}
