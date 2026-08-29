import SwiftUI
import Charts

struct BalanceHistoryChartView: View {
    let entries: [BalanceHistoryEntry]
    let currencyCode: String

    @State private var selectedDate: Date?

    var selectedEntry: BalanceHistoryEntry? {
        guard let selectedDate else { return nil }
        return entries.min(by: {
            abs($0.parsedDate.timeIntervalSince(selectedDate)) < abs($1.parsedDate.timeIntervalSince(selectedDate))
        })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Balance History")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                    if let selectedEntry {
                        Text("\(selectedEntry.balance.formatted(currencyCode: currencyCode)) on \(formatDateFull(selectedEntry.parsedDate))")
                            .font(.caption)
                            .foregroundColor(Color(hex: "a78bfa"))
                    } else if let latest = entries.last {
                        Text("Current: \(latest.balance.formatted(currencyCode: currencyCode))")
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                }
                Spacer()
            }

            if entries.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 32))
                        .foregroundColor(Color.white.opacity(0.2))
                    Text("No balance history")
                        .font(.subheadline)
                        .foregroundColor(Color.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
            } else {
                Chart {
                    ForEach(entries) { entry in
                        LineMark(
                            x: .value("Date", entry.parsedDate),
                            y: .value("Balance", entry.balance)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "818cf8"), Color(hex: "a78bfa")],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Date", entry.parsedDate),
                            y: .value("Balance", entry.balance)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "818cf8").opacity(0.25), Color(hex: "818cf8").opacity(0.01)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }

                    if let selectedEntry {
                        RuleMark(x: .value("Selected Date", selectedEntry.parsedDate))
                            .foregroundStyle(Color(hex: "a78bfa").opacity(0.6))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                            .annotation(position: .top) {
                                VStack(spacing: 2) {
                                    Text(selectedEntry.balance.formatted(currencyCode: currencyCode))
                                        .font(.caption2.bold())
                                        .foregroundColor(.white)
                                    Text(formatDateFull(selectedEntry.parsedDate))
                                        .font(.system(size: 9))
                                        .foregroundColor(Color.white.opacity(0.6))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(hex: "1f2937"))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "a78bfa").opacity(0.4), lineWidth: 1))
                            }

                        PointMark(
                            x: .value("Selected Date", selectedEntry.parsedDate),
                            y: .value("Selected Balance", selectedEntry.balance)
                        )
                        .foregroundStyle(Color(hex: "a78bfa"))
                        .symbolSize(60)
                    }
                }
                .chartXSelection(value: $selectedDate)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { val in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                            .foregroundStyle(Color.white.opacity(0.12))
                        AxisValueLabel(format: .dateTime.month(.twoDigits).day(.twoDigits))
                            .foregroundStyle(Color.white.opacity(0.5))
                            .font(.caption2)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { val in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                            .foregroundStyle(Color.white.opacity(0.12))
                        AxisValueLabel {
                            if let amount = val.as(Double.self) {
                                Text(formatCompactCurrency(amount, currencyCode: currencyCode))
                                    .foregroundStyle(Color.white.opacity(0.5))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .frame(height: 200)
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private func formatDateFull(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    private func formatCompactCurrency(_ value: Double, currencyCode: String) -> String {
        let absVal = abs(value)
        let prefix = value < 0 ? "-" : ""
        if absVal >= 1_000_000 {
            return "\(prefix)\(String(format: "%.1fM", absVal / 1_000_000)) \(currencyCode)"
        } else if absVal >= 1_000 {
            return "\(prefix)\(String(format: "%.0fk", absVal / 1_000)) \(currencyCode)"
        }
        return "\(prefix)\(Int(absVal)) \(currencyCode)"
    }
}
