import SwiftUI

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    var onSuccess: () -> Void = {}

    @State private var type: TransactionType = .expense
    @State private var amount = ""
    @State private var currencyCode = "USD"
    @State private var selectedAccountId = ""
    @State private var selectedCategoryId = ""
    @State private var payee = ""
    @State private var date = ""
    @State private var time = ""
    @State private var description = ""
    @State private var accounts: [AccountResponse] = []
    @State private var categories: [CategoryResponse] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var filteredCategories: [CategoryResponse] {
        categories.filter { $0.type == nil || $0.type == type.rawValue }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0d1117").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Type picker
                        HStack(spacing: 0) {
                            ForEach(TransactionType.allCases, id: \.self) { t in
                                Button {
                                    type = t
                                } label: {
                                    Text(t.displayName)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(type == t ? .white : Color.white.opacity(0.4))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            Group {
                                                if type == t {
                                                    LinearGradient(colors: [Color(hex: "818cf8"), Color(hex: "a78bfa")],
                                                                   startPoint: .leading, endPoint: .trailing)
                                                } else {
                                                    Color.clear
                                                }
                                            }
                                        )
                                }
                            }
                        }
                        .background(Color.white.opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        Group {
                            // Amount
                            formField("Amount", icon: "dollarsign.circle") {
                                TextField("0.00", text: $amount)
                                    .keyboardType(.decimalPad)
                            }

                            // Account
                            formPickerField("Account", icon: "building.columns", selection: $selectedAccountId) {
                                Text("Select Account").tag("")
                                ForEach(accounts) { a in
                                    Text(a.name).tag(a.id)
                                }
                            }

                            // Category
                            formPickerField("Category", icon: "tag", selection: $selectedCategoryId) {
                                Text("Select Category").tag("")
                                ForEach(filteredCategories) { c in
                                    Text(c.name).tag(c.id)
                                }
                            }

                            // Payee
                            formField("Payee", icon: "person") {
                                TextField("Payee name", text: $payee)
                            }

                            // Date
                            formField("Date", icon: "calendar") {
                                TextField("YYYY-MM-DD", text: $date)
                            }

                            // Time
                            formField("Time", icon: "clock") {
                                TextField("HH:MM", text: $time)
                            }

                            // Description
                            formField("Description", icon: "text.alignleft") {
                                TextField("Optional note", text: $description)
                            }
                        }

                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(Color(hex: "f87171"))
                                .padding(12)
                                .background(Color(hex: "f87171").opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        Button {
                            Task { await save() }
                        } label: {
                            Group {
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Add Transaction").font(.headline).foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(LinearGradient(colors: [Color(hex: "818cf8"), Color(hex: "a78bfa")],
                                                       startPoint: .leading, endPoint: .trailing))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(isLoading || selectedAccountId.isEmpty || amount.isEmpty)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color(hex: "a78bfa"))
                }
            }
        }
        .task {
            do {
                async let accs = AccountService.shared.getAccounts()
                async let cats = TransactionService.shared.getCategories()
                let (a, c) = try await (accs, cats)
                accounts = a
                categories = c
                if let first = a.first {
                    selectedAccountId = first.id
                    currencyCode = first.currencyCode
                }
                // Pre-fill date/time
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                date = formatter.string(from: Date())
                formatter.dateFormat = "HH:mm"
                time = formatter.string(from: Date())
            } catch {}
        }
    }

    private func save() async {
        guard let amountDouble = Double(amount), !selectedAccountId.isEmpty else { return }
        let acc = accounts.first { $0.id == selectedAccountId }
        let payload = CreateTransactionPayload(
            accountId: selectedAccountId,
            subAccountId: nil,
            categoryId: selectedCategoryId.isEmpty ? nil : selectedCategoryId,
            type: type.rawValue,
            amount: amountDouble,
            currencyCode: acc?.currencyCode ?? currencyCode,
            description: description.isEmpty ? nil : description,
            date: date,
            time: time.isEmpty ? "12:00" : time,
            payee: payee.isEmpty ? nil : payee
        )
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let _: TransactionResponse = try await TransactionService.shared.createTransaction(payload)
            onSuccess()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @ViewBuilder
    private func formField<Content: View>(_ label: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
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

    @ViewBuilder
    private func formPickerField<SelectionValue: Hashable, Content: View>(
        _ label: String, icon: String,
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content
    ) -> some View where Content: View {
        VStack(alignment: .leading, spacing: 8) {
            Label(label, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundColor(Color.white.opacity(0.6))
            Picker(label, selection: selection) {
                content()
            }
            .pickerStyle(.menu)
            .padding(12)
            .background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .foregroundColor(.white)
        }
    }
}
