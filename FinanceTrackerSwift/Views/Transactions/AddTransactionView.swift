import SwiftUI

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    var onSuccess: () -> Void = {}

    @State private var transactionType: TransactionType = .expense
    @State private var amount: String = ""
    @State private var currencyCode: String = "USD"
    @State private var selectedAccountId: String = ""
    @State private var selectedCategoryId: String = ""
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
        transactionType == .expense ? Color(hex: "f87171") : Color(hex: "34d399")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0d1117").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Sleek Expense / Income Segmented Control
                        HStack(spacing: 0) {
                            tabPill(
                                title: "EXPENSE",
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
                                title: "INCOME",
                                icon: "arrow.up.right.circle.fill",
                                isSelected: transactionType == .income,
                                activeColor: Color(hex: "34d399")
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    transactionType = .income
                                    updateSelectedCategoryForCurrentType()
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
                            Text(transactionType == .expense ? "Amount to Spend" : "Amount to Receive")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color.white.opacity(0.5))

                            HStack(alignment: .center, spacing: 8) {
                                Text(transactionType == .expense ? "-" : "+")
                                    .font(.system(size: 36, weight: .bold))
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

                        // 3. Account Selector
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Target Account", systemImage: "building.columns.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color.white.opacity(0.6))
                                .padding(.horizontal, 20)

                            Menu {
                                ForEach(accounts) { acc in
                                    Button {
                                        selectedAccountId = acc.id
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
                                        Text(selectedAccount?.name ?? (accounts.first?.name ?? "Select Account"))
                                            .font(.subheadline.bold())
                                            .foregroundColor(.white)
                                        Text("Balance: \(selectedAccount?.totalValue.formatted(currencyCode: selectedAccount?.currencyCode ?? currencyCode) ?? "0.00")")
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

                        // 4. Dynamic Categories Grid & Quick Creator
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

                                            Text("Add")
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

                        // 5. Date Quick Selector
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Date", systemImage: "calendar")
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

                            TextField("e.g. Weekly grocery haul, Dinner with friends...", text: $comment)
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
                // Floating Action Bar with App's Gradient Styling
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
                                    Image(systemName: transactionType == .expense ? "arrow.down.right.circle.fill" : "arrow.up.right.circle.fill")
                                    Text(transactionType == .expense ? "Add Expense" : "Add Income")
                                        .font(.headline.bold())
                                }
                                .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(
                            LinearGradient(
                                colors: transactionType == .expense ?
                                    [Color(hex: "f43f5e"), Color(hex: "e11d48")] :
                                    [Color(hex: "10b981"), Color(hex: "059669")],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(
                            color: (transactionType == .expense ? Color(hex: "f43f5e") : Color(hex: "10b981")).opacity(0.35),
                            radius: 10, x: 0, y: 5
                        )
                    }
                    .disabled(isLoading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                .background(Color(hex: "0d1117").opacity(0.95))
            }
            .navigationTitle(transactionType == .expense ? "New Expense" : "New Income")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
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
                                Button("Done") {
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
                do {
                    accounts = try await AccountService.shared.getAccounts()
                    if selectedAccountId.isEmpty, let first = accounts.first {
                        selectedAccountId = first.id
                        currencyCode = first.currencyCode
                    }
                    categories = try await CategoryService.shared.getCategories()
                    updateSelectedCategoryForCurrentType()
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func updateSelectedCategoryForCurrentType() {
        if !filteredCategories.contains(where: { $0.id == selectedCategoryId }) {
            selectedCategoryId = filteredCategories.first?.id ?? ""
        }
    }

    // MARK: - Subviews
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
        var targetAccountId = selectedAccountId
        if targetAccountId.isEmpty {
            if let first = accounts.first {
                targetAccountId = first.id
                selectedAccountId = first.id
            } else {
                if let accs = try? await AccountService.shared.getAccounts(), let first = accs.first {
                    accounts = accs
                    targetAccountId = first.id
                    selectedAccountId = first.id
                }
            }
        }

        guard !targetAccountId.isEmpty else {
            errorMessage = "Please select or create an account first."
            return
        }

        guard let amt = Double(amount), amt > 0 else {
            errorMessage = "Please enter an amount greater than 0."
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

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        let currentTimeString = timeFormatter.string(from: Date())

        let payload = CreateTransactionPayload(
            accountId: targetAccountId,
            subAccountId: nil,
            categoryId: targetCategoryId,
            type: transactionType.rawValue,
            amount: amt,
            currencyCode: currencyCode,
            description: comment.trimmingCharacters(in: .whitespaces).isEmpty ? nil : comment,
            date: selectedDateString,
            time: currentTimeString,
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
