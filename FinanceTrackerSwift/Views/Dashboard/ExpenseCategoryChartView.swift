import SwiftUI
import Charts

let categoryColors: [Color] = [
    Color(hex: "818cf8"), Color(hex: "a78bfa"), Color(hex: "f472b6"),
    Color(hex: "34d399"), Color(hex: "fbbf24"), Color(hex: "60a5fa"),
    Color(hex: "fb923c"), Color(hex: "e879f9")
]

struct ExpenseCategoryChartView: View {
    let entries: [CategoryBreakdownEntry]
    let currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Expenses by Category")
                .font(.headline.bold())
                .foregroundColor(.white)

            HStack(alignment: .center, spacing: 20) {
                // Pie chart
                Chart {
                    ForEach(Array(entries.prefix(8).enumerated()), id: \.element.id) { idx, entry in
                        SectorMark(
                            angle: .value("Amount", entry.total),
                            innerRadius: .ratio(0.55),
                            angularInset: 2
                        )
                        .foregroundStyle(categoryColors[idx % categoryColors.count])
                        .cornerRadius(4)
                    }
                }
                .frame(width: 130, height: 130)

                // Legend
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(entries.prefix(5).enumerated()), id: \.element.id) { idx, entry in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(categoryColors[idx % categoryColors.count])
                                .frame(width: 8, height: 8)
                            Text(entry.categoryName)
                                .font(.caption)
                                .foregroundColor(Color.white.opacity(0.8))
                                .lineLimit(1)
                            Spacer()
                            Text(entry.total.formatted(currencyCode: currencyCode))
                                .font(.caption2)
                                .foregroundColor(Color.white.opacity(0.5))
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
