import SwiftUI

@Observable
class AccountsViewModel {
    var accounts: [AccountResponse] = []
    var isLoading = false
    var isRefreshing = false
    var errorMessage: String?

    var totalNetWorth: Double {
        accounts.reduce(0) { $0 + $1.totalValue }
    }

    func load(isManualRefresh: Bool = false) async {
        if isManualRefresh {
            isRefreshing = true
        } else if accounts.isEmpty {
            isLoading = true
        }
        errorMessage = nil
        defer {
            isLoading = false
            isRefreshing = false
        }
        do {
            accounts = try await AccountService.shared.getAccounts()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteAccount(id: String) async {
        withAnimation(.easeInOut(duration: 0.25)) {
            accounts.removeAll { $0.id == id }
        }
        do {
            try await AccountService.shared.deleteAccount(id: id)
        } catch {
            errorMessage = error.localizedDescription
            await load()
        }
    }

    func deleteSubAccount(accountId: String, subAccountId: String) async {
        do {
            try await AccountService.shared.deleteSubAccount(accountId: accountId, subAccountId: subAccountId)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

enum AccountModalSheet: Identifiable {
    case addAccount
    case editAccount(AccountResponse)
    case addSubAccount(accountId: String, currency: String)
    case editSubAccount(accountId: String, currency: String, subAccount: SubAccountResponse)
    case addAsset(accountId: String?, subAccountId: String?)

    var id: String {
        switch self {
        case .addAccount: return "addAccount"
        case .editAccount(let a): return "editAccount-\(a.id)"
        case .addSubAccount(let aId, _): return "addSubAccount-\(aId)"
        case .editSubAccount(let aId, _, let s): return "editSubAccount-\(aId)-\(s.id)"
        case .addAsset(let aId, let sId): return "addAsset-\(aId ?? "")-\(sId ?? "")"
        }
    }
}

struct AccountsView: View {
    @State private var viewModel = AccountsViewModel()
    @State private var activeSheet: AccountModalSheet? = nil

    @State private var accountToDelete: AccountResponse? = nil
    @State private var showDeleteAccountConfirmation = false

    @State private var subAccountToDelete: (accountId: String, sub: SubAccountResponse)? = nil
    @State private var showDeleteSubAccountConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Accounts")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                        Text("\(viewModel.accounts.count) accounts • Net Worth: \(viewModel.totalNetWorth.formatted(currencyCode: "USD"))")
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.5))
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        // Buy/Add Asset button
                        Button {
                            activeSheet = .addAsset(accountId: nil, subAccountId: nil)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 11, weight: .bold))
                                Text("Asset")
                                    .font(.caption.weight(.bold))
                            }
                            .foregroundColor(Color(hex: "34d399"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color(hex: "34d399").opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        // Add Account button
                        Button {
                            activeSheet = .addAccount
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.caption.weight(.bold))
                                Text("Account")
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "818cf8"), Color(hex: "a78bfa")],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
                .padding(.horizontal, 4)

                // Error Banner
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

                // Content
                if viewModel.isLoading && viewModel.accounts.isEmpty {
                    ProgressView().tint(Color(hex: "a78bfa")).padding(.vertical, 40)
                } else if viewModel.accounts.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "building.columns")
                            .font(.system(size: 48))
                            .foregroundColor(Color.white.opacity(0.2))
                        Text("No accounts yet")
                            .font(.headline)
                            .foregroundColor(Color.white.opacity(0.4))
                        Button("Add Your First Account") {
                            activeSheet = .addAccount
                        }
                        .foregroundColor(Color(hex: "a78bfa"))
                        .font(.subheadline.bold())
                    }
                    .padding(.vertical, 60)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.accounts) { account in
                            AccountCardView(
                                account: account,
                                onEdit: {
                                    activeSheet = .editAccount(account)
                                },
                                onDelete: {
                                    accountToDelete = account
                                    showDeleteAccountConfirmation = true
                                },
                                onAddSubAccount: {
                                    activeSheet = .addSubAccount(accountId: account.id, currency: account.currencyCode)
                                },
                                onAddAsset: {
                                    activeSheet = .addAsset(accountId: account.id, subAccountId: nil)
                                },
                                onEditSubAccount: { sub in
                                    activeSheet = .editSubAccount(accountId: account.id, currency: sub.currencyCode, subAccount: sub)
                                },
                                onDeleteSubAccount: { sub in
                                    subAccountToDelete = (accountId: account.id, sub: sub)
                                    showDeleteSubAccountConfirmation = true
                                },
                                onAddAssetToSubAccount: { sub in
                                    activeSheet = .addAsset(accountId: account.id, subAccountId: sub.id)
                                }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(hex: "0d1117").ignoresSafeArea())
        .refreshable {
            await viewModel.load(isManualRefresh: true)
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .addAccount:
                AddAccountView {
                    Task { await viewModel.load() }
                }
            case .editAccount(let account):
                AddAccountView(editingAccount: account) {
                    Task { await viewModel.load() }
                }
            case .addSubAccount(let accountId, let currency):
                AddSubAccountView(parentAccountId: accountId, parentCurrency: currency) {
                    Task { await viewModel.load() }
                }
            case .editSubAccount(let accountId, let currency, let subAccount):
                AddSubAccountView(parentAccountId: accountId, parentCurrency: currency, editingSubAccount: subAccount) {
                    Task { await viewModel.load() }
                }
            case .addAsset(let accountId, let subAccountId):
                AddAssetView(defaultAccountId: accountId, defaultSubAccountId: subAccountId) {
                    Task { await viewModel.load() }
                }
            }
        }
        .confirmationDialog(
            "Delete Account",
            isPresented: $showDeleteAccountConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Account", role: .destructive) {
                if let acc = accountToDelete {
                    Task { await viewModel.deleteAccount(id: acc.id) }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let acc = accountToDelete {
                Text("Are you sure you want to delete '\(acc.name)'? This will also remove all its sub-accounts and transactions.")
            }
        }
        .confirmationDialog(
            "Delete Sub-Account",
            isPresented: $showDeleteSubAccountConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Sub-Account", role: .destructive) {
                if let item = subAccountToDelete {
                    Task { await viewModel.deleteSubAccount(accountId: item.accountId, subAccountId: item.sub.id) }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let item = subAccountToDelete {
                Text("Are you sure you want to delete '\(item.sub.name)'?")
            }
        }
        .task {
            await viewModel.load()
        }
    }
}
