import SwiftUI
import Charts

let categoryColors: [Color] = [
    Color(hex: "818cf8"), Color(hex: "a78bfa"), Color(hex: "f472b6"),
    Color(hex: "34d399"), Color(hex: "fbbf24"), Color(hex: "60a5fa"),
    Color(hex: "fb923c"), Color(hex: "e879f9"), Color(hex: "38bdf8"),
    Color(hex: "a3e635")
]

struct ExpenseCategoryChartView: View {
    let entries: [CategoryBreakdownEntry]
    let currencyCode: String

    var totalAmount: Double {
        entries.reduce(0) { $0 + $1.total }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Text(L10n.Dashboard.expensesByCategory)
                    .font(.headline.bold())
                    .foregroundColor(.white)
                Spacer()
                if totalAmount > 0 {
                    Text("\(L10n.Dashboard.total): \(totalAmount.formatted(currencyCode: currencyCode))")
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.5))
                }
            }

            if entries.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 32))
                        .foregroundColor(Color.white.opacity(0.2))
                    Text(L10n.Dashboard.noExpenses)
                        .font(.subheadline)
                        .foregroundColor(Color.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 160)
            } else {
                HStack(alignment: .center, spacing: 16) {
                    // Donut chart
                    Chart {
                        ForEach(Array(entries.prefix(8).enumerated()), id: \.element.id) { idx, entry in
                            let color = entry.color != nil ? Color(hex: entry.color!) : categoryColors[idx % categoryColors.count]
                            SectorMark(
                                angle: .value("Amount", entry.total),
                                innerRadius: .ratio(0.58),
                                angularInset: 2
                            )
                            .foregroundStyle(color)
                            .cornerRadius(4)
                        }
                    }
                    .frame(width: 120, height: 120)

                    // Top categories list
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(entries.prefix(4).enumerated()), id: \.element.id) { idx, entry in
                            let color = entry.color != nil ? Color(hex: entry.color!) : categoryColors[idx % categoryColors.count]
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 8, height: 8)
                                Text(entry.categoryName)
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                Spacer()
                                Text(String(format: "%.1f%%", entry.percentage))
                                    .font(.caption2)
                                    .foregroundColor(Color.white.opacity(0.5))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                // 2-column legend for remaining or full breakdown
                if entries.count > 4 {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                        ForEach(Array(entries.dropFirst(4).prefix(4).enumerated()), id: \.element.id) { idx, entry in
                            let color = entry.color != nil ? Color(hex: entry.color!) : categoryColors[(idx + 4) % categoryColors.count]
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 6, height: 6)
                                Text(entry.categoryName)
                                    .font(.caption2)
                                    .foregroundColor(Color.white.opacity(0.7))
                                    .lineLimit(1)
                                Spacer()
                                Text(String(format: "%.0f%%", entry.percentage))
                                    .font(.system(size: 10))
                                    .foregroundColor(Color.white.opacity(0.4))
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}
