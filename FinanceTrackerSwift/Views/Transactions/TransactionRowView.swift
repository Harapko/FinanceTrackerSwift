import SwiftUI

struct TransactionRowView: View {
    let transaction: TransactionResponse
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    var amountColor: Color {
        switch transaction.type {
        case .income: return Color(hex: "34d399")
        case .expense: return Color(hex: "f87171")
        case .transfer: return Color(hex: "60a5fa")
        }
    }

    var categoryColor: Color {
        if let hex = transaction.categoryColor, !hex.isEmpty {
            return Color(hex: hex)
        }
        return amountColor
    }

    var categoryDisplayIcon: String {
        if let icon = transaction.categoryIcon, !icon.isEmpty {
            let lower = icon.lowercased()
            switch lower {
            case "shoppingbag", "shoppingcart", "shopping-bag", "shopping-cart": return "cart.fill"
            case "utensils", "utensilscrossed", "utensils-crossed": return "fork.knife"
            case "coffee": return "cup.and.saucer.fill"
            case "car": return "car.fill"
            case "fuel", "gas": return "fuelpump.fill"
            case "home", "building", "building2": return "house.fill"
            case "plane": return "airplane"
            case "heart", "heartpulse", "heart-pulse": return "heart.fill"
            case "smartphone", "laptop", "monitor", "tablet": return "laptopcomputer.and.iphone"
            case "gift": return "gift.fill"
            case "dollarsign", "dollar-sign", "wallet", "coins": return "dollarsign.circle.fill"
            case "film", "tv", "tv2", "gamepad2": return "film.fill"
            case "graduationcap", "book", "bookopen": return "graduationcap.fill"
            case "wifi": return "wifi"
            case "shirt": return "tshirt.fill"
            case "wrench", "hammer": return "wrench.and.screwdriver.fill"
            default:
                if UIImage(systemName: icon) != nil {
                    return icon
                }
            }
        }

        let cat = (transaction.categoryName ?? "").lowercased()
        if cat.contains("food") || cat.contains("grocer") || cat.contains("продукт") || cat.contains("їжа") { return "cart.fill" }
        if cat.contains("clothes") || cat.contains("одяг") { return "tshirt.fill" }
        if cat.contains("wifi") || cat.contains("інтернет") { return "wifi" }
        if cat.contains("entertain") || cat.contains("розваг") { return "film.fill" }
        if cat.contains("travel") || cat.contains("подорож") { return "airplane" }
        if cat.contains("home") || cat.contains("дім") || cat.contains("житл") { return "house.fill" }
        if cat.contains("car") || cat.contains("авто") || cat.contains("транспорт") { return "car.fill" }
        if cat.contains("fuel") || cat.contains("бензин") { return "fuelpump.fill" }
        if cat.contains("health") || cat.contains("здоров") || cat.contains("аптек") { return "heart.fill" }
        if cat.contains("salary") || cat.contains("зарплат") || cat.contains("дохід") { return "dollarsign.circle.fill" }

        switch transaction.type {
        case .income: return "arrow.down.circle.fill"
        case .expense: return "tag.fill"
        case .transfer: return "arrow.left.arrow.right.circle.fill"
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
        return transaction.description?.isEmpty == false ? (transaction.description ?? L10n.Nav.transactions) : L10n.Nav.transactions
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
            // Category Icon Badge
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.18))
                    .frame(width: 42, height: 42)
                Image(systemName: categoryDisplayIcon)
                    .foregroundColor(categoryColor)
                    .font(.system(size: 17, weight: .semibold))
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

            if onEdit != nil || onDelete != nil {
                Menu {
                    if let onEdit {
                        Button {
                            onEdit()
                        } label: {
                            Label(L10n.Common.edit, systemImage: "pencil")
                        }
                    }

                    if let onDelete {
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Label(L10n.Transactions.deleteTransaction, systemImage: "trash")
                        }
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
            if let onEdit {
                Button {
                    onEdit()
                } label: {
                    Label(L10n.Common.edit, systemImage: "pencil")
                }
            }

            if let onDelete {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label(L10n.Transactions.deleteTransaction, systemImage: "trash")
                }
            }
        }
    }
}
