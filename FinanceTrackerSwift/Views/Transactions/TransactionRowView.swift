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

    var primaryTitle: String {
        if let payee = transaction.payee, !payee.trimmingCharacters(in: .whitespaces).isEmpty {
            return payee
        }
        if let category = transaction.categoryName, !category.trimmingCharacters(in: .whitespaces).isEmpty {
            return category
        }
        return transaction.description?.isEmpty == false ? (transaction.description ?? "Transaction") : "Transaction"
    }

    var secondaryDetails: String {
        var parts: [String] = []
        
        // If payee was primary, include category
        if let payee = transaction.payee, !payee.isEmpty, let cat = transaction.categoryName, !cat.isEmpty {
            parts.append(cat)
        } else if let acc = transaction.accountName, !acc.isEmpty {
            parts.append(acc)
        } else if let desc = transaction.description, !desc.isEmpty && desc != primaryTitle {
            parts.append(desc)
        }

        if let time = transaction.time, !time.isEmpty {
            let shortTime = String(time.prefix(5))
            parts.append(shortTime)
        }

        return parts.joined(separator: " • ")
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(amountColor.opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: {
                    switch transaction.type {
                    case .income: return "arrow.down.circle.fill"
                    case .expense: return "arrow.up.circle.fill"
                    case .transfer: return "arrow.left.arrow.right.circle.fill"
                    }
                }())
                    .foregroundColor(amountColor)
                    .font(.system(size: 18, weight: .semibold))
            }

            // Title & Subtitle Info
            VStack(alignment: .leading, spacing: 3) {
                Text(primaryTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)

                if !secondaryDetails.isEmpty {
                    Text(secondaryDetails)
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.5))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Amount Display (High Priority, Never Truncated)
            Text("\(amountPrefix)\(transaction.amount.formatted(currencyCode: transaction.currencyCode))")
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundColor(amountColor)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .layoutPriority(1)

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
                        .foregroundColor(Color.white.opacity(0.35))
                        .padding(.horizontal, 6)
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
