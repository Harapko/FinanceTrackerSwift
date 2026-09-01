import SwiftUI

struct AccountCardView: View {
    let account: AccountResponse
    var onEdit: () -> Void = {}
    var onDelete: () -> Void = {}
    var onAddSubAccount: () -> Void = {}
    var onAddAsset: () -> Void = {}
    var onEditSubAccount: (SubAccountResponse) -> Void = { _ in }
    var onDeleteSubAccount: (SubAccountResponse) -> Void = { _ in }
    var onAddAssetToSubAccount: (SubAccountResponse) -> Void = { _ in }

    var isReordering: Bool = false
    var canMoveUp: Bool = false
    var canMoveDown: Bool = false
    var onMoveUp: () -> Void = {}
    var onMoveDown: () -> Void = {}

    var onMoveSubAccountUp: (SubAccountResponse, Int) -> Void = { _, _ in }
    var onMoveSubAccountDown: (SubAccountResponse, Int) -> Void = { _, _ in }

    @State private var isExpanded = true
    @State private var holdings: [HoldingResponse] = []
    @State private var isLoadingHoldings = false
    @State private var editingHolding: HoldingResponse? = nil

    private var directHoldings: [HoldingResponse] {
        holdings.filter { $0.subAccountId == nil }
    }

    private var accentColor: Color {
        if let hex = account.color, !hex.isEmpty {
            return Color(hex: hex)
        }
        switch account.type {
        case .bankAccount: return Color(hex: "60a5fa")
        case .cryptoWallet: return Color(hex: "f59e0b")
        case .investmentAccount: return Color(hex: "a78bfa")
        case .creditCard: return Color(hex: "f87171")
        default: return Color(hex: "818cf8")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header Row
            HStack(spacing: 12) {
                // Icon
                Image(systemName: account.icon ?? account.type.icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(accentColor)
                    .frame(width: 40, height: 40)
                    .background(accentColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 2) {
                    Text(account.name)
                        .font(.headline.bold())
                        .foregroundColor(.white)
                    Text("\(account.type.displayName) • \(account.currencyCode)")
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.5))
                }

                Spacer()

                if isReordering {
                    HStack(spacing: 6) {
                        Button {
                            onMoveUp()
                        } label: {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(canMoveUp ? Color(hex: "818cf8") : Color.white.opacity(0.2))
                                .frame(width: 28, height: 28)
                                .background(Color(hex: "818cf8").opacity(canMoveUp ? 0.15 : 0.05))
                                .clipShape(Circle())
                        }
                        .disabled(!canMoveUp)

                        Button {
                            onMoveDown()
                        } label: {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(canMoveDown ? Color(hex: "818cf8") : Color.white.opacity(0.2))
                                .frame(width: 28, height: 28)
                                .background(Color(hex: "818cf8").opacity(canMoveDown ? 0.15 : 0.05))
                                .clipShape(Circle())
                        }
                        .disabled(!canMoveDown)
                    }
                } else {
                    HStack(spacing: 6) {
                        Button {
                            onAddAsset()
                        } label: {
                            Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color(hex: "34d399"))
                        }

                        Button {
                            onAddSubAccount()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color(hex: "818cf8"))
                        }

                        Menu {
                            Button {
                                onAddAsset()
                            } label: {
                                Label(L10n.Accounts.buyAddAsset, systemImage: "chart.line.uptrend.xyaxis")
                            }

                            Button {
                                onAddSubAccount()
                            } label: {
                                Label("Add Sub-Account", systemImage: "plus.rectangle.on.rectangle")
                            }

                            Button {
                                onEdit()
                            } label: {
                                Label(L10n.Accounts.editAccount, systemImage: "pencil")
                            }

                            Divider()

                            Button(role: .destructive) {
                                onDelete()
                            } label: {
                                Label(L10n.Accounts.deleteAccount, systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color.white.opacity(0.4))
                                .padding(6)
                        }
                    }
                }
            }

            // Description if any
            if let desc = account.description, !desc.isEmpty {
                Text(desc)
                    .font(.caption)
                    .foregroundColor(Color.white.opacity(0.6))
                    .italic()
            }

            // Total Balance Card
            VStack(spacing: 8) {
                HStack {
                    Text("Total Balance")
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.6))
                    Spacer()
                    Text(account.totalValue.formatted(currencyCode: account.currencyCode))
                        .font(.title3.bold())
                        .foregroundColor(.white)
                }

                if let holdingsVal = account.holdingsValue, holdingsVal > 0 || (account.balance ?? 0) != account.totalValue {
                    Divider().background(Color.white.opacity(0.06))
                    HStack {
                        if let bal = account.balance {
                            Text("Cash: \(bal.formatted(currencyCode: account.currencyCode))")
                                .font(.caption2)
                                .foregroundColor(bal >= 0 ? Color.white.opacity(0.7) : Color(hex: "f87171"))
                        }
                        Spacer()
                        if let h = account.holdingsValue, h > 0 {
                            Text("Assets: \(h.formatted(currencyCode: account.currencyCode))")
                                .font(.caption2.bold())
                                .foregroundColor(Color(hex: "34d399"))
                        }
                    }
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.05), lineWidth: 1))

            // Direct Account Holdings (Stock & Crypto)
            AccountHoldingsSection(
                holdings: directHoldings,
                currencyCode: account.currencyCode,
                isLoading: isLoadingHoldings,
                onEditHolding: { holding in
                    editingHolding = holding
                },
                onDeleteHolding: { holdingId in
                    Task {
                        try? await HoldingService.shared.deleteHolding(id: holdingId)
                        await loadHoldings()
                    }
                }
            )

            // Sub-Accounts Section
            if !account.subAccountsList.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                isExpanded.toggle()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                                    .font(.caption2.bold())
                                Text("SUB-ACCOUNTS (\(account.subAccountsList.count))")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundColor(Color.white.opacity(0.5))
                        }

                        Spacer()

                        Button {
                            onAddSubAccount()
                        } label: {
                            HStack(spacing: 2) {
                                Image(systemName: "plus")
                                Text("Sub-Account")
                            }
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "a78bfa"))
                        }
                    }

                    if isExpanded {
                        VStack(spacing: 8) {
                            ForEach(Array(account.subAccountsList.enumerated()), id: \.element.id) { subIndex, sub in
                                SubAccountCardRow(
                                    subAccount: sub,
                                    account: account,
                                    onEdit: { onEditSubAccount(sub) },
                                    onDelete: { onDeleteSubAccount(sub) },
                                    onAddAsset: { onAddAssetToSubAccount(sub) },
                                    isReordering: isReordering && account.subAccountsList.count > 1,
                                    canMoveUp: subIndex > 0,
                                    canMoveDown: subIndex < account.subAccountsList.count - 1,
                                    onMoveUp: { onMoveSubAccountUp(sub, subIndex) },
                                    onMoveDown: { onMoveSubAccountDown(sub, subIndex) }
                                )
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(accentColor.opacity(0.35), lineWidth: 1.5)
        )
        .sheet(item: $editingHolding) { holding in
            EditAssetView(
                holding: holding,
                accounts: [account],
                onSuccess: {
                    Task { await loadHoldings() }
                }
            )
        }
        .task {
            await loadHoldings()
        }
    }

    private func loadHoldings() async {
        isLoadingHoldings = true
        defer { isLoadingHoldings = false }
        do {
            holdings = try await HoldingService.shared.getAccountHoldings(accountId: account.id)
        } catch {
            holdings = []
        }
    }
}

// MARK: - Sub Account Row
struct SubAccountCardRow: View {
    let subAccount: SubAccountResponse
    var account: AccountResponse? = nil
    var onEdit: () -> Void = {}
    var onDelete: () -> Void = {}
    var onAddAsset: () -> Void = {}

    var isReordering: Bool = false
    var canMoveUp: Bool = false
    var canMoveDown: Bool = false
    var onMoveUp: () -> Void = {}
    var onMoveDown: () -> Void = {}

    @State private var holdings: [HoldingResponse] = []
    @State private var isLoadingHoldings = false
    @State private var editingHolding: HoldingResponse? = nil

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "a78bfa"))
                    .frame(width: 28, height: 28)
                    .background(Color(hex: "a78bfa").opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 1) {
                    Text(subAccount.name)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    Text("\(subAccount.type.displayName) • \(subAccount.currencyCode)")
                        .font(.caption2)
                        .foregroundColor(Color.white.opacity(0.4))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text(subAccount.totalValue.formatted(currencyCode: subAccount.currencyCode))
                        .font(.subheadline.bold())
                        .foregroundColor(.white)

                    if (subAccount.holdingsValue ?? 0) > 0 {
                        Text(L10n.Accounts.holdingsFormatted((subAccount.holdingsValue ?? 0).formatted(currencyCode: subAccount.currencyCode)))
                            .font(.system(size: 9))
                            .foregroundColor(Color(hex: "34d399"))
                    }
                }

                if isReordering {
                    HStack(spacing: 4) {
                        Button {
                            onMoveUp()
                        } label: {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(canMoveUp ? Color(hex: "a78bfa") : Color.white.opacity(0.2))
                                .frame(width: 24, height: 24)
                                .background(Color(hex: "a78bfa").opacity(canMoveUp ? 0.15 : 0.05))
                                .clipShape(Circle())
                        }
                        .disabled(!canMoveUp)

                        Button {
                            onMoveDown()
                        } label: {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(canMoveDown ? Color(hex: "a78bfa") : Color.white.opacity(0.2))
                                .frame(width: 24, height: 24)
                                .background(Color(hex: "a78bfa").opacity(canMoveDown ? 0.15 : 0.05))
                                .clipShape(Circle())
                        }
                        .disabled(!canMoveDown)
                    }
                } else {
                    Menu {
                        Button {
                            onAddAsset()
                        } label: {
                            Label(L10n.Accounts.buyAddAsset, systemImage: "chart.line.uptrend.xyaxis")
                        }

                        Button {
                            onEdit()
                        } label: {
                            Label(L10n.Accounts.editSubAccount, systemImage: "pencil")
                        }

                        Divider()

                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Label(L10n.Accounts.deleteSubAccount, systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.caption.bold())
                            .foregroundColor(Color.white.opacity(0.3))
                            .padding(.horizontal, 4)
                    }
                }
            }

            // Subaccount holdings
            AccountHoldingsSection(
                holdings: holdings,
                currencyCode: subAccount.currencyCode,
                isLoading: isLoadingHoldings,
                onEditHolding: { holding in
                    editingHolding = holding
                },
                onDeleteHolding: { holdingId in
                    Task {
                        try? await HoldingService.shared.deleteHolding(id: holdingId)
                        await loadHoldings()
                    }
                }
            )
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.04), lineWidth: 1))
        .sheet(item: $editingHolding) { holding in
            EditAssetView(
                holding: holding,
                accounts: account != nil ? [account!] : [],
                onSuccess: {
                    Task { await loadHoldings() }
                }
            )
        }
        .task {
            await loadHoldings()
        }
    }

    private func loadHoldings() async {
        isLoadingHoldings = true
        defer { isLoadingHoldings = false }
        do {
            holdings = try await HoldingService.shared.getSubAccountHoldings(subAccountId: subAccount.id)
        } catch {
            holdings = []
        }
    }
}

// MARK: - Account Holdings Section
struct AccountHoldingsSection: View {
    let holdings: [HoldingResponse]
    let currencyCode: String
    let isLoading: Bool
    var onEditHolding: (HoldingResponse) -> Void = { _ in }
    var onDeleteHolding: (String) -> Void = { _ in }

    var body: some View {
        if !holdings.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label(L10n.Accounts.holdingsAndAssets, systemImage: "chart.pie.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.6))
                    Spacer()
                }

                VStack(spacing: 6) {
                    ForEach(holdings) { h in
                        let isGain = h.unrealizedPnL >= 0
                        HStack(spacing: 10) {
                            // Symbol icon badge
                            Text(h.instrumentSymbol.prefix(4))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(hex: "a78bfa"))
                                .frame(width: 32, height: 32)
                                .background(Color(hex: "a78bfa").opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 6))

                            VStack(alignment: .leading, spacing: 1) {
                                HStack(spacing: 4) {
                                    Text(h.instrumentSymbol)
                                        .font(.caption.bold())
                                        .foregroundColor(.white)
                                    Text(h.instrumentType)
                                        .font(.system(size: 8, weight: .bold))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(Color.white.opacity(0.07))
                                        .clipShape(Capsule())
                                        .foregroundColor(Color.white.opacity(0.6))
                                }
                                Text("\(formatQty(h.quantity)) @ \(h.averageBuyPrice.formatted(currencyCode: h.currencyCode))")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color.white.opacity(0.4))
                                if let notes = h.notes, !notes.isEmpty {
                                    Text(notes)
                                        .font(.system(size: 9))
                                        .foregroundColor(Color.white.opacity(0.35))
                                        .lineLimit(1)
                                }
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 1) {
                                Text(h.marketValue.formatted(currencyCode: h.currencyCode))
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                HStack(spacing: 2) {
                                    Image(systemName: isGain ? "arrow.up.right" : "arrow.down.right")
                                        .font(.system(size: 8, weight: .bold))
                                    Text(String(format: "%+.1f%%", h.unrealizedPnLPercent))
                                        .font(.system(size: 9, weight: .bold))
                                }
                                .foregroundColor(isGain ? Color(hex: "34d399") : Color(hex: "f87171"))
                            }

                            Button {
                                onEditHolding(h)
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(hex: "818cf8"))
                                    .padding(4)
                            }

                            Button {
                                onDeleteHolding(h.id)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color(hex: "f87171").opacity(0.7))
                                    .padding(4)
                            }
                        }
                        .padding(8)
                        .background(Color.white.opacity(0.02))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(.top, 4)
        }
    }

    private func formatQty(_ qty: Double) -> String {
        if qty.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", qty)
        } else {
            return String(format: "%.4f", qty)
        }
    }
}
