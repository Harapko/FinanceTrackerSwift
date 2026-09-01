import SwiftUI

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    var initialType: TransactionType = .expense
    var initialDate: Date? = nil
    var transactionToEdit: TransactionResponse? = nil
    var onSuccess: () -> Void = {}

    var isEditing: Bool { transactionToEdit != nil }

    @State private var transactionType: TransactionType = .expense
    @State private var amount: String = ""
    @State private var currencyCode: String = "USD"
    @State private var selectedAccountId: String = ""
    @State private var selectedSubAccountId: String = ""
    @State private var selectedCategoryId: String = ""

    // Transfer specific
    @State private var destAccountId: String = ""
    @State private var destSubAccountId: String = ""

    @State private var selectedDateOption: Int = 0 // 0: today, 1: yesterday, 2: two days ago, 3: custom
    @State private var customDate: Date = Date()
    @State private var showDatePicker = false
    @State private var showAddCategory = false
    @State private var tags: [String] = []
    @State private var showAddTagPrompt = false
    @State private var newTagText = ""
    @State private var comment = ""

    @State private var accounts: [AccountResponse] = []
    @State private var categories: [CategoryResponse] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    let availableCurrencies = ["USD", "EUR", "UAH", "GBP", "PLN", "CAD", "CHF", "JPY"]

    var filteredCategories: [CategoryResponse] {
        categories.filter { cat in
            guard let type = cat.type else { return true }
            return type.caseInsensitiveCompare(transactionType.rawValue) == .orderedSame ||
                   type.caseInsensitiveCompare("Both") == .orderedSame
        }
    }

    var selectedAccount: AccountResponse? {
        accounts.first { $0.id == selectedAccountId }
    }

    var selectedDestAccount: AccountResponse? {
        accounts.first { $0.id == destAccountId }
    }

    var sourceSubAccounts: [SubAccountResponse] {
        selectedAccount?.subAccountsList ?? []
    }

    var destSubAccounts: [SubAccountResponse] {
        selectedDestAccount?.subAccountsList ?? []
    }

    var selectedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let calendar = Calendar.current
        switch selectedDateOption {
        case 0: return formatter.string(from: Date())
        case 1: return formatter.string(from: calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date())
        case 2: return formatter.string(from: calendar.date(byAdding: .day, value: -2, to: Date()) ?? Date())
        default: return formatter.string(from: customDate)
        }
    }

    private func dateLabel(daysAgo: Int) -> (dateStr: String, relStr: String) {
        let calendar = Calendar.current
        let target = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let datePart = formatter.string(from: target)
        let relPart = daysAgo == 0 ? "Today" : (daysAgo == 1 ? "Yesterday" : "2 days ago")
        return (datePart, relPart)
    }

    var themeColor: Color {
        switch transactionType {
        case .expense: return Color(hex: "f87171")
        case .income: return Color(hex: "34d399")
        case .transfer: return Color(hex: "818cf8")
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0d1117").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Sleek 3-Way Segmented Control
                        HStack(spacing: 0) {
                            tabPill(
                                title: L10n.Transactions.typeExpense.uppercased(),
                                icon: "arrow.down.right.circle.fill",
                                isSelected: transactionType == .expense,
                                activeColor: Color(hex: "f87171")
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    transactionType = .expense
                                    updateSelectedCategoryForCurrentType()
                                }
                            }

                            tabPill(
                                title: L10n.Transactions.typeIncome.uppercased(),
                                icon: "arrow.up.right.circle.fill",
                                isSelected: transactionType == .income,
                                activeColor: Color(hex: "34d399")
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    transactionType = .income
                                    updateSelectedCategoryForCurrentType()
                                }
                            }

                            tabPill(
                                title: L10n.Transactions.typeTransfer.uppercased(),
                                icon: "arrow.left.arrow.right.circle.fill",
                                isSelected: transactionType == .transfer,
                                activeColor: Color(hex: "818cf8")
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    transactionType = .transfer
                                    ensureDestAccountDifferent()
                                }
                            }
                        }
                        .padding(4)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 20)
                        .padding(.top, 10)

                        // Error Banner if present
                        if let error = errorMessage {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.subheadline)
                                Text(error)
                                    .font(.caption)
                                    .multilineTextAlignment(.leading)
                            }
                            .foregroundColor(Color(hex: "f87171"))
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(hex: "f87171").opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(hex: "f87171").opacity(0.3), lineWidth: 1)
                            )
                            .padding(.horizontal, 20)
                        }

                        // 2. Hero Amount Input Card
                        VStack(spacing: 8) {
                            Text(amountTitle)
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color.white.opacity(0.5))

                            HStack(alignment: .center, spacing: 8) {
                                Text(amountSymbol)
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(themeColor)

                                TextField("0.00", text: $amount)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 40, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(minWidth: 80, maxWidth: 180)

                                Menu {
                                    ForEach(availableCurrencies, id: \.self) { c in
                                        Button(c) { currencyCode = c }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(currencyCode)
                                            .font(.headline.bold())
                                            .foregroundColor(themeColor)
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.caption2.bold())
                                            .foregroundColor(themeColor.opacity(0.7))
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(themeColor.opacity(0.12))
                                    .clipShape(Capsule())
                                }

                                Button {
                                    if amount.isEmpty || amount == "0" {
                                        amount = "100"
                                    }
                                } label: {
                                    Image(systemName: "plus.forwardslash.minus")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(Color.white.opacity(0.6))
                                        .padding(8)
                                        .background(Color.white.opacity(0.06))
                                        .clipShape(Circle())
                                }
                            }
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(themeColor.opacity(0.25), lineWidth: 1))
                        .padding(.horizontal, 20)

                        // 3. Accounts Section (Different for Transfer vs Standard)
                        if transactionType == .transfer {
                            transferAccountsCard
                        } else {
                            standardAccountSelector
                        }

                        // 4. Dynamic Categories Grid (Expense & Income only)
                        if transactionType != .transfer {
                            categoriesSection
                        }

                        // 5. Date Quick Selector
                        VStack(alignment: .leading, spacing: 8) {
                            Label(L10n.Common.date, systemImage: "calendar")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color.white.opacity(0.6))
                                .padding(.horizontal, 20)

                            HStack(spacing: 8) {
                                datePill(index: 0, daysAgo: 0)
                                datePill(index: 1, daysAgo: 1)
                                datePill(index: 2, daysAgo: 2)

                                Button {
                                    showDatePicker = true
                                } label: {
                                    Image(systemName: "calendar.badge.clock")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(selectedDateOption == 3 ? Color(hex: "a78bfa") : Color.white.opacity(0.6))
                                        .frame(width: 44, height: 44)
                                        .background(selectedDateOption == 3 ? Color(hex: "a78bfa").opacity(0.2) : Color.white.opacity(0.05))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(selectedDateOption == 3 ? Color(hex: "a78bfa") : Color.clear, lineWidth: 1))
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        // 6. Note / Comment
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Note / Description (optional)", systemImage: "text.alignleft")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color.white.opacity(0.6))
                                .padding(.horizontal, 20)

                            TextField(transactionType == .transfer ? "e.g. Monthly savings, credit card payoff..." : "e.g. Weekly grocery haul, Dinner with friends...", text: $comment)
                                .textFieldStyle(.plain)
                                .foregroundColor(.white)
                                .padding(14)
                                .background(Color.white.opacity(0.04))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 1))
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
            .safeAreaInset(edge: .bottom) {
                // Floating Action Bar
                VStack(spacing: 0) {
                    Divider().background(Color.white.opacity(0.06))
                    Button {
                        Task { await save() }
                    } label: {
                        Group {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                HStack(spacing: 8) {
                                    Image(systemName: actionButtonIcon)
                                    Text(actionButtonTitle)
                                        .font(.headline.bold())
                                }
                                .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(
                            LinearGradient(
                                colors: actionButtonGradient,
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(
                            color: themeColor.opacity(0.35),
                            radius: 10, x: 0, y: 5
                        )
                    }
                    .disabled(isLoading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                .background(Color(hex: "0d1117").opacity(0.95))
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) { dismiss() }
                        .foregroundColor(Color(hex: "a78bfa"))
                }
            }
            .sheet(isPresented: $showDatePicker) {
                NavigationStack {
                    DatePicker("Select Date", selection: $customDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .padding()
                        .navigationTitle("Pick Date")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button(L10n.Common.done) {
                                    selectedDateOption = 3
                                    showDatePicker = false
                                }
                                .foregroundColor(Color(hex: "a78bfa"))
                            }
                        }
                }
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showAddCategory) {
                AddCategoryView(initialType: transactionType == .income ? .income : .expense) { newCat in
                    categories.append(newCat)
                    selectedCategoryId = newCat.id
                }
            }
            .alert("Add Tag", isPresented: $showAddTagPrompt) {
                TextField("Tag name", text: $newTagText)
                Button("Add") {
                    let t = newTagText.trimmingCharacters(in: .whitespaces)
                    if !t.isEmpty && !tags.contains(t) {
                        tags.append(t)
                    }
                    newTagText = ""
                }
                Button("Cancel", role: .cancel) { newTagText = "" }
            }
            .task {
                if let tx = transactionToEdit {
                    transactionType = tx.type
                    amount = String(tx.amount)
                    currencyCode = tx.currencyCode
                    selectedAccountId = tx.accountId
                    selectedSubAccountId = tx.subAccountId ?? ""
                    selectedCategoryId = tx.categoryId ?? ""
                    comment = tx.description ?? ""
                    destAccountId = tx.transferDestAccountId ?? ""
                    destSubAccountId = tx.transferDestSubAccountId ?? ""
                    let f = DateFormatter()
                    f.dateFormat = "yyyy-MM-dd"
                    if let d = f.date(from: tx.date) {
                        customDate = d
                        selectedDateOption = 3
                    }
                } else {
                    transactionType = initialType
                    if let initDate = initialDate {
                        let cal = Calendar.current
                        customDate = initDate
                        if cal.isDateInToday(initDate) {
                            selectedDateOption = 0
                        } else if cal.isDateInYesterday(initDate) {
                            selectedDateOption = 1
                        } else if let twoDaysAgo = cal.date(byAdding: .day, value: -2, to: Date()), cal.isDate(initDate, inSameDayAs: twoDaysAgo) {
                            selectedDateOption = 2
                        } else {
                            selectedDateOption = 3
                        }
                    }
                }
                do {
                    accounts = try await AccountService.shared.getAccounts()
                    if selectedAccountId.isEmpty, let first = accounts.first {
                        selectedAccountId = first.id
                        currencyCode = first.currencyCode
                    }
                    if destAccountId.isEmpty && accounts.count > 1 {
                        destAccountId = accounts[1].id
                    }
                    categories = try await CategoryService.shared.getCategories()
                    if !isEditing {
                        updateSelectedCategoryForCurrentType()
                    }
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private var amountTitle: String {
        switch transactionType {
        case .expense: return "Amount to Spend"
        case .income: return "Amount to Receive"
        case .transfer: return "Amount to Transfer"
        }
    }

    private var amountSymbol: String {
        switch transactionType {
        case .expense: return "-"
        case .income: return "+"
        case .transfer: return "⇄"
        }
    }

    private var navigationTitle: String {
        if isEditing {
            return L10n.Transactions.editTransaction
        }
        switch transactionType {
        case .expense: return L10n.Transactions.modalTitle
        case .income: return L10n.Transactions.modalTitle
        case .transfer: return L10n.Transactions.transferFunds
        }
    }

    private var actionButtonIcon: String {
        switch transactionType {
        case .expense: return "arrow.down.right.circle.fill"
        case .income: return "arrow.up.right.circle.fill"
        case .transfer: return "arrow.left.arrow.right.circle.fill"
        }
    }

    private var actionButtonTitle: String {
        if isEditing {
            return L10n.Common.save
        }
        switch transactionType {
        case .expense: return "\(L10n.Transactions.add) \(L10n.Transactions.typeExpense)"
        case .income: return "\(L10n.Transactions.add) \(L10n.Transactions.typeIncome)"
        case .transfer: return L10n.Transactions.transferFunds
        }
    }

    private var actionButtonGradient: [Color] {
        switch transactionType {
        case .expense: return [Color(hex: "f43f5e"), Color(hex: "e11d48")]
        case .income: return [Color(hex: "10b981"), Color(hex: "059669")]
        case .transfer: return [Color(hex: "818cf8"), Color(hex: "6366f1")]
        }
    }

    private func updateSelectedCategoryForCurrentType() {
        if !filteredCategories.contains(where: { $0.id == selectedCategoryId }) {
            selectedCategoryId = filteredCategories.first?.id ?? ""
        }
    }

    private func ensureDestAccountDifferent() {
        if destAccountId.isEmpty || destAccountId == selectedAccountId {
            if let other = accounts.first(where: { $0.id != selectedAccountId }) {
                destAccountId = other.id
            }
        }
    }

    private func swapTransferAccounts() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            let tempAcc = selectedAccountId
            let tempSub = selectedSubAccountId
            selectedAccountId = destAccountId
            selectedSubAccountId = destSubAccountId
            destAccountId = tempAcc
            destSubAccountId = tempSub
            if let newSource = accounts.first(where: { $0.id == selectedAccountId }) {
                currencyCode = newSource.currencyCode
            }
        }
    }

    // MARK: - Subviews
    @ViewBuilder
    private var standardAccountSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(L10n.Transactions.sourceAccount, systemImage: "building.columns.fill")
                .font(.caption.weight(.semibold))
                .foregroundColor(Color.white.opacity(0.6))
                .padding(.horizontal, 20)

            Menu {
                ForEach(accounts) { acc in
                    Button {
                        selectedAccountId = acc.id
                        selectedSubAccountId = ""
                        currencyCode = acc.currencyCode
                    } label: {
                        HStack {
                            Text("\(acc.name) (\(acc.currencyCode))")
                            if selectedAccountId == acc.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: selectedAccount?.color ?? "818cf8").opacity(0.2))
                            .frame(width: 38, height: 38)
                        Image(systemName: selectedAccount?.type.icon ?? "building.columns")
                            .font(.caption.bold())
                            .foregroundColor(Color(hex: selectedAccount?.color ?? "818cf8"))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedAccount?.name ?? (accounts.first?.name ?? L10n.Transactions.selectAccount))
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        Text("\(L10n.Accounts.totalBalance): \(selectedAccount?.totalValue.formatted(currencyCode: selectedAccount?.currencyCode ?? currencyCode) ?? "0.00")")
                            .font(.caption2)
                            .foregroundColor(Color.white.opacity(0.5))
                    }

                    Spacer()

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.bold())
                        .foregroundColor(Color(hex: "a78bfa"))
                }
                .padding(14)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.06), lineWidth: 1))
                .padding(.horizontal, 20)
            }
        }
    }

    @ViewBuilder
    private var transferAccountsCard: some View {
        VStack(spacing: 12) {
            // Source Account (From)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label("From Account", systemImage: "arrow.up.circle.fill")
                        .font(.caption.bold())
                        .foregroundColor(Color(hex: "f87171"))
                    Spacer()
                    if let acc = selectedAccount {
                        Text("Bal: \(acc.totalValue.formatted(currencyCode: acc.currencyCode))")
                            .font(.caption2)
                            .foregroundColor(Color.white.opacity(0.4))
                    }
                }

                Menu {
                    ForEach(accounts) { acc in
                        Button {
                            selectedAccountId = acc.id
                            selectedSubAccountId = ""
                            currencyCode = acc.currencyCode
                            ensureDestAccountDifferent()
                        } label: {
                            HStack {
                                Text("\(acc.name) (\(acc.currencyCode))")
                                if selectedAccountId == acc.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: selectedAccount?.type.icon ?? "building.columns")
                            .foregroundColor(Color(hex: selectedAccount?.color ?? "818cf8"))
                        Text(selectedAccount?.name ?? "Select Source")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2)
                            .foregroundColor(Color.white.opacity(0.4))
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // Optional Sub-Account selector for Source
                if !sourceSubAccounts.isEmpty {
                    Menu {
                        Button("Main Account") { selectedSubAccountId = "" }
                        ForEach(sourceSubAccounts) { sub in
                            Button("\(sub.name) (\(sub.currencyCode))") {
                                selectedSubAccountId = sub.id
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedSubAccountId.isEmpty ? "Sub-Account: Main" : "Sub-Account: \(sourceSubAccounts.first(where: { $0.id == selectedSubAccountId })?.name ?? "")")
                                .font(.caption)
                                .foregroundColor(Color(hex: "a78bfa"))
                            Spacer()
                            Image(systemName: "chevron.down").font(.caption2).foregroundColor(Color(hex: "a78bfa"))
                        }
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Color(hex: "a78bfa").opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }

            // Swap Button & Divider
            HStack {
                Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)
                Button {
                    swapTransferAccounts()
                } label: {
                    Image(systemName: "arrow.up.arrow.down.circle.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(hex: "818cf8"))
                        .background(Color(hex: "161b22"))
                        .clipShape(Circle())
                }
                Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)
            }
            .padding(.vertical, 2)

            // Destination Account (To)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label("To Account", systemImage: "arrow.down.circle.fill")
                        .font(.caption.bold())
                        .foregroundColor(Color(hex: "34d399"))
                    Spacer()
                    if let acc = selectedDestAccount {
                        Text("Bal: \(acc.totalValue.formatted(currencyCode: acc.currencyCode))")
                            .font(.caption2)
                            .foregroundColor(Color.white.opacity(0.4))
                    }
                }

                Menu {
                    ForEach(accounts) { acc in
                        Button {
                            destAccountId = acc.id
                            destSubAccountId = ""
                        } label: {
                            HStack {
                                Text("\(acc.name) (\(acc.currencyCode))")
                                if destAccountId == acc.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: selectedDestAccount?.type.icon ?? "building.columns")
                            .foregroundColor(Color(hex: selectedDestAccount?.color ?? "34d399"))
                        Text(selectedDestAccount?.name ?? "Select Destination")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2)
                            .foregroundColor(Color.white.opacity(0.4))
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // Optional Sub-Account selector for Destination
                if !destSubAccounts.isEmpty {
                    Menu {
                        Button("Main Account") { destSubAccountId = "" }
                        ForEach(destSubAccounts) { sub in
                            Button("\(sub.name) (\(sub.currencyCode))") {
                                destSubAccountId = sub.id
                            }
                        }
                    } label: {
                        HStack {
                            Text(destSubAccountId.isEmpty ? "Sub-Account: Main" : "Sub-Account: \(destSubAccounts.first(where: { $0.id == destSubAccountId })?.name ?? "")")
                                .font(.caption)
                                .foregroundColor(Color(hex: "34d399"))
                            Spacer()
                            Image(systemName: "chevron.down").font(.caption2).foregroundColor(Color(hex: "34d399"))
                        }
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Color(hex: "34d399").opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "818cf8").opacity(0.2), lineWidth: 1))
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Category", systemImage: "square.grid.2x2.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color.white.opacity(0.6))
                Spacer()
                Button {
                    showAddCategory = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("New Category")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color(hex: "a78bfa"))
                }
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Add Category quick pill
                    Button {
                        showAddCategory = true
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "a78bfa").opacity(0.12))
                                    .frame(width: 52, height: 52)
                                    .overlay(
                                        Circle()
                                            .stroke(Color(hex: "a78bfa").opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                                    )

                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Color(hex: "a78bfa"))
                            }

                            Text(L10n.Transactions.add)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color(hex: "a78bfa"))
                                .lineLimit(1)
                        }
                        .frame(width: 64)
                    }

                    ForEach(filteredCategories) { cat in
                        let isSelected = selectedCategoryId == cat.id
                        Button {
                            selectedCategoryId = cat.id
                        } label: {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: cat.displayColor).opacity(isSelected ? 0.9 : 0.15))
                                        .frame(width: 52, height: 52)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: isSelected ? 2.5 : 0)
                                        )
                                        .shadow(color: isSelected ? Color(hex: cat.displayColor).opacity(0.6) : Color.clear, radius: 8)

                                    Image(systemName: cat.displayIcon)
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(isSelected ? .white : Color(hex: cat.displayColor))
                                }

                                Text(cat.name)
                                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(isSelected ? .white : Color.white.opacity(0.6))
                                    .lineLimit(1)
                            }
                            .frame(width: 68)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
        }
    }

    @ViewBuilder
    private func tabPill(title: String, icon: String, isSelected: Bool, activeColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.bold())
                Text(title)
                    .font(.subheadline.bold())
            }
            .foregroundColor(isSelected ? .white : Color.white.opacity(0.5))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                isSelected ?
                LinearGradient(colors: [activeColor.opacity(0.8), activeColor], startPoint: .leading, endPoint: .trailing) :
                LinearGradient(colors: [Color.clear, Color.clear], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    @ViewBuilder
    private func datePill(index: Int, daysAgo: Int) -> some View {
        let (dPart, rPart) = dateLabel(daysAgo: daysAgo)
        let isSelected = selectedDateOption == index

        Button {
            selectedDateOption = index
        } label: {
            VStack(spacing: 2) {
                Text(rPart)
                    .font(.caption.bold())
                    .foregroundColor(isSelected ? .white : Color.white.opacity(0.8))
                Text(dPart)
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? Color.white.opacity(0.9) : Color.white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color(hex: "818cf8") : Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? Color(hex: "a78bfa") : Color.white.opacity(0.05), lineWidth: 1))
        }
    }

    // MARK: - Save
    private func save() async {
        guard let amt = Double(amount), amt > 0 else {
            errorMessage = "Please enter an amount greater than 0."
            return
        }

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        let currentTimeString = timeFormatter.string(from: Date())

        if let editTx = transactionToEdit {
            await saveEdit(editTx: editTx, amount: amt, timeStr: currentTimeString)
            return
        }

        if transactionType == .transfer {
            await saveTransfer(amount: amt, timeStr: currentTimeString)
        } else {
            await saveStandard(amount: amt, timeStr: currentTimeString)
        }
    }

    private func saveEdit(editTx: TransactionResponse, amount: Double, timeStr: String) async {
        guard !selectedAccountId.isEmpty else {
            errorMessage = "Please select an account."
            return
        }

        if transactionType == .transfer {
            guard !destAccountId.isEmpty else {
                errorMessage = "Please select a destination account."
                return
            }
            if selectedAccountId == destAccountId && selectedSubAccountId == destSubAccountId {
                errorMessage = "Source and destination accounts cannot be identical."
                return
            }
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let payload = UpdateTransactionPayload(
            accountId: selectedAccountId,
            subAccountId: selectedSubAccountId.isEmpty ? nil : selectedSubAccountId,
            categoryId: transactionType == .transfer ? nil : (selectedCategoryId.isEmpty ? nil : selectedCategoryId),
            type: transactionType.rawValue,
            amount: amount,
            currencyCode: currencyCode,
            exchangeRate: nil,
            description: comment.trimmingCharacters(in: .whitespaces).isEmpty ? nil : comment,
            date: selectedDateString,
            time: timeStr,
            payee: nil,
            transferDestAccountId: transactionType == .transfer ? destAccountId : nil,
            transferDestSubAccountId: transactionType == .transfer ? (destSubAccountId.isEmpty ? nil : destSubAccountId) : nil
        )

        do {
            let _: TransactionResponse = try await TransactionService.shared.updateTransaction(id: editTx.id, payload: payload)
            onSuccess()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveTransfer(amount: Double, timeStr: String) async {
        guard !selectedAccountId.isEmpty else {
            errorMessage = "Please select a source account."
            return
        }

        guard !destAccountId.isEmpty else {
            errorMessage = "Please select a destination account."
            return
        }

        if selectedAccountId == destAccountId && selectedSubAccountId == destSubAccountId {
            errorMessage = "Source and destination accounts cannot be identical."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let payload = CreateTransferPayload(
            sourceAccountId: selectedAccountId,
            sourceSubAccountId: selectedSubAccountId.isEmpty ? nil : selectedSubAccountId,
            destAccountId: destAccountId,
            destSubAccountId: destSubAccountId.isEmpty ? nil : destSubAccountId,
            amount: amount,
            currencyCode: currencyCode,
            exchangeRate: nil,
            description: comment.trimmingCharacters(in: .whitespaces).isEmpty ? L10n.Transactions.transferDescDefault : comment,
            date: selectedDateString,
            payee: nil
        )

        do {
            let _: TransactionResponse = try await TransactionService.shared.createTransfer(payload)
            onSuccess()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveStandard(amount: Double, timeStr: String) async {
        var targetAccountId = selectedAccountId
        if targetAccountId.isEmpty {
            if let first = accounts.first {
                targetAccountId = first.id
                selectedAccountId = first.id
            }
        }

        guard !targetAccountId.isEmpty else {
            errorMessage = "Please select or create an account first."
            return
        }

        var targetCategoryId = selectedCategoryId
        if targetCategoryId.isEmpty {
            targetCategoryId = filteredCategories.first?.id ?? categories.first?.id ?? ""
            if !targetCategoryId.isEmpty {
                selectedCategoryId = targetCategoryId
            }
        }

        guard !targetCategoryId.isEmpty else {
            errorMessage = "Please select or create a category first."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let payload = CreateTransactionPayload(
            accountId: targetAccountId,
            subAccountId: selectedSubAccountId.isEmpty ? nil : selectedSubAccountId,
            categoryId: targetCategoryId,
            type: transactionType.rawValue,
            amount: amount,
            currencyCode: currencyCode,
            description: comment.trimmingCharacters(in: .whitespaces).isEmpty ? nil : comment,
            date: selectedDateString,
            time: timeStr,
            payee: nil
        )

        do {
            let _: TransactionResponse = try await TransactionService.shared.createTransaction(payload)
            onSuccess()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
