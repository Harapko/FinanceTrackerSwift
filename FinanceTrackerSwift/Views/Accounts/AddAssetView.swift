import SwiftUI

struct AddAssetView: View {
    @Environment(\.dismiss) private var dismiss
    var defaultAccountId: String? = nil
    var defaultSubAccountId: String? = nil
    var onSuccess: (() -> Void) = {}

    @State private var accounts: [AccountResponse] = []
    @State private var selectedAccountId = ""
    @State private var selectedSubAccountId = ""

    @State private var tradeType = "Buy"
    @State private var instrumentType = "Stock"
    @State private var symbol = "VOO"
    @State private var quantity = "1"
    @State private var pricePerUnit = ""
    @State private var fee = "0"
    @State private var currencyCode = "USD"
    @State private var notes = ""
    @State private var date = ""
    @State private var time = ""

    @State private var liveQuote: MarketQuote? = nil
    @State private var isFetchingQuote = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    let tradeTypes = ["Buy", "Sell"]
    let instrumentTypes = ["Stock", "Crypto"]
    let stockSuggestions = ["VOO", "SPY", "AAPL", "NVDA", "TSLA", "MSFT", "GOOGL", "AMZN"]
    let cryptoSuggestions = ["BTC", "ETH", "SOL", "BNB", "XRP", "ADA", "DOGE"]
    let quantityPresets = ["1", "2", "5", "10", "25", "50", "100"]

    var activeSymbol: String {
        symbol.trimmingCharacters(in: .whitespaces).uppercased()
    }

    var selectedAccount: AccountResponse? {
        accounts.first { $0.id == selectedAccountId }
    }

    var availableSubAccounts: [SubAccountResponse] {
        selectedAccount?.subAccountsList ?? []
    }

    var totalCost: Double {
        let q = Double(quantity) ?? 1
        let p = Double(pricePerUnit) ?? (liveQuote?.resolvedPrice ?? 0)
        let f = Double(fee) ?? 0
        return (q * p) + f
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0d1117").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        // Trade Type (Buy / Sell)
                        Picker("Trade Type", selection: $tradeType) {
                            ForEach(tradeTypes, id: \.self) { t in
                                Text(t).tag(t)
                            }
                        }
                        .pickerStyle(.segmented)

                        // Instrument Type (Stock / Crypto)
                        Picker(L10n.Assets.assetType, selection: $instrumentType) {
                            ForEach(instrumentTypes, id: \.self) { t in
                                Text(t == "Crypto" ? L10n.Assets.crypto : L10n.Assets.stock).tag(t)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: instrumentType) { _, newType in
                            symbol = newType == "Crypto" ? "BTC" : "VOO"
                            Task { await fetchQuote() }
                        }

                        // Symbol with Quote button
                        VStack(alignment: .leading, spacing: 8) {
                            Label(L10n.Assets.symbol, systemImage: "magnifyingglass")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color.white.opacity(0.6))

                            HStack(spacing: 8) {
                                TextField(instrumentType == "Crypto" ? "e.g. BTC, ETH, SOL" : "e.g. VOO, AAPL, NVDA", text: $symbol)
                                    .textInputAutocapitalization(.characters)
                                    .autocorrectionDisabled()
                                    .textFieldStyle(.plain)
                                    .foregroundColor(.white)
                                    .onSubmit {
                                        Task { await fetchQuote() }
                                    }

                                if isFetchingQuote {
                                    ProgressView().tint(Color(hex: "a78bfa"))
                                } else {
                                    Button {
                                        Task { await fetchQuote() }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "bolt.fill")
                                                .font(.system(size: 10))
                                            Text(L10n.Assets.quote)
                                                .font(.caption.weight(.bold))
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(Color(hex: "818cf8"))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .disabled(activeSymbol.isEmpty)
                                }
                            }
                            .padding(14)
                            .background(Color.white.opacity(0.07))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            // Quick Suggestions
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(instrumentType == "Crypto" ? cryptoSuggestions : stockSuggestions, id: \.self) { sug in
                                        Button {
                                            symbol = sug
                                            Task { await fetchQuote() }
                                        } label: {
                                            Text(sug)
                                                .font(.caption2.bold())
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(activeSymbol == sug ? Color(hex: "818cf8").opacity(0.3) : Color.white.opacity(0.06))
                                                .foregroundColor(activeSymbol == sug ? Color(hex: "a78bfa") : Color.white.opacity(0.7))
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 2)

                            // Live Quote Preview Banner
                            if let quote = liveQuote {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(quote.name ?? quote.symbol)
                                            .font(.caption.weight(.bold))
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                        HStack(spacing: 6) {
                                            Text(quote.resolvedPrice.formatted(currencyCode: quote.currencyCode ?? currencyCode))
                                                .font(.subheadline.bold())
                                                .foregroundColor(Color(hex: "34d399"))

                                            if let changePercent = quote.changePercent {
                                                let isGain = changePercent >= 0
                                                Text(String(format: "%+.2f%%", changePercent))
                                                    .font(.caption2.bold())
                                                    .foregroundColor(isGain ? Color(hex: "34d399") : Color(hex: "f87171"))
                                            }
                                        }
                                    }

                                    Spacer()

                                    Button {
                                        pricePerUnit = String(format: "%.4f", quote.resolvedPrice)
                                        if let cur = quote.currencyCode, !cur.isEmpty {
                                            currencyCode = cur
                                        }
                                    } label: {
                                        Text(L10n.Assets.usePrice)
                                            .font(.caption.bold())
                                            .foregroundColor(Color(hex: "a78bfa"))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(Color(hex: "a78bfa").opacity(0.12))
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(12)
                                .background(Color(hex: "34d399").opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "34d399").opacity(0.2), lineWidth: 1))
                            }
                        }

                        // Destination Account
                        VStack(alignment: .leading, spacing: 8) {
                            Label(L10n.Assets.destinationAccount, systemImage: "building.columns")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color.white.opacity(0.6))
                            Picker("Account", selection: $selectedAccountId) {
                                Text(L10n.Transactions.selectAccount).tag("")
                                ForEach(accounts) { a in
                                    Text("\(a.name) (\(a.currencyCode))").tag(a.id)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(12)
                            .background(Color.white.opacity(0.07))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // Sub-Account (if available)
                        if !availableSubAccounts.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Sub-Account (Optional)", systemImage: "square.grid.2x2")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(Color.white.opacity(0.6))
                                Picker("Sub-Account", selection: $selectedSubAccountId) {
                                    Text("Direct to Account").tag("")
                                    ForEach(availableSubAccounts) { s in
                                        Text("\(s.name) (\(s.currencyCode))").tag(s.id)
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding(12)
                                .background(Color.white.opacity(0.07))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                        // Quantity & Price Row
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 12) {
                                formField(L10n.Assets.quantity, icon: "number") {
                                    TextField("1", text: $quantity)
                                        .keyboardType(.decimalPad)
                                }

                                formField("Price / Unit (\(currencyCode))", icon: "dollarsign.circle") {
                                    TextField(liveQuote != nil ? String(format: "%.2f", liveQuote!.resolvedPrice) : "0.00", text: $pricePerUnit)
                                        .keyboardType(.decimalPad)
                                }
                            }

                            // Quick Quantity Presets
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    Text("Qty:")
                                        .font(.caption2)
                                        .foregroundColor(Color.white.opacity(0.4))
                                    ForEach(quantityPresets, id: \.self) { q in
                                        Button {
                                            quantity = q
                                        } label: {
                                            Text(q)
                                                .font(.caption2.bold())
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 3)
                                                .background(quantity == q ? Color(hex: "818cf8").opacity(0.3) : Color.white.opacity(0.06))
                                                .foregroundColor(quantity == q ? Color(hex: "a78bfa") : Color.white.opacity(0.7))
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                            }
                        }

                        // Fee & Date Row
                        HStack(spacing: 12) {
                            formField("Fee", icon: "percent") {
                                TextField("0.00", text: $fee)
                                    .keyboardType(.decimalPad)
                            }

                            formField("Date", icon: "calendar") {
                                TextField("YYYY-MM-DD", text: $date)
                            }
                        }

                        // Notes
                        formField(L10n.Assets.notesOptional, icon: "text.alignleft") {
                            TextField("e.g. Vanguard ETF purchase, DCA...", text: $notes)
                        }

                        // Total Cost Card
                        if totalCost > 0 {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Estimated Total:")
                                        .font(.caption)
                                        .foregroundColor(Color.white.opacity(0.6))
                                    Text("\(quantity.isEmpty ? "1" : quantity) × \(pricePerUnit.isEmpty ? (liveQuote != nil ? String(format: "%.2f", liveQuote!.resolvedPrice) : "0.00") : pricePerUnit) \(currencyCode)")
                                        .font(.caption2)
                                        .foregroundColor(Color.white.opacity(0.4))
                                }
                                Spacer()
                                Text(totalCost.formatted(currencyCode: currencyCode))
                                    .font(.title3.bold())
                                    .foregroundColor(tradeType == "Buy" ? Color(hex: "34d399") : Color(hex: "f87171"))
                            }
                            .padding(14)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
                        }

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

                        // Submit Button
                        Button {
                            Task { await save() }
                        } label: {
                            Group {
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("\(tradeType) \(activeSymbol.isEmpty ? "Asset" : activeSymbol)")
                                        .font(.headline.bold())
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(
                                tradeType == "Buy" ?
                                    LinearGradient(colors: [Color(hex: "818cf8"), Color(hex: "a78bfa")],
                                                   startPoint: .leading, endPoint: .trailing) :
                                    LinearGradient(colors: [Color(hex: "f87171"), Color(hex: "ef4444")],
                                                   startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(isLoading || activeSymbol.isEmpty || selectedAccountId.isEmpty)
                    }
                    .padding(20)
                }
            }
            .navigationTitle(L10n.Assets.addAssetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) { dismiss() }
                        .foregroundColor(Color(hex: "a78bfa"))
                }
            }
            .task {
                do {
                    accounts = try await AccountService.shared.getAccounts()
                    if let defAcc = defaultAccountId, accounts.contains(where: { $0.id == defAcc }) {
                        selectedAccountId = defAcc
                    } else if let first = accounts.first {
                        selectedAccountId = first.id
                    }
                    if let defSub = defaultSubAccountId {
                        selectedSubAccountId = defSub
                    }
                    if let acc = selectedAccount {
                        currencyCode = acc.currencyCode
                    }
                } catch {}

                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                date = formatter.string(from: Date())
                formatter.dateFormat = "HH:mm:ss"
                time = formatter.string(from: Date())

                // Auto fetch initial quote
                await fetchQuote()
            }
            .onChange(of: selectedAccountId) { _, newId in
                if let acc = accounts.first(where: { $0.id == newId }) {
                    currencyCode = acc.currencyCode
                }
            }
        }
    }

    private func fetchQuote() async {
        let sym = activeSymbol
        guard !sym.isEmpty else { return }
        isFetchingQuote = true
        errorMessage = nil
        defer { isFetchingQuote = false }
        do {
            let quote = try await HoldingService.shared.getLiveQuote(symbol: sym, type: instrumentType)
            liveQuote = quote
            if pricePerUnit.isEmpty || pricePerUnit == "0.00" || pricePerUnit == "0" {
                pricePerUnit = String(format: "%.4f", quote.resolvedPrice)
            }
            if let cur = quote.currencyCode, !cur.isEmpty {
                currencyCode = cur
            }
        } catch {
            errorMessage = "Could not fetch quote: \(error.localizedDescription)"
        }
    }

    private func save() async {
        let sym = activeSymbol
        guard !sym.isEmpty, !selectedAccountId.isEmpty else { return }

        // Ensure price is resolved
        var finalPrice = Double(pricePerUnit) ?? 0
        if finalPrice <= 0 {
            if let q = liveQuote, q.resolvedPrice > 0 {
                finalPrice = q.resolvedPrice
            } else {
                // Fetch quote on the fly
                do {
                    let q = try await HoldingService.shared.getLiveQuote(symbol: sym, type: instrumentType)
                    finalPrice = q.resolvedPrice
                } catch {
                    errorMessage = "Please enter a price per unit or tap Quote."
                    return
                }
            }
        }

        let finalQty = Double(quantity) ?? 1.0
        guard finalQty > 0, finalPrice > 0 else {
            errorMessage = "Please enter a valid quantity and price."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            // 1. Ensure instrument exists on backend
            let instrument = try await HoldingService.shared.ensureInstrument(symbol: sym, type: instrumentType)

            // 2. Post instrument transaction
            let payload = CreateInstrumentTransactionPayload(
                instrumentId: instrument.id,
                type: tradeType,
                quantity: finalQty,
                pricePerUnit: finalPrice,
                subAccountId: selectedSubAccountId.isEmpty ? nil : selectedSubAccountId,
                fee: Double(fee) ?? 0,
                currencyCode: currencyCode,
                date: date,
                time: time.isEmpty ? "12:00:00" : time,
                notes: notes.isEmpty ? nil : notes
            )
            try await HoldingService.shared.createInstrumentTransaction(
                accountId: selectedAccountId,
                subAccountId: selectedSubAccountId.isEmpty ? nil : selectedSubAccountId,
                payload: payload
            )
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
