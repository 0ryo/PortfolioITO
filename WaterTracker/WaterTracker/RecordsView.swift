import SwiftUI
import Charts
import SwiftData

struct RecordsView: View {
    private let monthStart: Date
    private let monthEnd: Date
    
    @Query private var logs: [WaterLog]

    // 日別合計データ（グラフ用）
    private var dailyTotals: [DayTotal] {
        let calendar = Calendar.current
        var totals: [Date: Int] = [:]

        for log in logs {
            let day = calendar.startOfDay(for: log.date)
            let current = totals[day] ?? 0
            totals[day] = current + log.amountML
        }

        // 今月の全日を並べて、データがない日は0で埋める
        var result: [DayTotal] = []
        var day = monthStart
        while day <= monthEnd {
            let key = calendar.startOfDay(for: day)
            let value = totals[key] ?? 0
            result.append(DayTotal(date: key, amountML: value))
            if let next = calendar.date(byAdding: .day, value: 1, to: day) {
                day = next
            } else {
                break
            }
        }
        return result
    }

    // 一覧用(今日より前の日だけに絞る)
    private var pastDailyTotals: [DayTotal] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        return dailyTotals
            .filter { $0.date < tomorrow }
            .sorted { $0.date > $1.date }
    }

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = .current
        f.dateFormat = "MMM dd"
        return f
    }()

    init() {
        let calendar = Calendar.current
        let now = Date()
        let comps = calendar.dateComponents([.year, .month], from: now)
        let startOfMonth = calendar.date(from: comps) ?? now
        let startOfNextMonth = calendar.date(byAdding: DateComponents(month: 1), to: startOfMonth) ?? now
        let endOfMonth = calendar.date(byAdding: .second, value: -1, to: startOfNextMonth) ?? now
        self.monthStart = startOfMonth
        self.monthEnd = endOfMonth

        // 今月を絞り込む
        let predicate = #Predicate<WaterLog> { log in
            log.date >= startOfMonth && log.date <= endOfMonth
        }
        _logs = Query(
            filter: predicate,
            sort: [SortDescriptor(\WaterLog.date, order: .forward)]
        )
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Monthly Data")
                .font(.headline)

            // 棒グラフ
            Chart(dailyTotals) { item in
                BarMark(
                    x: .value("Date", item.date, unit: .day),
                    y: .value("Water (ml)", item.amountML)
                )
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .frame(width: 345, height: 240)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.day(), centered: true)
                }
            }
            .padding(37)
            Text("History")
                .font(.headline)

            // 記録一覧
            List(pastDailyTotals) { item in
                HStack {
                    Text(dateFormatter.string(from: item.date))
                        .font(.body)
                    Spacer()
                    Text("\(item.amountML) ml")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            .frame(width: 375, height: 320)
        }
        .padding()
    }
}

private struct DayTotal: Identifiable {
    let id = UUID()
    let date: Date
    let amountML: Int
}
