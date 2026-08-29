import SwiftUI

struct CategoryItem: Identifiable, Hashable {
    let id: String
    let name: String
    let icon: String
    let color: String
}

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    var onSuccess: () -> Void = {}

    @State private var transactionType: TransactionType = .expense
    @State private var amount: String = ""
    @State private var currencyCode: String = "UAH"
    @State private var selectedAccountId: String = ""
    @State private var selectedCategoryId: String = "health"
    @State private var selectedDateOption: Int = 0 // 0: today, 1: yesterday, 2: two days ago, 3: custom
    @State private var customDate: Date = Date()
    @State private var showDatePicker = false
    @State private var showAccountPickerSheet = false
    @State private var tags: [String] = []
    @State private var showAddTagPrompt = false
    @State private var newTagText = ""
    @State private var comment = ""

    @State private var accounts: [AccountResponse] = []
    @State private var categories: [CategoryResponse] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    let availableCurrencies = ["UAH", "USD", "EUR", "GBP", "PLN", "CAD", "CHF"]

    // 8 Category items matching Screenshot 4
    let defaultCategories: [CategoryItem] = [
        CategoryItem(id: "health", name: "Health", icon: "heart.fill", color: "#ef4444"),
        CategoryItem(id: "leisure", name: "Leisure", icon: "wallet.pass.fill", color: "#06b6d4"),
        CategoryItem(id: "home", name: "Home", icon: "house.fill", color: "#f97316"),
        CategoryItem(id: "cafe", name: "Cafe", icon: "fork.knife", color: "#a855f7"),
        CategoryItem(id: "education", name: "Education", icon: "graduationcap.fill", color: "#3b82f6"),
        CategoryItem(id: "gifts", name: "Gifts", icon: "gift.fill", color: "#ec4899"),
        CategoryItem(id: "groceries", name: "Groceries", icon: "basket.fill", color: "#22c55e"),
        CategoryItem(id: "more", name: "More", icon: "plus", color: "#64748b")
    ]

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
        formatter.dateFormat = "M/d"
        let datePart = formatter.string(from: target)
        let relPart = daysAgo == 0 ? "today" : (daysAgo == 1 ? "yesterday" : "two days ago")
        return (datePart, relPart)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background dark green-olive theme matching Screenshot 4
                Color(hex: "0e1711").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 22) {
                        // 1. EXPENSES vs INCOME Tabs
                        HStack(spacing: 0) {
                            tabButton(title: "EXPENSES", isSelected: transactionType == .expense) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    transactionType = .expense
                                }
                            }
                            tabButton(title: "INCOME", isSelected: transactionType == .income) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    transactionType = .income
                                }
                            }
                        }
                        .padding(.top, 8)

                        // 2. Big Amount Input with Currency & Calculator
                        VStack(spacing: 4) {
                            HStack(alignment: .bottom, spacing: 12) {
                                Spacer()

                                TextField("0", text: $amount)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 42, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.trailing)
                                    .frame(minWidth: 80, maxWidth: 200)

                                Menu {
                                    ForEach(availableCurrencies, id: \.self) { c in
                                        Button(c) { currencyCode = c }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(currencyCode)
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(Color(hex: "34d399"))
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(Color(hex: "34d399").opacity(0.7))
                                    }
                                }

                                Button {
                                    if amount.isEmpty || amount == "0" {
                                        amount = "100"
                                    }
                                } label: {
                                    Image(systemName: "plus.forwardslash.minus")
                                        .font(.system(size: 22))
                                        .foregroundColor(Color.white.opacity(0.6))
                                        .padding(.leading, 6)
                                }

                                Spacer()
                            }
                            .padding(.bottom, 6)

                            Rectangle()
                                .fill(Color.white.opacity(0.18))
                                .frame(width: 240, height: 1.5)
                        }

                        // 3. Account Selector
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Account")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color.white.opacity(0.5))

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
                                HStack {
                                    Text(selectedAccount?.name ?? (accounts.first?.name ?? "Select Account"))
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(Color(hex: "34d399"))
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.caption2)
                                        .foregroundColor(Color.white.opacity(0.4))
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)

                        // 4. Categories Grid (2 Rows of 4 Circles matching Screenshot 4)
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Categories")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color.white.opacity(0.5))
                                .padding(.horizontal, 20)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 18) {
                                ForEach(defaultCategories) { cat in
                                    Button {
                                        selectedCategoryId = cat.id
                                    } label: {
                                        VStack(spacing: 8) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color(hex: cat.color))
                                                    .frame(width: 56, height: 56)
                                                    .overlay(
                                                        Circle()
                                                            .stroke(Color.white, lineWidth: selectedCategoryId == cat.id ? 3 : 0)
                                                    )
                                                    .shadow(color: selectedCategoryId == cat.id ? Color(hex: cat.color).opacity(0.6) : Color.clear, radius: 8)

                                                Image(systemName: cat.icon)
                                                    .font(.system(size: 22, weight: .bold))
                                                    .foregroundColor(.white)
                                            }

                                            Text(cat.name)
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(selectedCategoryId == cat.id ? .white : Color.white.opacity(0.7))
                                                .lineLimit(1)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        // 5. Date Quick Pills
                        HStack(spacing: 8) {
                            datePill(index: 0, daysAgo: 0)
                            datePill(index: 1, daysAgo: 1)
                            datePill(index: 2, daysAgo: 2)

                            // Calendar custom date button
                            Button {
                                showDatePicker = true
                            } label: {
                                Image(systemName: "calendar")
                                    .font(.system(size: 16))
                                    .foregroundColor(selectedDateOption == 3 ? Color(hex: "10b981") : Color.white.opacity(0.6))
                                    .frame(width: 44, height: 44)
                                    .background(selectedDateOption == 3 ? Color(hex: "10b981").opacity(0.2) : Color.white.opacity(0.05))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                        .padding(.horizontal, 20)

                        // 6. Tags Section
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Tags")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(Color.white.opacity(0.5))
                                Spacer()
                                Image(systemName: "magnifyingglass")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "34d399"))
                            }

                            HStack(spacing: 8) {
                                Button {
                                    showAddTagPrompt = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus")
                                        Text("Add tag")
                                    }
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(Color(hex: "34d399"))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color(hex: "34d399").opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "34d399").opacity(0.3), lineWidth: 1))
                                }

                                ForEach(tags, id: \.self) { t in
                                    Text("#\(t)")
                                        .font(.caption2.bold())
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.white.opacity(0.08))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // 7. Comment Field (Underline style)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Comment")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color.white.opacity(0.5))

                            TextField("Comment", text: $comment)
                                .textFieldStyle(.plain)
                                .foregroundColor(.white)
                                .padding(.vertical, 6)

                            Rectangle()
                                .fill(Color.white.opacity(0.15))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 20)

                        // 8. Photo Section (Placeholder Attachment Slots)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Photo")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color.white.opacity(0.5))

                            HStack(spacing: 12) {
                                ForEach(0..<3) { _ in
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.06))
                                            .frame(height: 70)
                                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                                        Image(systemName: "plus")
                                            .font(.title2)
                                            .foregroundColor(Color.white.opacity(0.4))
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // Error message banner
                        if let error = errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text(error).font(.caption)
                            }
                            .foregroundColor(Color(hex: "f87171"))
                            .padding(12)
                            .background(Color(hex: "f87171").opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.horizontal, 20)
                        }

                        // Bottom breathing room for safe area
                        Spacer().frame(height: 80)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                // Floating Bottom Add Button (Always Clean & Visible)
                VStack(spacing: 0) {
                    Divider().background(Color.white.opacity(0.06))
                    Button {
                        Task { await save() }
                    } label: {
                        Group {
                            if isLoading {
                                ProgressView().tint(.black)
                            } else {
                                Text("Add")
                                    .font(.headline.bold())
                                    .foregroundColor(Color(hex: "0e1711"))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "fbbf24"), Color(hex: "f59e0b")],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .shadow(color: Color(hex: "f59e0b").opacity(0.35), radius: 10, x: 0, y: 5)
                    }
                    .disabled(isLoading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                .background(Color(hex: "0e1711").opacity(0.95))
            }
            .navigationTitle("Add Transactions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
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
                            }
                        }
                }
                .presentationDetents([.medium])
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
                    categories = try await TransactionService.shared.getCategories()
                } catch {}
            }
        }
    }

    // MARK: - Subviews
    @ViewBuilder
    private func tabButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(isSelected ? .white : Color.white.opacity(0.5))
                    .padding(.horizontal, 20)

                Rectangle()
                    .fill(isSelected ? Color.white : Color.clear)
                    .frame(height: 3)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func datePill(index: Int, daysAgo: Int) -> some View {
        let (dPart, rPart) = dateLabel(daysAgo: daysAgo)
        let isSelected = selectedDateOption == index

        Button {
            selectedDateOption = index
        } label: {
            VStack(spacing: 2) {
                Text(dPart)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(isSelected ? Color(hex: "0e1711") : .white)
                Text(rPart)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? Color(hex: "0e1711").opacity(0.8) : Color.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color(hex: "34d399") : Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Save
    private func save() async {
        // Auto-select account if empty
        var targetAccountId = selectedAccountId
        if targetAccountId.isEmpty {
            if let first = accounts.first {
                targetAccountId = first.id
                selectedAccountId = first.id
            } else {
                // Fetch accounts
                if let accs = try? await AccountService.shared.getAccounts(), let first = accs.first {
                    accounts = accs
                    targetAccountId = first.id
                    selectedAccountId = first.id
                }
            }
        }

        guard !targetAccountId.isEmpty else {
            errorMessage = "Please create or select an Account first."
            return
        }

        guard let amt = Double(amount), amt > 0 else {
            errorMessage = "Please enter an amount greater than 0."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        // Find or map category
        let mappedCat = categories.first { $0.name.lowercased() == selectedCategoryId.lowercased() } ?? categories.first

        let payload = CreateTransactionPayload(
            accountId: targetAccountId,
            subAccountId: nil,
            categoryId: mappedCat?.id,
            type: transactionType.rawValue,
            amount: amt,
            currencyCode: currencyCode,
            description: comment.trimmingCharacters(in: .whitespaces).isEmpty ? nil : comment,
            date: selectedDateString,
            time: "12:00",
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
