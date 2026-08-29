import SwiftUI

enum ContributionItemType: String, CaseIterable {
    case cash = "Cash"
    case stock = "Stock"
    case crypto = "Crypto"
}

struct ContributionFormItem: Identifiable {
    let id = UUID()
    var type: ContributionItemType = .cash
    var symbol: String = "VOO"
    var quantity: String = "1"
    var unitPrice: String = ""
    var cashAmount: String = ""
    var fee: String = "0"
    var currencyCode: String = "USD"
    var note: String = ""

    var liveQuote: MarketQuote? = nil
    var isFetchingQuote: Bool = false
    var instrumentId: String? = nil

    var calculatedAmount: Double {
        switch type {
        case .cash:
            return Double(cashAmount) ?? 0
        case .stock, .crypto:
            let q = Double(quantity) ?? 1
            let p = Double(unitPrice) ?? (liveQuote?.resolvedPrice ?? 0)
            let f = Double(fee) ?? 0
            return (q * p) + f
        }
    }
}

struct ContributeToGoalView: View {
    @Environment(\.dismiss) private var dismiss
    let goal: SavingsGoalResponse
    var onSuccess: () -> Void

    @State private var items: [ContributionFormItem] = [
        ContributionFormItem(type: .cash, cashAmount: "100")
    ]
    @State private var generalNote: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    let stockSuggestions = ["VOO", "SPY", "AAPL", "NVDA", "TSLA", "MSFT", "GOOGL"]
    let cryptoSuggestions = ["BTC", "ETH", "SOL", "BNB", "XRP"]

    var totalContribution: Double {
        items.reduce(0) { $0 + $1.calculatedAmount }
    }

    var projectedTotal: Double {
        goal.currentAmount + totalContribution
    }

    var currentProgress: Double {
        goal.targetAmount > 0 ? min(goal.currentAmount / goal.targetAmount, 1.0) : 0
    }

    var projectedProgress: Double {
        goal.targetAmount > 0 ? min(projectedTotal / goal.targetAmount, 1.0) : 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0d1117").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Goal Header Card
                        VStack(spacing: 12) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: goal.color ?? "818cf8").opacity(0.2))
                                        .frame(width: 44, height: 44)
                                    Text(goal.icon ?? "🎯")
                                        .font(.title3)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(goal.name)
                                        .font(.headline.bold())
                                        .foregroundColor(.white)
                                    Text("Saved: \(goal.currentAmount.formatted(currencyCode: goal.currencyCode)) of \(goal.targetAmount.formatted(currencyCode: goal.currencyCode))")
                                        .font(.caption)
                                        .foregroundColor(Color.white.opacity(0.6))
                                }
                                Spacer()
                                if goal.targetAmount > 0 {
                                    Text(String(format: "%.0f%%", currentProgress * 100))
                                        .font(.subheadline.bold())
                                        .foregroundColor(Color(hex: "a78bfa"))
                                }
                            }

                            // Progress Bar with Projected Gain
                            if goal.targetAmount > 0 {
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.white.opacity(0.1))
                                            .frame(height: 8)

                                        // Projected fill
                                        if projectedProgress > currentProgress {
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color(hex: "34d399").opacity(0.5))
                                                .frame(width: geo.size.width * projectedProgress, height: 8)
                                        }

                                        // Current fill
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(LinearGradient(
                                                colors: [Color(hex: goal.color ?? "818cf8"), Color(hex: "a78bfa")],
                                                startPoint: .leading, endPoint: .trailing
                                            ))
                                            .frame(width: geo.size.width * currentProgress, height: 8)
                                    }
                                }
                                .frame(height: 8)
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.06), lineWidth: 1))

                        // Contribution Items List
                        VStack(spacing: 14) {
                            ForEach($items) { $item in
                                ContributionItemCard(
                                    item: $item,
                                    goalCurrency: goal.currencyCode,
                                    canRemove: items.count > 1,
                                    onRemove: {
                                        if let idx = items.firstIndex(where: { $0.id == item.id }) {
                                            items.remove(at: idx)
                                        }
                                    }
                                )
                            }
                        }

                        // Add More Items Buttons
                        HStack(spacing: 10) {
                            Button {
                                items.append(ContributionFormItem(type: .stock, symbol: "VOO", quantity: "1"))
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                    Text("+ Add Stock")
                                }
                                .font(.caption.bold())
                                .foregroundColor(Color(hex: "a78bfa"))
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color(hex: "a78bfa").opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "a78bfa").opacity(0.3), lineWidth: 1))
                            }

                            Button {
                                items.append(ContributionFormItem(type: .crypto, symbol: "BTC", quantity: "0.01"))
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "bitcoinsign.circle")
                                    Text("+ Add Crypto")
                                }
                                .font(.caption.bold())
                                .foregroundColor(Color(hex: "fbbf24"))
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color(hex: "fbbf24").opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "fbbf24").opacity(0.3), lineWidth: 1))
                            }

                            Button {
                                items.append(ContributionFormItem(type: .cash, cashAmount: "50"))
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "banknote")
                                    Text("+ Add Cash")
                                }
                                .font(.caption.bold())
                                .foregroundColor(Color(hex: "34d399"))
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color(hex: "34d399").opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "34d399").opacity(0.3), lineWidth: 1))
                            }
                        }

                        // Total Added Summary Card
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(items.count) item(s) to contribute")
                                    .font(.caption)
                                    .foregroundColor(Color.white.opacity(0.6))
                                Text("Total Added:")
                                    .font(.headline.bold())
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            Text("+\(totalContribution.formatted(currencyCode: goal.currencyCode))")
                                .font(.title2.bold())
                                .foregroundColor(Color(hex: "34d399"))
                        }
                        .padding(16)
                        .background(Color(hex: "34d399").opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "34d399").opacity(0.25), lineWidth: 1))

                        // General Note
                        VStack(alignment: .leading, spacing: 8) {
                            Label("General Note (optional)", systemImage: "text.alignleft")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color.white.opacity(0.6))
                            TextField("e.g. Monthly DCA, birthday gift...", text: $generalNote)
                                .textFieldStyle(.plain)
                                .padding(14)
                                .background(Color.white.opacity(0.07))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .foregroundColor(.white)
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
                            Task { await submitContribution() }
                        } label: {
                            Group {
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    HStack {
                                        Image(systemName: "arrow.up.right.circle.fill")
                                        Text("Contribute \(totalContribution > 0 ? totalContribution.formatted(currencyCode: goal.currencyCode) : "")")
                                    }
                                    .font(.headline.bold())
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
                        .disabled(isLoading || totalContribution <= 0)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Contribute to Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color(hex: "a78bfa"))
                }
            }
        }
    }

    private func submitContribution() async {
        guard totalContribution > 0 else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            var payloadItems: [ContributionItemPayload] = []

            for item in items {
                switch item.type {
                case .cash:
                    guard let amt = Double(item.cashAmount), amt > 0 else { continue }
                    payloadItems.append(ContributionItemPayload(
                        instrumentId: nil,
                        symbol: "CASH",
                        name: "Cash Deposit",
                        type: "Cash",
                        amount: amt,
                        quantity: nil,
                        unitPrice: nil,
                        assetCurrencyCode: goal.currencyCode,
                        note: item.note.isEmpty ? nil : item.note
                    ))
                case .stock, .crypto:
                    let sym = item.symbol.trimmingCharacters(in: .whitespaces).uppercased()
                    guard !sym.isEmpty else { continue }

                    // 1. Ensure instrument
                    let inst = try await HoldingService.shared.ensureInstrument(symbol: sym, type: item.type.rawValue)
                    let qty = Double(item.quantity) ?? 1.0
                    var price = Double(item.unitPrice) ?? (item.liveQuote?.resolvedPrice ?? inst.resolvedPrice)
                    if price <= 0 {
                        let quote = try await HoldingService.shared.getLiveQuote(symbol: sym, type: item.type.rawValue)
                        price = quote.resolvedPrice
                    }
                    let fee = Double(item.fee) ?? 0
                    let totalVal = (qty * price) + fee

                    payloadItems.append(ContributionItemPayload(
                        instrumentId: inst.id,
                        symbol: sym,
                        name: inst.name ?? sym,
                        type: item.type.rawValue,
                        amount: totalVal,
                        quantity: qty,
                        unitPrice: price,
                        assetCurrencyCode: inst.currencyCode ?? goal.currencyCode,
                        note: item.note.isEmpty ? nil : item.note
                    ))
                }
            }

            guard !payloadItems.isEmpty else {
                errorMessage = "Please enter valid contribution items."
                return
            }

            let payload = ContributeSavingsGoalPayload(
                amount: totalContribution,
                instrumentId: nil,
                quantity: nil,
                note: generalNote.isEmpty ? nil : generalNote,
                items: payloadItems
            )

            let _: SavingsGoalResponse = try await SavingsGoalService.shared.contribute(goalId: goal.id, payload: payload)
            onSuccess()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Contribution Item Card
struct ContributionItemCard: View {
    @Binding var item: ContributionFormItem
    let goalCurrency: String
    let canRemove: Bool
    let onRemove: () -> Void

    let stockSuggestions = ["VOO", "SPY", "AAPL", "NVDA", "TSLA", "MSFT"]
    let cryptoSuggestions = ["BTC", "ETH", "SOL", "BNB", "XRP"]

    var body: some View {
        VStack(spacing: 12) {
            // Header: Type Picker + Delete button
            HStack {
                Picker("Item Type", selection: $item.type) {
                    ForEach(ContributionItemType.allCases, id: \.self) { t in
                        Text(t.rawValue).tag(t)
                    }
                }
                .pickerStyle(.segmented)

                if canRemove {
                    Button(role: .destructive, action: onRemove) {
                        Image(systemName: "trash")
                            .font(.caption.bold())
                            .foregroundColor(Color(hex: "f87171"))
                            .padding(8)
                            .background(Color(hex: "f87171").opacity(0.12))
                            .clipShape(Circle())
                    }
                }
            }

            // Body based on type
            switch item.type {
            case .cash:
                VStack(alignment: .leading, spacing: 6) {
                    Label("Cash Amount (\(goalCurrency))", systemImage: "banknote")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Color.white.opacity(0.6))
                    TextField("0.00", text: $item.cashAmount)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .foregroundColor(.white)
                        .font(.headline)
                }

            case .stock, .crypto:
                VStack(spacing: 10) {
                    // Symbol + Quote
                    VStack(alignment: .leading, spacing: 6) {
                        Label("\(item.type.rawValue) Symbol", systemImage: "magnifyingglass")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Color.white.opacity(0.6))

                        HStack {
                            TextField(item.type == .crypto ? "e.g. BTC, ETH" : "e.g. VOO, AAPL", text: $item.symbol)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .textFieldStyle(.plain)
                                .foregroundColor(.white)

                            if item.isFetchingQuote {
                                ProgressView().tint(Color(hex: "a78bfa"))
                            } else {
                                Button {
                                    Task { await fetchQuote() }
                                } label: {
                                    Text("Quote")
                                        .font(.caption.bold())
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color(hex: "818cf8"))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                        // Suggestions
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(item.type == .crypto ? cryptoSuggestions : stockSuggestions, id: \.self) { s in
                                    Button {
                                        item.symbol = s
                                        Task { await fetchQuote() }
                                    } label: {
                                        Text(s)
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(item.symbol.uppercased() == s ? Color(hex: "818cf8").opacity(0.3) : Color.white.opacity(0.06))
                                            .foregroundColor(item.symbol.uppercased() == s ? Color(hex: "a78bfa") : Color.white.opacity(0.7))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }

                        // Live Quote Banner
                        if let quote = item.liveQuote {
                            HStack {
                                Text("\(quote.symbol): \(quote.resolvedPrice.formatted(currencyCode: quote.currencyCode ?? goalCurrency))")
                                    .font(.caption.bold())
                                    .foregroundColor(Color(hex: "34d399"))
                                Spacer()
                                Button("Use Price") {
                                    item.unitPrice = String(format: "%.4f", quote.resolvedPrice)
                                }
                                .font(.caption2.bold())
                                .foregroundColor(Color(hex: "a78bfa"))
                            }
                            .padding(8)
                            .background(Color(hex: "34d399").opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }

                    // Quantity and Price
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Quantity")
                                .font(.caption2)
                                .foregroundColor(Color.white.opacity(0.6))
                            TextField("1", text: $item.quantity)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.plain)
                                .padding(10)
                                .background(Color.white.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Price / Unit")
                                .font(.caption2)
                                .foregroundColor(Color.white.opacity(0.6))
                            TextField("0.00", text: $item.unitPrice)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.plain)
                                .padding(10)
                                .background(Color.white.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Fee")
                                .font(.caption2)
                                .foregroundColor(Color.white.opacity(0.6))
                            TextField("0", text: $item.fee)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.plain)
                                .padding(10)
                                .background(Color.white.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .foregroundColor(.white)
                        }
                    }
                }
            }

            // Item total preview
            if item.calculatedAmount > 0 {
                HStack {
                    Text("Item Value:")
                        .font(.caption2)
                        .foregroundColor(Color.white.opacity(0.5))
                    Spacer()
                    Text(item.calculatedAmount.formatted(currencyCode: goalCurrency))
                        .font(.caption.bold())
                        .foregroundColor(Color(hex: "34d399"))
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.06), lineWidth: 1))
        .task {
            if (item.type == .stock || item.type == .crypto) && !item.symbol.isEmpty {
                await fetchQuote()
            }
        }
    }

    private func fetchQuote() async {
        let sym = item.symbol.trimmingCharacters(in: .whitespaces).uppercased()
        guard !sym.isEmpty else { return }
        item.isFetchingQuote = true
        defer { item.isFetchingQuote = false }
        do {
            let quote = try await HoldingService.shared.getLiveQuote(symbol: sym, type: item.type.rawValue)
            item.liveQuote = quote
            if item.unitPrice.isEmpty || item.unitPrice == "0.00" {
                item.unitPrice = String(format: "%.4f", quote.resolvedPrice)
            }
        } catch {}
    }
}
