import SwiftUI

struct AddAccountView: View {
    @Environment(\.dismiss) private var dismiss
    let editingAccount: AccountResponse?
    let onSuccess: () -> Void

    @State private var name: String
    @State private var type: AccountType
    @State private var currencyCode: String
    @State private var balanceText: String
    @State private var color: String
    @State private var description: String
    @State private var isLoading = false
    @State private var errorMessage: String?

    let currencies = ["USD", "EUR", "GBP", "UAH", "PLN", "JPY", "CAD", "AUD", "CHF", "BTC", "ETH", "SOL"]
    let colorOptions = ["#818cf8", "#a78bfa", "#f472b6", "#34d399", "#fbbf24", "#60a5fa", "#fb923c", "#e879f9", "#38bdf8", "#2bff00"]

    init(editingAccount: AccountResponse? = nil, onSuccess: @escaping () -> Void = {}) {
        self.editingAccount = editingAccount
        self.onSuccess = onSuccess
        _name = State(initialValue: editingAccount?.name ?? "")
        _type = State(initialValue: editingAccount?.type ?? .bankAccount)
        _currencyCode = State(initialValue: editingAccount?.currencyCode ?? "USD")
        _balanceText = State(initialValue: editingAccount != nil ? String(format: "%.2f", editingAccount?.balance ?? 0) : "")
        _color = State(initialValue: editingAccount?.color ?? "#818cf8")
        _description = State(initialValue: editingAccount?.description ?? "")
    }

    var isEditing: Bool { editingAccount != nil }

    var selectedColor: Color {
        Color(hex: color)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0d1117").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Account Name
                        VStack(alignment: .leading, spacing: 8) {
                            Label(L10n.Accounts.accountName, systemImage: "building.columns.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color.white.opacity(0.6))
                            TextField(L10n.Accounts.accountNamePlaceholder, text: $name)
                                .textFieldStyle(.plain)
                                .padding(14)
                                .background(Color.white.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
                                .foregroundColor(.white)
                        }

                        // 2. Account Type (Full-Width Dropdown Card)
                        VStack(alignment: .leading, spacing: 8) {
                            Label(L10n.Accounts.accountType, systemImage: "creditcard.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color.white.opacity(0.6))

                            Menu {
                                ForEach(AccountType.allCases, id: \.self) { t in
                                    Button {
                                        type = t
                                    } label: {
                                        HStack {
                                            Label(t.displayName, systemImage: t.icon)
                                            if type == t {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: type.icon)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(selectedColor)
                                        .frame(width: 28)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(type.displayName)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(.white)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.caption.bold())
                                        .foregroundColor(Color(hex: "a78bfa"))
                                }
                                .padding(14)
                                .background(Color.white.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
                            }
                        }

                        // 3. Currency Selector
                        VStack(alignment: .leading, spacing: 8) {
                            Label(L10n.Common.currency, systemImage: "dollarsign.circle.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color.white.opacity(0.6))

                            Menu {
                                ForEach(currencies, id: \.self) { c in
                                    Button(c) {
                                        currencyCode = c
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(currencyCode)
                                        .font(.subheadline.weight(.bold))
                                        .foregroundColor(Color(hex: "34d399"))

                                    Spacer()

                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.caption.bold())
                                        .foregroundColor(Color(hex: "a78bfa"))
                                }
                                .padding(14)
                                .background(Color.white.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
                            }
                        }

                        // 4. Balance (Initial or Current)
                        VStack(alignment: .leading, spacing: 8) {
                            Label(isEditing ? L10n.Accounts.currentBalance : L10n.Accounts.initialBalance, systemImage: "banknote.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color.white.opacity(0.6))

                            HStack(spacing: 10) {
                                Text(currencyCode)
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color(hex: "34d399"))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(hex: "34d399").opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))

                                TextField("0.00", text: $balanceText)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.plain)
                                    .foregroundColor(.white)
                            }
                            .padding(14)
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))

                            if isEditing {
                                Text(L10n.Accounts.balanceAdjustmentHint)
                                    .font(.caption2)
                                    .foregroundColor(Color.white.opacity(0.5))
                            }
                        }

                        // 5. Accent Color Ribbon
                        VStack(alignment: .leading, spacing: 10) {
                            Label(L10n.Accounts.themeColor, systemImage: "paintpalette.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color.white.opacity(0.6))

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(colorOptions, id: \.self) { c in
                                        let isSelected = color.lowercased() == c.lowercased()
                                        Circle()
                                            .fill(Color(hex: c))
                                            .frame(width: 36, height: 36)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: isSelected ? 3 : 0)
                                            )
                                            .shadow(color: isSelected ? Color(hex: c).opacity(0.6) : Color.clear, radius: 6)
                                            .scaleEffect(isSelected ? 1.15 : 1.0)
                                            .animation(.spring(response: 0.25), value: isSelected)
                                            .onTapGesture { color = c }
                                    }
                                }
                                .padding(.horizontal, 4)
                                .padding(.vertical, 6)
                            }
                        }

                        // 6. Description (Optional)
                        VStack(alignment: .leading, spacing: 8) {
                            Label(L10n.Accounts.descriptionOptional, systemImage: "text.alignleft")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color.white.opacity(0.6))

                            TextField(L10n.Accounts.descriptionPlaceholder, text: $description)
                                .textFieldStyle(.plain)
                                .padding(14)
                                .background(Color.white.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
                                .foregroundColor(.white)
                        }

                        // Error Banner
                        if let error = errorMessage {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(Color(hex: "f87171"))
                                    .font(.subheadline)
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "f87171"))
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(hex: "f87171").opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "f87171").opacity(0.3), lineWidth: 1))
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 80)
                }
            }
            .safeAreaInset(edge: .bottom) {
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
                                    Image(systemName: isEditing ? "checkmark.circle.fill" : "plus.circle.fill")
                                    Text(isEditing ? L10n.Profile.saveChanges : L10n.Accounts.modalCreateTitle)
                                        .font(.headline.bold())
                                }
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
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color(hex: "818cf8").opacity(0.35), radius: 10, x: 0, y: 5)
                    }
                    .disabled(isLoading || name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                .background(Color(hex: "0d1117").opacity(0.95))
            }
            .navigationTitle(isEditing ? L10n.Accounts.modalEditTitle : L10n.Accounts.modalCreateTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) { dismiss() }
                        .foregroundColor(Color(hex: "a78bfa"))
                }
            }
        }
    }

    private func save() async {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let parsedBalance = Double(balanceText.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces))

        do {
            if let acc = editingAccount {
                let payload = UpdateAccountPayload(
                    name: trimmedName,
                    type: type.rawValue,
                    currencyCode: currencyCode,
                    description: description.trimmingCharacters(in: .whitespaces).isEmpty ? nil : description,
                    color: color,
                    balance: parsedBalance
                )
                let _: AccountResponse = try await AccountService.shared.updateAccount(id: acc.id, payload: payload)
            } else {
                let payload = CreateAccountPayload(
                    name: trimmedName,
                    type: type.rawValue,
                    currencyCode: currencyCode,
                    description: description.trimmingCharacters(in: .whitespaces).isEmpty ? nil : description,
                    color: color,
                    initialBalance: parsedBalance
                )
                let _: AccountResponse = try await AccountService.shared.createAccount(payload)
            }
            onSuccess()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
