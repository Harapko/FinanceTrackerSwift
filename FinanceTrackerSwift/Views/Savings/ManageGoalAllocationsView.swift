import SwiftUI

struct ManageGoalAllocationsView: View {
    @Environment(\.dismiss) private var dismiss
    let goalId: String
    var onUpdate: () -> Void = {}

    @State private var goal: SavingsGoalResponse? = nil
    @State private var selectedTab = 0 // 0: Assets, 1: History, 2: Withdraw
    @State private var isLoading = false
    @State private var isActionLoading = false
    @State private var errorMessage: String?

    // Withdraw state
    @State private var withdrawAmount = ""
    @State private var withdrawNote = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0d1117").ignoresSafeArea()

                if let currentGoal = goal {
                    ScrollView {
                        VStack(spacing: 18) {
                            // Goal Header Summary
                            VStack(spacing: 8) {
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: currentGoal.color ?? "818cf8").opacity(0.2))
                                            .frame(width: 44, height: 44)
                                        Text(currentGoal.icon ?? "🎯")
                                            .font(.title3)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(currentGoal.name)
                                            .font(.headline.bold())
                                            .foregroundColor(.white)
                                        Text("\(L10n.Dashboard.totalBalance): \(currentGoal.currentAmount.formatted(currencyCode: currentGoal.currencyCode))")
                                            .font(.caption)
                                            .foregroundColor(Color.white.opacity(0.6))
                                    }
                                    Spacer()
                                    if currentGoal.targetAmount > 0 {
                                        Text(String(format: "%.0f%%", (currentGoal.currentAmount / currentGoal.targetAmount) * 100))
                                            .font(.subheadline.bold())
                                            .foregroundColor(Color(hex: "a78bfa"))
                                    }
                                }
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                            // Segmented Tabs
                            Picker("Section", selection: $selectedTab) {
                                Text(L10n.Savings.tabAllocations).tag(0)
                                Text("\(L10n.Savings.tabHistory) (\(currentGoal.contributionsList.count))").tag(1)
                                Text(L10n.Savings.tabWithdraw).tag(2)
                            }
                            .pickerStyle(.segmented)

                            // Error Banner
                            if let error = errorMessage {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                    Text(error).font(.caption)
                                }
                                .foregroundColor(Color(hex: "f87171"))
                                .padding(12)
                                .background(Color(hex: "f87171").opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }

                            // Tab Content
                            switch selectedTab {
                            case 0:
                                holdingsTab(currentGoal)
                            case 1:
                                historyTab(currentGoal)
                            case 2:
                                withdrawTab(currentGoal)
                            default:
                                EmptyView()
                            }
                        }
                        .padding(20)
                    }
                } else if isLoading {
                    ProgressView().tint(Color(hex: "a78bfa"))
                }
            }
            .navigationTitle(L10n.Savings.manageAllocations)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.close) { dismiss() }
                        .foregroundColor(Color(hex: "a78bfa"))
                }
            }
            .task {
                await loadGoal()
            }
        }
    }

    // MARK: - Tab 1: Holdings & Allocations
    @ViewBuilder
    private func holdingsTab(_ g: SavingsGoalResponse) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Saved Instruments List
            if !g.savedInstrumentsList.isEmpty {
                Text("\(L10n.Savings.allocatedAssets.uppercased()) (\(g.savedInstrumentsList.count))")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.5))

                VStack(spacing: 8) {
                    ForEach(g.savedInstrumentsList) { inst in
                        let isGain = (inst.unrealizedPnL ?? 0) >= 0
                        HStack(spacing: 12) {
                            // Symbol badge
                            Text(inst.symbol.prefix(4))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(hex: "a78bfa"))
                                .frame(width: 38, height: 38)
                                .background(Color(hex: "a78bfa").opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(inst.symbol)
                                        .font(.subheadline.bold())
                                        .foregroundColor(.white)
                                    Text(inst.type)
                                        .font(.system(size: 8, weight: .bold))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(Color.white.opacity(0.08))
                                        .clipShape(Capsule())
                                        .foregroundColor(Color.white.opacity(0.6))
                                }
                                Text("\(formatQty(inst.totalQuantity)) shares @ \(inst.totalAmount.formatted(currencyCode: g.currencyCode))")
                                    .font(.caption2)
                                    .foregroundColor(Color.white.opacity(0.5))
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(inst.totalAmount.formatted(currencyCode: g.currencyCode))
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)

                                if let pnlPercent = inst.unrealizedPnLPercent {
                                    HStack(spacing: 2) {
                                        Image(systemName: isGain ? "arrow.up.right" : "arrow.down.right")
                                            .font(.system(size: 8, weight: .bold))
                                        Text(String(format: "%+.1f%%", pnlPercent))
                                            .font(.system(size: 10, weight: .bold))
                                    }
                                    .foregroundColor(isGain ? Color(hex: "34d399") : Color(hex: "f87171"))
                                }
                            }

                            if let instId = inst.instrumentId {
                                Button(role: .destructive) {
                                    Task { await removeInstrument(instId) }
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.caption)
                                        .foregroundColor(Color(hex: "f87171"))
                                        .padding(8)
                                        .background(Color(hex: "f87171").opacity(0.1))
                                        .clipShape(Circle())
                                }
                            }
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.03))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 32))
                        .foregroundColor(Color.white.opacity(0.2))
                    Text(L10n.Savings.noAllocationsInGoal)
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            }
        }
    }

    // MARK: - Tab 2: Contribution History
    @ViewBuilder
    private func historyTab(_ g: SavingsGoalResponse) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if g.contributionsList.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 32))
                        .foregroundColor(Color.white.opacity(0.2))
                    Text(L10n.Savings.noContributionsYet)
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                ForEach(g.contributionsList) { c in
                    let isCash = c.instrumentId == nil || c.instrumentSymbol == "CASH"
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(isCash ? Color(hex: "34d399").opacity(0.15) : Color(hex: "a78bfa").opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: isCash ? "banknote" : "chart.line.uptrend.xyaxis")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(isCash ? Color(hex: "34d399") : Color(hex: "a78bfa"))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(isCash ? L10n.Savings.cashDeposit : (c.instrumentSymbol ?? L10n.Accounts.addAsset))
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                if let q = c.quantity {
                                    Text("(\(formatQty(q)) @ \(c.unitPrice?.formatted(currencyCode: c.assetCurrencyCode ?? g.currencyCode) ?? ""))")
                                        .font(.caption2)
                                        .foregroundColor(Color.white.opacity(0.5))
                                }
                            }
                            if let note = c.note, !note.isEmpty {
                                Text(note)
                                    .font(.caption2)
                                    .foregroundColor(Color.white.opacity(0.4))
                                    .italic()
                            }
                        }

                        Spacer()

                        Text("+\(c.amount.formatted(currencyCode: g.currencyCode))")
                            .font(.subheadline.bold())
                            .foregroundColor(Color(hex: "34d399"))

                        Button(role: .destructive) {
                            Task { await deleteContribution(c.id) }
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption2)
                                .foregroundColor(Color(hex: "f87171"))
                                .padding(6)
                                .background(Color(hex: "f87171").opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    // MARK: - Tab 3: Withdraw
    @ViewBuilder
    private func withdrawTab(_ g: SavingsGoalResponse) -> some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Label("\(L10n.Savings.withdrawAmount) (\(g.currencyCode))", systemImage: "arrow.down.circle")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color.white.opacity(0.6))
                TextField("0.00", text: $withdrawAmount)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.plain)
                    .padding(14)
                    .background(Color.white.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .foregroundColor(.white)
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 8) {
                Label(L10n.Assets.notesOptional, systemImage: "text.alignleft")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color.white.opacity(0.6))
                TextField(L10n.Savings.withdrawReasonPlaceholder, text: $withdrawNote)
                    .textFieldStyle(.plain)
                    .padding(14)
                    .background(Color.white.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .foregroundColor(.white)
            }

            Button {
                Task { await performWithdraw() }
            } label: {
                Group {
                    if isActionLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text(L10n.Savings.withdrawFromGoal)
                            .font(.headline.bold())
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(Color(hex: "f87171"))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(isActionLoading || (Double(withdrawAmount) ?? 0) <= 0)
        }
    }

    // MARK: - Actions
    private func loadGoal() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            goal = try await SavingsGoalService.shared.getGoal(id: goalId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func removeInstrument(_ instrumentId: String) async {
        isActionLoading = true
        errorMessage = nil
        defer { isActionLoading = false }
        do {
            goal = try await SavingsGoalService.shared.removeInstrument(goalId: goalId, instrumentId: instrumentId)
            onUpdate()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteContribution(_ contributionId: String) async {
        isActionLoading = true
        errorMessage = nil
        defer { isActionLoading = false }
        do {
            goal = try await SavingsGoalService.shared.deleteContribution(goalId: goalId, contributionId: contributionId)
            onUpdate()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func performWithdraw() async {
        guard let amt = Double(withdrawAmount), amt > 0 else { return }
        isActionLoading = true
        errorMessage = nil
        defer { isActionLoading = false }
        do {
            let payload = WithdrawSavingsGoalPayload(amount: amt, note: withdrawNote.isEmpty ? nil : withdrawNote)
            goal = try await SavingsGoalService.shared.withdraw(goalId: goalId, payload: payload)
            withdrawAmount = ""
            withdrawNote = ""
            selectedTab = 0
            onUpdate()
        } catch {
            errorMessage = error.localizedDescription
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
