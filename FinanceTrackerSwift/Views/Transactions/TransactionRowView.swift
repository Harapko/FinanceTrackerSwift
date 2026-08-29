import SwiftUI

struct TransactionRowView: View {
    let transaction: TransactionResponse

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
                    Text(transaction.categoryName ?? "")
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.5))
                    Text("•")
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.3))
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
        }
        .padding(.vertical, 4)
    }
}
