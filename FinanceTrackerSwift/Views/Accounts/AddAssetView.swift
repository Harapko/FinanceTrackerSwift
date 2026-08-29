import SwiftUI

struct AddAssetView: View {
    @Environment(\.dismiss) private var dismiss
    var defaultAccountId: String? = nil
    var defaultSubAccountId: String? = nil
    var onSuccess: (() -> Void) = {}

    @State private var accounts: [AccountResponse] = []
    @State private var selectedAccountId = ""
    @State private var selectedSubAccountId = ""

    @State private var symbol = ""
    @State private var instrumentType = "Crypto"
    @State private var quantity = ""
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

    let types = ["Crypto", "Stock"]
    let currencies = ["USD", "EUR", "GBP", "UAH", "PLN", "CAD", "CHF"]

    var selectedAccount: AccountResponse? {
        accounts.first { $0.id == selectedAccountId }
    }

    var availableSubAccounts: [SubAccountResponse] {
        selectedAccount?.subAccountsList ?? []
    }

    var totalCost: Double {
        let q = Double(quantity) ?? 0
        let p = Double(pricePerUnit) ?? 0
        let f = Double(fee) ?? 0
        return (q * p) + f
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0d1117").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Instrument Type
                        Picker("Type", selection: $instrumentType) {
                            ForEach(types, id: \.self) { t in
                                Text(t).tag(t)
                            }
                        }
                        .pickerStyle(.segmented)

                        // Symbol with Quote button
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Asset Symbol", systemImage: "magnifyingglass")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color.white.opacity(0.6))
                            HStack {
                                TextField("e.g. BTC, AAPL, ETH", text: $symbol)
                                    .textInputAutocapitalization(.characters)
                                    .autocorrectionDisabled()
                                    .textFieldStyle(.plain)
                                    .foregroundColor(.white)

                                if isFetchingQuote {
                                    ProgressView().tint(Color(hex: "a78bfa"))
                                } else {
                                    Button {
                                        Task { await fetchQuote() }
                                    } label: {
                                        Text("Quote")
                                            .font(.caption.weight(.bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Color(hex: "818cf8"))
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .disabled(symbol.trimmingCharacters(in: .whitespaces).isEmpty)
                                }
                            }
                            .padding(14)
                            .background(Color.white.opacity(0.07))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            if let quote = liveQuote {
                                HStack {
                                    Text("\(quote.symbol): \(quote.currentPrice.formatted(currencyCode: quote.currencyCode ?? currencyCode))")
                                        .font(.caption.bold())
                                        .foregroundColor(Color(hex: "34d399"))
                                    Spacer()
                                    Button("Use Price") {
                                        pricePerUnit = String(format: "%.4f", quote.currentPrice)
                                    }
                                    .font(.caption2.bold())
                                    .foregroundColor(Color(hex: "a78bfa"))
                                }
                                .padding(.horizontal, 4)
                            }
                        }

                        // Account Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Destination Account", systemImage: "building.columns")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color.white.opacity(0.6))
                            Picker("Account", selection: $selectedAccountId) {
                                Text("Select Account").tag("")
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

                        // Sub-Account Picker (if account has sub-accounts)
                        if !availableSubAccounts.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Sub-Account (Optional)", systemImage: "square.grid.2x2")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(Color.white.opacity(0.6))
                                Picker("Sub-Account", selection: $selectedSubAccountId) {
                                    Text("None (Direct to Account)").tag("")
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
                        HStack(spacing: 12) {
                            formField("Quantity", icon: "number") {
                                TextField("0.00", text: $quantity)
                                    .keyboardType(.decimalPad)
                            }

                            formField("Price / Unit", icon: "dollarsign.circle") {
                                TextField("0.00", text: $pricePerUnit)
                                    .keyboardType(.decimalPad)
                            }
                        }

                        // Currency & Fee
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Currency", systemImage: "coloncurrencysign.circle")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(Color.white.opacity(0.6))
                                Menu {
                                    ForEach(currencies, id: \.self) { c in
                                        Button(c) { currencyCode = c }
                                    }
                                } label: {
                                    HStack {
                                        Text(currencyCode)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(.white)
                                        Spacer()
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.caption2)
                                            .foregroundColor(Color(hex: "a78bfa"))
                                    }
                                    .padding(14)
                                    .background(Color.white.opacity(0.07))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }

                            formField("Fee", icon: "percent") {
                                TextField("0.00", text: $fee)
                                    .keyboardType(.decimalPad)
                            }
                        }

                        // Total Estimated Cost preview
                        if totalCost > 0 {
                            HStack {
                                Text("Total Cost:")
                                    .font(.subheadline)
                                    .foregroundColor(Color.white.opacity(0.7))
                                Spacer()
                                Text(totalCost.formatted(currencyCode: currencyCode))
                                    .font(.headline.bold())
                                    .foregroundColor(Color(hex: "34d399"))
                            }
                            .padding(14)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // Notes
                        formField("Notes (optional)", icon: "text.alignleft") {
                            TextField("Transaction notes...", text: $notes)
                        }

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
                                    Text("Buy / Add Asset")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "818cf8"), Color(hex: "a78bfa")],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(isLoading || symbol.trimmingCharacters(in: .whitespaces).isEmpty || quantity.isEmpty || pricePerUnit.isEmpty || selectedAccountId.isEmpty)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Buy / Add Asset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
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
            }
            .onChange(of: selectedAccountId) { _, newId in
                if let acc = accounts.first(where: { $0.id == newId }) {
                    currencyCode = acc.currencyCode
                }
            }
        }
    }

    private func fetchQuote() async {
        let sym = symbol.trimmingCharacters(in: .whitespaces).uppercased()
        guard !sym.isEmpty else { return }
        isFetchingQuote = true
        errorMessage = nil
        defer { isFetchingQuote = false }
        do {
            let quote = try await HoldingService.shared.getLiveQuote(symbol: sym, type: instrumentType)
            liveQuote = quote
            pricePerUnit = String(format: "%.4f", quote.currentPrice)
            if let cur = quote.currencyCode, !cur.isEmpty {
                currencyCode = cur
            }
        } catch {
            errorMessage = "Could not fetch quote: \(error.localizedDescription)"
        }
    }

    private func save() async {
        let sym = symbol.trimmingCharacters(in: .whitespaces).uppercased()
        guard !sym.isEmpty,
              let qty = Double(quantity), qty > 0,
              let price = Double(pricePerUnit), price > 0,
              !selectedAccountId.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            // 1. Ensure instrument exists on backend
            let instrument = try await HoldingService.shared.ensureInstrument(symbol: sym, type: instrumentType)

            // 2. Post instrument purchase transaction
            let payload = CreateInstrumentTransactionPayload(
                instrumentId: instrument.id,
                type: "Buy",
                quantity: qty,
                pricePerUnit: price,
                subAccountId: selectedSubAccountId.isEmpty ? nil : selectedSubAccountId,
                fee: Double(fee) ?? 0,
                currencyCode: currencyCode,
                date: date,
                time: time,
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
