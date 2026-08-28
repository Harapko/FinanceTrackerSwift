import SwiftUI

struct RecentTransactionsView: View {
    let transactions: [TransactionResponse]
    let currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Transactions")
                .font(.headline.bold())
                .foregroundColor(.white)

            ForEach(transactions) { tx in
                TransactionRowView(transaction: tx)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
