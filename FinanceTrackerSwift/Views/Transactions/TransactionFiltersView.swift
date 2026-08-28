import SwiftUI

struct TransactionFiltersView: View {
    @Binding var filters: TransactionFilterParams
    let onApply: () -> Void
    @State private var accounts: [AccountResponse] = []

    var body: some View {
        VStack(spacing: 12) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color.white.opacity(0.4))
                TextField("Search payee or description...", text: Binding(
                    get: { filters.search ?? "" },
                    set: { filters.search = $0.isEmpty ? nil : $0 }
                ))
                .foregroundColor(.white)
                .autocorrectionDisabled()
            }
            .padding(12)
            .background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 10) {
                // Type filter
                Picker("Type", selection: Binding(
                    get: { filters.type ?? "" },
                    set: { filters.type = $0.isEmpty ? nil : $0 }
                )) {
                    Text("All Types").tag("")
                    Text("Income").tag("Income")
                    Text("Expense").tag("Expense")
                    Text("Transfer").tag("Transfer")
                }
                .pickerStyle(.menu)
                .padding(10)
                .background(Color.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .foregroundColor(.white)

                // Date range
                HStack(spacing: 6) {
                    TextField("From", text: Binding(
                        get: { filters.fromDate ?? "" },
                        set: { filters.fromDate = $0.isEmpty ? nil : $0 }
                    ))
                    .font(.caption)
                    .foregroundColor(.white)
                    Text("–").foregroundColor(Color.white.opacity(0.4))
                    TextField("To", text: Binding(
                        get: { filters.toDate ?? "" },
                        set: { filters.toDate = $0.isEmpty ? nil : $0 }
                    ))
                    .font(.caption)
                    .foregroundColor(.white)
                }
                .padding(10)
                .background(Color.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            HStack {
                Button("Apply Filters") {
                    filters.page = 1
                    onApply()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(LinearGradient(colors: [Color(hex: "818cf8"), Color(hex: "a78bfa")],
                                           startPoint: .leading, endPoint: .trailing))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Spacer()

                Button("Reset") {
                    filters = TransactionFilterParams()
                    onApply()
                }
                .font(.subheadline)
                .foregroundColor(Color.white.opacity(0.5))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
