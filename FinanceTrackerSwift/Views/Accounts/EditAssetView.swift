import SwiftUI

struct EditAssetView: View {
    let holding: HoldingResponse
    let accounts: [AccountResponse]
    var onSuccess: () -> Void = {}

    @Environment(\.dismiss) private var dismiss

    @State private var quantity: String = ""
    @State private var averageBuyPrice: String = ""
    @State private var selectedSubAccountId: String = ""
    @State private var notes: String = ""
    @State private var customName: String = ""
    @State private var liveQuote: MarketQuote?
    @State private var isFetchingQuote = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var parentAccount: AccountResponse? {
        accounts.first(where: { $0.id == holding.accountId })
    }

    private var availableSubAccounts: [SubAccountResponse] {
        parentAccount?.subAccounts ?? []
    }

    private var currentPrice: Double {
        if let q = liveQuote, q.resolvedPrice > 0 {
            return q.resolvedPrice
        }
        return holding.currentPrice > 0 ? holding.currentPrice : holding.averageBuyPrice
    }

    private var qtyNum: Double {
        Double(quantity.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private var avgPriceNum: Double {
        Double(averageBuyPrice.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private var marketValue: Double {
        qtyNum * currentPrice
    }

    private var costBasis: Double {
        qtyNum * avgPriceNum
    }

    private var unrealizedPnL: Double {
        marketValue - costBasis
    }

    private var unrealizedPnLPercent: Double {
        costBasis > 0 ? (unrealizedPnL / costBasis) * 100 : 0
    }

    private var isGain: Bool {
        unrealizedPnL >= 0
    }

    private var isCrypto: Bool {
        holding.instrumentType.lowercased().contains("crypto")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0f172a").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header Asset Info Card
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                Text(holding.instrumentSymbol.prefix(4))
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(isCrypto ? Color(hex: "f59e0b") : Color(hex: "818cf8"))
                                    .frame(width: 44, height: 44)
                                    .background(isCrypto ? Color(hex: "f59e0b").opacity(0.15) : Color(hex: "818cf8").opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))

                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 6) {
                                        Text(holding.instrumentSymbol)
                                            .font(.title3.bold())
                                            .foregroundColor(.white)
                                        Text(holding.instrumentType)
                                            .font(.system(size: 9, weight: .bold))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.white.opacity(0.08))
                                            .clipShape(Capsule())
                                            .foregroundColor(Color.white.opacity(0.7))
                                    }
                                    Text(holding.instrumentName)
                                        .font(.subheadline)
                                        .foregroundColor(Color.white.opacity(0.5))
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(currentPrice.formatted(currencyCode: holding.currencyCode))
                                        .font(.headline.bold())
                                        .foregroundColor(.white)
                                    Text(L10n.Assets.quote)
                                        .font(.system(size: 10))
                                        .foregroundColor(Color.white.opacity(0.4))
                                }
                            }
                        }
                        .padding(16)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "1e293b").opacity(0.8), Color(hex: "0f172a").opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(hex: "818cf8").opacity(0.2), lineWidth: 1)
                        )

                        // Form Section
                        VStack(spacing: 16) {
                            // Custom Asset Name
                            formField(L10n.Assets.assetName, icon: "tag.fill") {
                                TextField(holding.instrumentName, text: $customName)
                            }

                            // Portfolio / SubAccount Picker
                            if !availableSubAccounts.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Label(L10n.Assets.destinationSubAccount, systemImage: "folder.fill")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(Color.white.opacity(0.6))

                                    Picker("", selection: $selectedSubAccountId) {
                                        Text("No sub-account (\(parentAccount?.currencyCode ?? "USD"))")
                                            .tag("")
                                        ForEach(availableSubAccounts) { sub in
                                            Text("\(sub.name) (\(sub.currencyCode))")
                                                .tag(sub.id)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(14)
                                    .background(Color.white.opacity(0.07))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .foregroundColor(.white)
                                }
                            }

                            // Quantity
                            formField(L10n.Assets.quantity, icon: "number") {
                                TextField("0.00", text: $quantity)
                                    .keyboardType(.decimalPad)
                            }

                            // Average Buy Price with live quote button
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Label(L10n.Assets.avgBuyPrice, systemImage: "dollarsign.circle.fill")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(Color.white.opacity(0.6))
                                    Spacer()
                                    if let q = liveQuote, q.resolvedPrice > 0 {
                                        Button {
                                            averageBuyPrice = String(format: "%.4f", q.resolvedPrice)
                                        } label: {
                                            Text("\(L10n.Assets.usePrice) (\(q.resolvedPrice.formatted(currencyCode: holding.currencyCode)))")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(Color(hex: "818cf8"))
                                        }
                                    }
                                }

                                TextField("0.00", text: $averageBuyPrice)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.plain)
                                    .padding(14)
                                    .background(Color.white.opacity(0.07))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .foregroundColor(.white)
                            }

                            // Description / Notes
                            formField(L10n.Assets.notesOptional, icon: "note.text") {
                                TextField(L10n.Assets.notesPlaceholder, text: $notes)
                            }
                        }

                        // Real-Time Valuation & P&L Summary Box
                        VStack(spacing: 10) {
                            HStack {
                                Text(L10n.Assets.itemValue)
                                    .font(.subheadline)
                                    .foregroundColor(Color.white.opacity(0.6))
                                Spacer()
                                Text(marketValue.formatted(currencyCode: holding.currencyCode))
                                    .font(.title3.bold())
                                    .foregroundColor(.white)
                            }

                            Divider().background(Color.white.opacity(0.08))

                            HStack {
                                Text("Cost Basis:")
                                    .font(.caption)
                                    .foregroundColor(Color.white.opacity(0.4))
                                Spacer()
                                Text(costBasis.formatted(currencyCode: holding.currencyCode))
                                    .font(.caption.bold())
                                    .foregroundColor(Color.white.opacity(0.7))
                            }

                            HStack {
                                Text("Unrealized P&L:")
                                    .font(.caption)
                                    .foregroundColor(Color.white.opacity(0.4))
                                Spacer()
                                HStack(spacing: 4) {
                                    Image(systemName: isGain ? "arrow.up.right" : "arrow.down.right")
                                        .font(.system(size: 10, weight: .bold))
                                    Text("\(isGain ? "+" : "")\(unrealizedPnL.formatted(currencyCode: holding.currencyCode)) (\(String(format: "%+.1f%%", unrealizedPnLPercent)))")
                                        .font(.caption.bold())
                                }
                                .foregroundColor(isGain ? Color(hex: "34d399") : Color(hex: "f87171"))
                            }
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))

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

                        // Save Button
                        Button {
                            Task { await save() }
                        } label: {
                            Group {
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text(L10n.Profile.saveChanges)
                                        .font(.headline.bold())
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "818cf8"), Color(hex: "a78bfa")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(isLoading || qtyNum < 0 || avgPriceNum < 0)
                    }
                    .padding(20)
                }
            }
            .navigationTitle(L10n.Assets.editAssetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) { dismiss() }
                        .foregroundColor(Color(hex: "a78bfa"))
                }
            }
            .task {
                quantity = holding.quantity.truncatingRemainder(dividingBy: 1) == 0 ?
                    String(format: "%.0f", holding.quantity) :
                    String(format: "%.4f", holding.quantity)
                averageBuyPrice = String(format: "%.4f", holding.averageBuyPrice)
                selectedSubAccountId = holding.subAccountId ?? ""
                notes = holding.notes ?? ""
                customName = holding.instrumentName

                // Fetch quote
                do {
                    liveQuote = try await HoldingService.shared.getLiveQuote(
                        symbol: holding.instrumentSymbol,
                        type: holding.instrumentType
                    )
                } catch {}
            }
        }
    }

    private func save() async {
        guard qtyNum >= 0, avgPriceNum >= 0 else {
            errorMessage = "Quantity and average price must be non-negative."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let payload = UpdateHoldingPayload(
                quantity: qtyNum,
                averageBuyPrice: avgPriceNum,
                subAccountId: selectedSubAccountId.isEmpty ? nil : selectedSubAccountId,
                notes: notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces),
                customName: customName.trimmingCharacters(in: .whitespaces).isEmpty ? nil : customName.trimmingCharacters(in: .whitespaces)
            )

            _ = try await HoldingService.shared.updateHolding(id: holding.id, payload: payload)
            onSuccess()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @ViewBuilder
    private func formField<Content: View>(
        _ label: String, icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(label, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundColor(Color.white.opacity(0.6))
            content()
                .textFieldStyle(.plain)
                .padding(14)
                .background(Color.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .foregroundColor(.white)
        }
    }
}
