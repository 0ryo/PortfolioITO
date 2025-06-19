//
//  StaticsView.swift
//  PocketGarden
//
//  Created by 伊藤瞭汰 on 2025/05/11.
//

import SwiftUI
import Charts

struct StatisticsView: View {
    @EnvironmentObject private var vm: GardenViewModel
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdays = ["日", "月", "火", "水", "木", "金", "土"]
    @State private var selectedMonth = Date()
    @State private var selectedDay: Date? = nil
    @State private var showMonthYearPicker = false
    @State private var tempYear = Calendar.current.component(.year, from: Date())
    @State private var tempMonth = Calendar.current.component(.month, from: Date())
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Study Heat-map")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // 月選択ピッカー
                HStack {
                    Button(action: { selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth)! }) {
                        Image(systemName: "chevron.left")
                    }
                    
                    Button {
                        tempYear = Calendar.current.component(.year, from: selectedMonth)
                        tempMonth = Calendar.current.component(.month, from: selectedMonth)
                        showMonthYearPicker = true
                    } label: {
                        Text(monthYearFormatter.string(from: selectedMonth))
                            .font(.headline)
                            .padding(.horizontal)
                            .foregroundColor(.primary)
                    }
                    
                    Button(action: { selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth)! }) {
                        Image(systemName: "chevron.right")
                    }
                }
                .padding(.bottom, 8)
                
                // 曜日ヘッダー
                HStack {
                    ForEach(weekdays, id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                    }
                }
                
                // カレンダーグリッド
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(daysInMonth(), id: \.self) { day in
                        if let day = day {
                            let minutes = minutesForDay(day)
                            Button {
                                selectedDay = day
                            } label: {
                                VStack {
                                    Text("\(Calendar.current.component(.day, from: day))")
                                        .font(.caption2)
                                        .foregroundColor(.primary)
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(colorForMinutes(minutes))
                                        .frame(height: 28)
                                        .overlay(
                                            Text(minutes > 0 ? "\(minutes)分" : "")
                                                .font(.system(size: 10))
                                                .foregroundColor(.white)
                                        )
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            Color.clear
                                .frame(height: 50)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("統計")
        .sheet(item: $selectedDay) { day in
            DayDetailView(date: day)
        }
        .sheet(isPresented: $showMonthYearPicker) {
            MonthYearPickerView(
                year: $tempYear,
                month: $tempMonth,
                isPresented: $showMonthYearPicker,
                onDone: {
                    if let newDate = Calendar.current.date(from: DateComponents(year: tempYear, month: tempMonth, day: 1)) {
                        selectedMonth = newDate
                    }
                }
            )
        }
    }
    
    // 当月のすべての日を取得（前月末と翌月初めの日を含む）
    private func daysInMonth() -> [Date?] {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: selectedMonth)!
        let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth))!
        let firstWeekday = calendar.component(.weekday, from: firstDay) - 1 // 0が日曜
        
        var days = [Date?](repeating: nil, count: firstWeekday)
        
        for day in 1...range.count {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        
        // 最後の週を埋める
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    // 指定日のフォーカス時間（分）を取得
    private func minutesForDay(_ date: Date) -> Int {
        let calendar = Calendar.current
        return vm.aggregatedStudyMinutes().filter { 
            calendar.isDate($0.date, inSameDayAs: date)
        }.first?.minutes ?? 0
    }
    
    // 時間に応じた色を返す
    private func colorForMinutes(_ minutes: Int) -> Color {
        switch minutes {
        case 0: return Color("LeafPrimary").opacity(0.15)
        case 1...25: return Color("LeafPrimary").opacity(0.3)
        case 26...50: return Color("LeafPrimary").opacity(0.5)
        case 51...100: return Color("LeafPrimary").opacity(0.7)
        default: return Color("LeafPrimary").opacity(0.9)
        }
    }
    
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter
    }
}

extension Date: Identifiable {
    public var id: Self { self }
}

// 日の詳細ビュー
struct DayDetailView: View {
    let date: Date
    @EnvironmentObject private var vm: GardenViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text(dateFormatter.string(from: date))
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("フォーカス時間の詳細")
                    .font(.headline)
                
                if dayFocusSessions.isEmpty {
                    Text("この日のフォーカスセッションはありません")
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    // 横軸が時間のチャート
                    Chart {
                        ForEach(dayFocusSessions) { session in
                            BarMark(
                                x: .value("時間", hourFormatter.string(from: session.date)),
                                y: .value("分", session.minutes)
                            )
                            .foregroundStyle(Color.green.gradient)
                        }
                    }
                    .frame(height: 200)
                    .padding()
                    
                    // セッション一覧
                    List {
                        ForEach(dayFocusSessions) { session in
                            HStack {
                                Text(timeFormatter.string(from: session.date))
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                Text("\(session.minutes)分")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .padding(.horizontal)
            .navigationTitle("日次詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // この日のフォーカスセッション（時間帯別）
    private var dayFocusSessions: [FocusSession] {
        // 仮のデータを生成（本来はGardenViewModelから取得）
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        // GardenViewModelから取得したタスクをもとにフォーカスセッションを生成
        var sessions: [FocusSession] = []
        
        // 完了したタスクを元にセッションを推定
        let completedTasks = vm.tasks.filter { 
            task in task.isDone && calendar.isDate(task.createdAt, inSameDayAs: date)
        }
        
        for (index, task) in completedTasks.enumerated() {
            // 各タスクに対して25分のフォーカスセッションを割り当て
            if let hour = calendar.dateComponents([.hour], from: task.createdAt).hour {
                let sessionDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: startOfDay)!
                sessions.append(FocusSession(id: UUID(), date: sessionDate, minutes: 25))
            }
        }
        
        return sessions.sorted { $0.date < $1.date }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }
    
    private var hourFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "H時"
        return formatter
    }
}

// フォーカスセッションモデル
struct FocusSession: Identifiable {
    let id: UUID
    let date: Date
    let minutes: Int
}

// 年月ピッカー
struct MonthYearPickerView: View {
    @Binding var year: Int
    @Binding var month: Int
    @Binding var isPresented: Bool
    let onDone: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Picker("年", selection: $year) {
                        ForEach(2020...2030, id: \.self) { year in
                            Text("\(year)年").tag(year)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 150)
                    
                    Picker("月", selection: $month) {
                        ForEach(1...12, id: \.self) { month in
                            Text("\(month)月").tag(month)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 150)
                }
                .padding()
            }
            .navigationTitle("日付を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") {
                        onDone()
                        isPresented = false
                    }
                }
            }
        }
    }
}
