import SwiftUI

@Observable
class AccountsViewModel {
    var accounts: [AccountResponse] = []
    var netWorthResponse: NetWorthResponse?
    var isLoading = false
    var isRefreshing = false
    var errorMessage: String?
    var currentCurrency: String = "USD"

    var displayNetWorth: Double {
        if let nw = netWorthResponse {
            return nw.netWorth
        }
        return accounts.reduce(0) { $0 + $1.totalValue }
    }

    var displayCurrency: String {
        if let nw = netWorthResponse {
            return nw.currencyCode
        }
        let common = accounts.first?.currencyCode ?? currentCurrency
        if !accounts.isEmpty && accounts.allSatisfy({ $0.currencyCode == common }) {
            return common
        }
        return currentCurrency
    }

    func load(currencyCode: String, isManualRefresh: Bool = false) async {
        self.currentCurrency = currencyCode
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

        async let accsTask = AccountService.shared.getAccounts()
        async let nwTask = AnalyticsService.shared.getNetWorth(currencyCode: currencyCode)

        do {
            accounts = try await accsTask
        } catch {
            errorMessage = error.localizedDescription
        }

        netWorthResponse = try? await nwTask
    }

    func moveAccountUp(index: Int) async {
        guard index > 0 && index < accounts.count else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            let account = accounts.remove(at: index)
            accounts.insert(account, at: index - 1)
        }
        let ids = accounts.map { $0.id }
        do {
            try await AccountService.shared.reorderAccounts(accountIds: ids)
        } catch {
            errorMessage = error.localizedDescription
            await load(currencyCode: currentCurrency)
        }
    }

    func moveAccountDown(index: Int) async {
        guard index >= 0 && index < accounts.count - 1 else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            let account = accounts.remove(at: index)
            accounts.insert(account, at: index + 1)
        }
        let ids = accounts.map { $0.id }
        do {
            try await AccountService.shared.reorderAccounts(accountIds: ids)
        } catch {
            errorMessage = error.localizedDescription
            await load(currencyCode: currentCurrency)
        }
    }

    func moveSubAccountUp(accountId: String, subIndex: Int) async {
        guard let accIndex = accounts.firstIndex(where: { $0.id == accountId }),
              var subs = accounts[accIndex].subAccounts,
              subIndex > 0 && subIndex < subs.count else { return }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            let sub = subs.remove(at: subIndex)
            subs.insert(sub, at: subIndex - 1)
            accounts[accIndex].subAccounts = subs
        }

        let ids = subs.map { $0.id }
        do {
            try await AccountService.shared.reorderSubAccounts(accountId: accountId, subAccountIds: ids)
        } catch {
            errorMessage = error.localizedDescription
            await load(currencyCode: currentCurrency)
        }
    }

    func moveSubAccountDown(accountId: String, subIndex: Int) async {
        guard let accIndex = accounts.firstIndex(where: { $0.id == accountId }),
              var subs = accounts[accIndex].subAccounts,
              subIndex >= 0 && subIndex < subs.count - 1 else { return }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            let sub = subs.remove(at: subIndex)
            subs.insert(sub, at: subIndex + 1)
            accounts[accIndex].subAccounts = subs
        }

        let ids = subs.map { $0.id }
        do {
            try await AccountService.shared.reorderSubAccounts(accountId: accountId, subAccountIds: ids)
        } catch {
            errorMessage = error.localizedDescription
            await load(currencyCode: currentCurrency)
        }
    }

    func deleteAccount(id: String) async {
        withAnimation(.easeInOut(duration: 0.25)) {
            accounts.removeAll { $0.id == id }
        }
        do {
            try await AccountService.shared.deleteAccount(id: id)
            await load(currencyCode: currentCurrency)
        } catch {
            errorMessage = error.localizedDescription
            await load(currencyCode: currentCurrency)
        }
    }

    func deleteSubAccount(accountId: String, subAccountId: String) async {
        do {
            try await AccountService.shared.deleteSubAccount(accountId: accountId, subAccountId: subAccountId)
            await load(currencyCode: currentCurrency)
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
        case .addAsset(let aId, let sId): return "addAsset-" + (aId ?? "") + "-" + (sId ?? "")
        }
    }
}

struct AccountsView: View {
    @Environment(AuthManager.self) private var auth
    @State private var viewModel = AccountsViewModel()
    @State private var activeSheet: AccountModalSheet? = nil
    @State private var isReordering = false
    @State private var selectedCurrency: String = "USD"

    let availableCurrencies = ["USD", "EUR", "GBP", "UAH", "PLN", "JPY", "CAD", "CHF"]

    @State private var accountToDelete: AccountResponse? = nil
    @State private var showDeleteAccountConfirmation = false

    @State private var subAccountToDelete: (accountId: String, sub: SubAccountResponse)? = nil
    @State private var showDeleteSubAccountConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header & Action Bar
                VStack(alignment: .leading, spacing: 14) {
                    // Title and Summary Row
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.Accounts.pageTitle)
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)

                        HStack(spacing: 8) {
                            Text(L10n.Accounts.accountsSummary(
                                count: viewModel.accounts.count,
                                netWorth: viewModel.displayNetWorth.formatted(currencyCode: viewModel.displayCurrency)
                            ))
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.6))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                            // Currency Switcher Menu Pill
                            Menu {
                                ForEach(availableCurrencies, id: \.self) { c in
                                    Button {
                                        selectedCurrency = c
                                        Task { await viewModel.load(currencyCode: c) }
                                    } label: {
                                        HStack {
                                            Text(c)
                                            if selectedCurrency == c {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 3) {
                                    Text(selectedCurrency)
                                        .font(.caption2.bold())
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 8, weight: .bold))
                                }
                                .foregroundColor(Color(hex: "a78bfa"))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color(hex: "a78bfa").opacity(0.12))
                                .clipShape(Capsule())
                            }
                        }
                    }

                    // Action Buttons Row
                    HStack(spacing: 8) {
                        // Reorder toggle
                        if viewModel.accounts.count > 1 || viewModel.accounts.contains(where: { ($0.subAccounts?.count ?? 0) > 1 }) {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    isReordering.toggle()
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: isReordering ? "checkmark" : "arrow.up.arrow.down")
                                        .font(.system(size: 11, weight: .bold))
                                    Text(isReordering ? L10n.Accounts.doneReordering : L10n.Accounts.reorder)
                                        .font(.caption.weight(.bold))
                                        .lineLimit(1)
                                }
                                .foregroundColor(isReordering ? Color(hex: "a78bfa") : Color.white.opacity(0.85))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(isReordering ? Color(hex: "a78bfa").opacity(0.2) : Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .fixedSize(horizontal: true, vertical: false)
                        }

                        // Buy/Add Asset button
                        Button {
                            activeSheet = .addAsset(accountId: nil, subAccountId: nil)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 11, weight: .bold))
                                Text(L10n.Accounts.addAsset)
                                    .font(.caption.weight(.bold))
                                    .lineLimit(1)
                            }
                            .foregroundColor(Color(hex: "34d399"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color(hex: "34d399").opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .fixedSize(horizontal: true, vertical: false)

                        Spacer()

                        // Add Account button
                        Button {
                            activeSheet = .addAccount
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.caption.weight(.bold))
                                Text(L10n.Accounts.addAccount)
                                    .font(.caption.weight(.semibold))
                                    .lineLimit(1)
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
                        .fixedSize(horizontal: true, vertical: false)
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

                // Reorder Help Banner
                if isReordering {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "818cf8"))
                        Text(L10n.Accounts.reorderHelp)
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.85))
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "818cf8").opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(hex: "818cf8").opacity(0.25), lineWidth: 1)
                            )
                    )
                }

                // Content
                if viewModel.isLoading && viewModel.accounts.isEmpty {
                    ProgressView().tint(Color(hex: "a78bfa")).padding(.vertical, 40)
                } else if viewModel.accounts.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "building.columns")
                            .font(.system(size: 48))
                            .foregroundColor(Color.white.opacity(0.2))
                        Text(L10n.Accounts.emptyTitle)
                            .font(.headline)
                            .foregroundColor(Color.white.opacity(0.4))
                        Button(L10n.Accounts.createFirstAccount) {
                            activeSheet = .addAccount
                        }
                        .foregroundColor(Color(hex: "a78bfa"))
                        .font(.subheadline.bold())
                    }
                    .padding(.vertical, 60)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(Array(viewModel.accounts.enumerated()), id: \.element.id) { index, account in
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
                                },
                                isReordering: isReordering,
                                canMoveUp: index > 0,
                                canMoveDown: index < viewModel.accounts.count - 1,
                                onMoveUp: {
                                    Task { await viewModel.moveAccountUp(index: index) }
                                },
                                onMoveDown: {
                                    Task { await viewModel.moveAccountDown(index: index) }
                                },
                                onMoveSubAccountUp: { sub, subIndex in
                                    Task { await viewModel.moveSubAccountUp(accountId: account.id, subIndex: subIndex) }
                                },
                                onMoveSubAccountDown: { sub, subIndex in
                                    Task { await viewModel.moveSubAccountDown(accountId: account.id, subIndex: subIndex) }
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
            await viewModel.load(currencyCode: selectedCurrency, isManualRefresh: true)
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .addAccount:
                AddAccountView {
                    Task { await viewModel.load(currencyCode: selectedCurrency) }
                }
            case .editAccount(let account):
                AddAccountView(editingAccount: account) {
                    Task { await viewModel.load(currencyCode: selectedCurrency) }
                }
            case .addSubAccount(let accountId, let currency):
                AddSubAccountView(parentAccountId: accountId, parentCurrency: currency) {
                    Task { await viewModel.load(currencyCode: selectedCurrency) }
                }
            case .editSubAccount(let accountId, let currency, let subAccount):
                AddSubAccountView(parentAccountId: accountId, parentCurrency: currency, editingSubAccount: subAccount) {
                    Task { await viewModel.load(currencyCode: selectedCurrency) }
                }
            case .addAsset(let accountId, let subAccountId):
                AddAssetView(defaultAccountId: accountId, defaultSubAccountId: subAccountId) {
                    Task { await viewModel.load(currencyCode: selectedCurrency) }
                }
            }
        }
        .confirmationDialog(
            L10n.Accounts.deleteConfirmTitle,
            isPresented: $showDeleteAccountConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.Accounts.deleteAccount, role: .destructive) {
                if let acc = accountToDelete {
                    Task { await viewModel.deleteAccount(id: acc.id) }
                }
            }
            Button(L10n.Common.cancel, role: .cancel) {}
        } message: {
            if let acc = accountToDelete {
                Text(L10n.Accounts.deleteConfirmMsg(name: acc.name))
            }
        }
        .confirmationDialog(
            L10n.Accounts.deleteSubConfirmTitle,
            isPresented: $showDeleteSubAccountConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.Accounts.deleteSubAccount, role: .destructive) {
                if let item = subAccountToDelete {
                    Task { await viewModel.deleteSubAccount(accountId: item.accountId, subAccountId: item.sub.id) }
                }
            }
            Button(L10n.Common.cancel, role: .cancel) {}
        } message: {
            if let item = subAccountToDelete {
                Text(L10n.Accounts.deleteSubConfirmMsg(name: item.sub.name))
            }
        }
        .task {
            let initialCurr = auth.currentUser?.defaultCurrencyCode ?? "USD"
            selectedCurrency = initialCurr
            await viewModel.load(currencyCode: selectedCurrency)

            if initialCurr == "USD",
               let firstCurr = viewModel.accounts.first?.currencyCode,
               !viewModel.accounts.isEmpty,
               viewModel.accounts.allSatisfy({ $0.currencyCode == firstCurr }) {
                selectedCurrency = firstCurr
                await viewModel.load(currencyCode: selectedCurrency)
            }
        }
        .onChange(of: selectedCurrency) { _, newCurrency in
            Task { await viewModel.load(currencyCode: newCurrency) }
        }
    }
}
