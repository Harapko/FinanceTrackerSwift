import SwiftUI

struct RecentTransactionsView: View {
    let transactions: [TransactionResponse]
    let currencyCode: String
    var onViewAll: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header with View All button
            HStack {
                Text(L10n.Dashboard.recentTransactions)
                    .font(.headline.bold())
                    .foregroundColor(.white)
                Spacer()
                Button {
                    onViewAll()
                } label: {
                    HStack(spacing: 4) {
                        Text(L10n.Dashboard.viewAll)
                            .font(.caption.weight(.semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(Color(hex: "a78bfa"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(hex: "a78bfa").opacity(0.12))
                    .clipShape(Capsule())
                }
            }

            if transactions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "arrow.left.arrow.right.circle")
                        .font(.system(size: 32))
                        .foregroundColor(Color.white.opacity(0.2))
                    Text(L10n.Dashboard.noRecentTransactions)
                        .font(.subheadline)
                        .foregroundColor(Color.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
            } else {
                VStack(spacing: 0) {
                    ForEach(transactions) { tx in
                        TransactionRowView(transaction: tx)
                            .padding(.vertical, 8)
                        if tx.id != transactions.last?.id {
                            Divider().background(Color.white.opacity(0.06))
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}
