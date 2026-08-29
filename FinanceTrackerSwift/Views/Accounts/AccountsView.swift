import SwiftUI

@Observable
class AccountsViewModel {
    var accounts: [AccountResponse] = []
    var isLoading = false
    var errorMessage: String?

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            accounts = try await AccountService.shared.getAccounts()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(id: String) async {
        do {
            try await AccountService.shared.deleteAccount(id: id)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct AccountsView: View {
    @State private var viewModel = AccountsViewModel()
    @State private var showAddAccount = false

    var totalNetWorth: Double {
        viewModel.accounts.reduce(0) { $0 + $1.totalValue }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Accounts")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                        Text("\(viewModel.accounts.count) accounts")
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                    Spacer()
                    Button { showAddAccount = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(LinearGradient(colors: [Color(hex: "818cf8"), Color(hex: "a78bfa")],
                                                            startPoint: .leading, endPoint: .trailing))
                            .font(.title3)
                    }
                }
                .padding(.horizontal, 4)

                if viewModel.isLoading {
                    ProgressView().tint(Color(hex: "a78bfa")).padding(.vertical, 40)
                } else if viewModel.accounts.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "building.columns")
                            .font(.system(size: 48))
                            .foregroundColor(Color.white.opacity(0.2))
                        Text("No accounts yet")
                            .font(.headline)
                            .foregroundColor(Color.white.opacity(0.4))
                        Button("Add Account") { showAddAccount = true }
                            .foregroundColor(Color(hex: "a78bfa"))
                    }
                    .padding(.vertical, 60)
                } else {
                    ForEach(viewModel.accounts) { account in
                        AccountCardView(account: account)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    Task { await viewModel.delete(id: account.id) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(hex: "0d1117").ignoresSafeArea())
        .sheet(isPresented: $showAddAccount, onDismiss: {
            Task { await viewModel.load() }
        }) {
            AddAccountView(onSuccess: {})
        }
        .task { await viewModel.load() }
    }
}
