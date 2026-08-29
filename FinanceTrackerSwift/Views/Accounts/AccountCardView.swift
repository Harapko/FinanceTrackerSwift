import SwiftUI

struct AccountCardView: View {
    let account: AccountResponse
    @State private var isExpanded = false

    var accentColor: Color {
        Color(hex: account.color ?? "818cf8")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row
            Button { withAnimation(.spring(response: 0.3)) { isExpanded.toggle() } } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.2))
                            .frame(width: 48, height: 48)
                        Image(systemName: account.type.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(accentColor)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(account.name)
                            .font(.headline.weight(.bold))
                            .foregroundColor(.white)
                        HStack(spacing: 6) {
                            Text(account.type.displayName)
                                .font(.caption)
                                .foregroundColor(Color.white.opacity(0.5))
                            Text("•")
                                .font(.caption)
                                .foregroundColor(Color.white.opacity(0.3))
                            Text(account.currencyCode)
                                .font(.caption)
                                .foregroundColor(Color.white.opacity(0.5))
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(account.totalValue.formatted(currencyCode: account.currencyCode))
                            .font(.title3.bold())
                            .foregroundColor(.white)
                        if let holdings = account.holdingsValue, holdings > 0 {
                            Text("Holdings: \(holdings.formatted(currencyCode: account.currencyCode))")
                                .font(.caption2)
                                .foregroundColor(Color(hex: "34d399"))
                        }
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.4))
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            // Sub-accounts
            if isExpanded && !account.subAccountsList.isEmpty {
                Divider().background(Color.white.opacity(0.08))
                VStack(spacing: 0) {
                    ForEach(account.subAccountsList) { sub in
                        HStack {
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 8, height: 8)
                                .padding(.leading, 24)
                            Text(sub.name)
                                .font(.subheadline)
                                .foregroundColor(Color.white.opacity(0.8))
                            Text(sub.type.rawValue)
                                .font(.caption)
                                .foregroundColor(Color.white.opacity(0.4))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.white.opacity(0.07))
                                .clipShape(Capsule())
                            Spacer()
                            Text(sub.totalValue.formatted(currencyCode: sub.currencyCode))
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.02))

                        if sub.id != account.subAccountsList.last?.id {
                            Divider().background(Color.white.opacity(0.05))
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(accentColor.opacity(0.2), lineWidth: 1)
        )
    }
}
