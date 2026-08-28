import SwiftUI
import Charts

struct BalanceHistoryChartView: View {
    let entries: [BalanceHistoryEntry]
    let currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Balance History")
                .font(.headline.bold())
                .foregroundColor(.white)

            Chart {
                ForEach(entries) { entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Balance", entry.balance)
                    )
                    .foregroundStyle(
                        LinearGradient(colors: [Color(hex: "818cf8"), Color(hex: "a78bfa")],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Date", entry.date),
                        y: .value("Balance", entry.balance)
                    )
                    .foregroundStyle(
                        LinearGradient(colors: [Color(hex: "818cf8").opacity(0.25), .clear],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                        .foregroundStyle(Color.white.opacity(0.15))
                    AxisValueLabel()
                        .foregroundStyle(Color.white.opacity(0.5))
                        .font(.caption2)
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                        .foregroundStyle(Color.white.opacity(0.15))
                    AxisValueLabel()
                        .foregroundStyle(Color.white.opacity(0.5))
                        .font(.caption2)
                }
            }
            .frame(height: 180)
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
