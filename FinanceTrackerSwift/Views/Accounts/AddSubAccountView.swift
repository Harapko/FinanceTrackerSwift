import SwiftUI

struct AddSubAccountView: View {
    @Environment(\.dismiss) private var dismiss
    let parentAccountId: String
    let parentCurrency: String
    var editingSubAccount: SubAccountResponse? = nil
    var onSuccess: (() -> Void) = {}

    @State private var name = ""
    @State private var type: SubAccountType = .checking
    @State private var currencyCode = "USD"
    @State private var description = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    let currencies = ["USD", "EUR", "GBP", "UAH", "PLN", "JPY", "CAD", "AUD", "CHF", "BTC", "ETH", "SOL"]

    var isEditing: Bool { editingSubAccount != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0d1117").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Sub-Account Name
                        formField("Sub-Account Name", icon: "square.grid.2x2") {
                            TextField("e.g. Emergency Savings", text: $name)
                        }

                        // Type
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Sub-Account Type", systemImage: "creditcard")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color.white.opacity(0.6))
                            Picker("Type", selection: $type) {
                                ForEach(SubAccountType.allCases, id: \.self) { t in
                                    Text(t.displayName).tag(t)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(12)
                            .background(Color.white.opacity(0.07))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // Currency
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Currency", systemImage: "dollarsign.circle")
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
                                        .fixedSize()
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.caption)
                                        .foregroundColor(Color(hex: "a78bfa"))
                                }
                                .padding(14)
                                .background(Color.white.opacity(0.07))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }

                        // Description
                        formField("Description (optional)", icon: "text.alignleft") {
                            TextField("Notes or purpose...", text: $description)
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

                        // Submit
                        Button {
                            Task { await save() }
                        } label: {
                            Group {
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text(isEditing ? "Save Changes" : "Create Sub-Account")
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
                        .disabled(isLoading || name.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(20)
                }
            }
            .navigationTitle(isEditing ? "Edit Sub-Account" : "New Sub-Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color(hex: "a78bfa"))
                }
            }
            .onAppear {
                if let sub = editingSubAccount {
                    name = sub.name
                    type = sub.type
                    currencyCode = sub.currencyCode
                    description = sub.description ?? ""
                } else {
                    currencyCode = parentCurrency
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
        do {
            if let sub = editingSubAccount {
                let payload = UpdateSubAccountPayload(
                    name: trimmedName,
                    type: type.rawValue,
                    currencyCode: currencyCode,
                    description: description.trimmingCharacters(in: .whitespaces).isEmpty ? nil : description
                )
                let _: SubAccountResponse = try await AccountService.shared.updateSubAccount(
                    accountId: parentAccountId,
                    subAccountId: sub.id,
                    payload: payload
                )
            } else {
                let payload = CreateSubAccountPayload(
                    name: trimmedName,
                    type: type.rawValue,
                    currencyCode: currencyCode,
                    description: description.trimmingCharacters(in: .whitespaces).isEmpty ? nil : description
                )
                let _: SubAccountResponse = try await AccountService.shared.createSubAccount(
                    accountId: parentAccountId,
                    payload: payload
                )
            }
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
