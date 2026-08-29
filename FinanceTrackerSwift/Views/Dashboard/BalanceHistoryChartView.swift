import SwiftUI
import Charts

struct BalanceHistoryChartView: View {
    let entries: [BalanceHistoryEntry]
    let currencyCode: String

    @State private var selectedDate: String?
    @State private var selectedBalance: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Balance History")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                    if let selectedBalance, let selectedDate {
                        Text("\(selectedBalance.formatted(currencyCode: currencyCode)) on \(formatDateLabel(selectedDate))")
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
                            x: .value("Date", entry.date),
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
                            x: .value("Date", entry.date),
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

                    if let selectedDate, let selectedBalance {
                        RuleMark(x: .value("Selected Date", selectedDate))
                            .foregroundStyle(Color(hex: "a78bfa").opacity(0.6))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                            .annotation(position: .top) {
                                VStack(spacing: 2) {
                                    Text(selectedBalance.formatted(currencyCode: currencyCode))
                                        .font(.caption2.bold())
                                        .foregroundColor(.white)
                                    Text(formatDateLabel(selectedDate))
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
                            x: .value("Selected Date", selectedDate),
                            y: .value("Selected Balance", selectedBalance)
                        )
                        .foregroundStyle(Color(hex: "a78bfa"))
                        .symbolSize(60)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { val in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                            .foregroundStyle(Color.white.opacity(0.12))
                        AxisValueLabel {
                            if let dateStr = val.as(String.self) {
                                Text(formatDateShort(dateStr))
                                    .foregroundStyle(Color.white.opacity(0.5))
                                    .font(.caption2)
                            }
                        }
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
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let origin = geo[proxy.plotFrame!].origin
                                        let location = CGPoint(
                                            x: value.location.x - origin.x,
                                            y: value.location.y - origin.y
                                        )
                                        if let (date, _) = proxy.value(at: location, as: (String, Double).self) {
                                            if let match = entries.min(by: { abs($0.date.compare(date).rawValue) < abs($1.date.compare(date).rawValue) }) {
                                                selectedDate = match.date
                                                selectedBalance = match.balance
                                            }
                                        }
                                    }
                                    .onEnded { _ in
                                        selectedDate = nil
                                        selectedBalance = nil
                                    }
                            )
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

    private func formatDateShort(_ dateString: String) -> String {
        let parts = dateString.split(separator: "-")
        if parts.count == 3 {
            return "\(parts[1])/\(parts[2])"
        }
        return dateString
    }

    private func formatDateLabel(_ dateString: String) -> String {
        return dateString
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
