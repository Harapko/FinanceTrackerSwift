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

    @State private var isExpanded = true
    @State private var holdings: [HoldingResponse] = []
    @State private var isLoadingHoldings = false

    var accentColor: Color {
        Color(hex: account.color ?? "#818cf8")
    }

    var isInvestmentAccount: Bool {
        account.type == .investmentAccount || account.type == .cryptoWallet
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header: Avatar, Name, Type, Actions
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: account.type.icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(accentColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(account.name)
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text("\(account.type.displayName) • \(account.currencyCode)")
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.5))
                }

                Spacer()

                // Action buttons
                HStack(spacing: 6) {
                    if isInvestmentAccount {
                        Button {
                            onAddAsset()
                        } label: {
                            Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color(hex: "34d399"))
                        }
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
                            onEdit()
                        } label: {
                            Label("Edit Account", systemImage: "pencil")
                        }

                        if isInvestmentAccount {
                            Button {
                                onAddAsset()
                            } label: {
                                Label("Add / Buy Asset", systemImage: "plus.app")
                            }
                        }

                        Button {
                            onAddSubAccount()
                        } label: {
                            Label("Add Sub-Account", systemImage: "plus.rectangle.on.rectangle")
                        }

                        Divider()

                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Label("Delete Account", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.4))
                            .padding(6)
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

            // Direct Account Holdings (if investment account)
            if isInvestmentAccount {
                AccountHoldingsSection(
                    holdings: holdings,
                    currencyCode: account.currencyCode,
                    isLoading: isLoadingHoldings,
                    onDeleteHolding: { holdingId in
                        Task {
                            try? await HoldingService.shared.deleteHolding(id: holdingId)
                            await loadHoldings()
                        }
                    }
                )
            }

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
                            ForEach(account.subAccountsList) { sub in
                                SubAccountCardRow(
                                    subAccount: sub,
                                    onEdit: { onEditSubAccount(sub) },
                                    onDelete: { onDeleteSubAccount(sub) },
                                    onAddAsset: { onAddAssetToSubAccount(sub) }
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
        .task {
            if isInvestmentAccount {
                await loadHoldings()
            }
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
    var onEdit: () -> Void = {}
    var onDelete: () -> Void = {}
    var onAddAsset: () -> Void = {}

    @State private var holdings: [HoldingResponse] = []
    @State private var isExpanded = false
    @State private var isLoadingHoldings = false

    var isInvestment: Bool {
        subAccount.type == .investment
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(subAccount.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                        Text(subAccount.type.displayName)
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Capsule())
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                    if let desc = subAccount.description, !desc.isEmpty {
                        Text(desc)
                            .font(.caption2)
                            .foregroundColor(Color.white.opacity(0.4))
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(subAccount.totalValue.formatted(currencyCode: subAccount.currencyCode))
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.white)

                    if (subAccount.holdingsValue ?? 0) > 0 {
                        Text("Holdings: \((subAccount.holdingsValue ?? 0).formatted(currencyCode: subAccount.currencyCode))")
                            .font(.system(size: 9))
                            .foregroundColor(Color(hex: "34d399"))
                    }
                }

                Menu {
                    Button {
                        onEdit()
                    } label: {
                        Label("Edit Sub-Account", systemImage: "pencil")
                    }

                    if isInvestment {
                        Button {
                            onAddAsset()
                        } label: {
                            Label("Buy / Add Asset", systemImage: "chart.line.uptrend.xyaxis")
                        }
                    }

                    Divider()

                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete Sub-Account", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption.bold())
                        .foregroundColor(Color.white.opacity(0.3))
                        .padding(.horizontal, 4)
                }
            }

            // Subaccount holdings
            if isInvestment && !holdings.isEmpty {
                AccountHoldingsSection(
                    holdings: holdings,
                    currencyCode: subAccount.currencyCode,
                    isLoading: isLoadingHoldings,
                    onDeleteHolding: { holdingId in
                        Task {
                            try? await HoldingService.shared.deleteHolding(id: holdingId)
                            await loadHoldings()
                        }
                    }
                )
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.04), lineWidth: 1))
        .task {
            if isInvestment {
                await loadHoldings()
            }
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
    var onDeleteHolding: (String) -> Void = { _ in }

    var body: some View {
        if !holdings.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label("Holdings & Assets", systemImage: "chart.pie.fill")
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
