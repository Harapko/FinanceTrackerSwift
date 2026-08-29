import SwiftUI

struct TransactionRowView: View {
    let transaction: TransactionResponse
    var onDelete: (() -> Void)? = nil

    var amountColor: Color {
        switch transaction.type {
        case .income: return Color(hex: "34d399")
        case .expense: return Color(hex: "f87171")
        case .transfer: return Color(hex: "60a5fa")
        }
    }

    var amountPrefix: String {
        switch transaction.type {
        case .income: return "+"
        case .expense: return "-"
        case .transfer: return ""
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(amountColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: {
                    switch transaction.type {
                    case .income: return "arrow.down.circle.fill"
                    case .expense: return "arrow.up.circle.fill"
                    case .transfer: return "arrow.left.arrow.right.circle.fill"
                    }
                }())
                    .foregroundColor(amountColor)
                    .font(.system(size: 16, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text((transaction.payee?.isEmpty == false ? transaction.payee : nil) ?? transaction.categoryName ?? "Unknown")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    if let cat = transaction.categoryName, !cat.isEmpty {
                        Text(cat)
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.5))
                        Text("•")
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.3))
                    }
                    Text(transaction.date)
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.5))
                }
            }

            Spacer()

            Text("\(amountPrefix)\(transaction.amount.formatted(currencyCode: transaction.currencyCode))")
                .font(.subheadline.weight(.bold))
                .foregroundColor(amountColor)
                .lineLimit(1)

            if let onDelete {
                Menu {
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete Transaction", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.3))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                }
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
            if let onDelete {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete Transaction", systemImage: "trash")
                }
            }
        }
    }
}
