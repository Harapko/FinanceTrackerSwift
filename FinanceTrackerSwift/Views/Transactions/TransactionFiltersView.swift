import SwiftUI

struct TransactionFiltersView: View {
    @Bindable var viewModel: TransactionsViewModel
    let onApply: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(Color.white.opacity(0.4))
                TextField("Search payee or description...", text: $viewModel.searchText)
                    .foregroundColor(.white).autocorrectionDisabled()
                if !viewModel.searchText.isEmpty {
                    Button { viewModel.searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(Color.white.opacity(0.4))
                    }
                }
            }
            .padding(12).background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 10) {
                // Type filter
                Menu {
                    Button("All Types") { viewModel.selectedType = "" }
                    Button("Income") { viewModel.selectedType = "Income" }
                    Button("Expense") { viewModel.selectedType = "Expense" }
                    Button("Transfer") { viewModel.selectedType = "Transfer" }
                } label: {
                    HStack {
                        Text(viewModel.selectedType.isEmpty ? "All Types" : viewModel.selectedType)
                            .font(.subheadline).foregroundColor(.white).fixedSize()
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down").font(.caption2)
                            .foregroundColor(Color(hex: "a78bfa"))
                    }
                    .padding(10).background(Color.white.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // Date range
                HStack(spacing: 4) {
                    TextField("From", text: $viewModel.fromDate).font(.caption).foregroundColor(.white)
                    Text("–").foregroundColor(Color.white.opacity(0.4))
                    TextField("To", text: $viewModel.toDate).font(.caption).foregroundColor(.white)
                }
                .padding(10).background(Color.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            HStack {
                Button("Apply") { onApply() }
                    .font(.subheadline.weight(.semibold)).foregroundColor(.white)
                    .padding(.horizontal, 20).padding(.vertical, 10)
                    .background(LinearGradient(colors: [Color(hex: "818cf8"), Color(hex: "a78bfa")],
                                               startPoint: .leading, endPoint: .trailing))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Spacer()

                Button("Reset") { viewModel.reset() }
                    .font(.subheadline).foregroundColor(Color.white.opacity(0.5))
            }
        }
        .padding(16).background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
