import SwiftUI

struct AddAccountView: View {
    @Environment(\.dismiss) private var dismiss
    var onSuccess: (() -> Void) = {}   // kept for compatibility, onDismiss handles reload

    @State private var name = ""
    @State private var type: AccountType = .bankAccount
    @State private var currencyCode = "USD"
    @State private var color = "#818cf8"
    @State private var description = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    let currencies = ["USD", "EUR", "GBP", "UAH", "PLN", "JPY", "CAD", "AUD", "CHF", "BTC"]
    let colorOptions = ["#818cf8", "#a78bfa", "#f472b6", "#34d399", "#fbbf24", "#60a5fa", "#fb923c", "#e879f9"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0d1117").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Name
                        formField("Account Name", icon: "building.columns") {
                            TextField("e.g. My Chase Account", text: $name)
                        }

                        // Type
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Account Type", systemImage: "creditcard")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color.white.opacity(0.6))
                            Picker("Type", selection: $type) {
                                ForEach(AccountType.allCases, id: \.self) { t in
                                    Label(t.displayName, systemImage: t.icon).tag(t)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(12)
                            .background(Color.white.opacity(0.07))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // Currency — use Menu so label never wraps
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

                        // Color
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Accent Color", systemImage: "paintpalette")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color.white.opacity(0.6))
                            HStack(spacing: 10) {
                                ForEach(colorOptions, id: \.self) { c in
                                    Circle()
                                        .fill(Color(hex: c))
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: color == c ? 3 : 0)
                                        )
                                        .onTapGesture { color = c }
                                }
                            }
                        }

                        // Description
                        formField("Description (optional)", icon: "text.alignleft") {
                            TextField("Optional description", text: $description)
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
                                    Text("Create Account")
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
            .navigationTitle("New Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color(hex: "a78bfa"))
                }
            }
        }
    }

    private func save() async {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        let payload = CreateAccountPayload(
            name: trimmedName,
            type: type.rawValue,
            currencyCode: currencyCode,
            description: description.trimmingCharacters(in: .whitespaces).isEmpty ? nil : description,
            color: color
        )
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let _: AccountResponse = try await AccountService.shared.createAccount(payload)
            dismiss()           // sheet dismiss triggers onDismiss → reload in AccountsView
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
