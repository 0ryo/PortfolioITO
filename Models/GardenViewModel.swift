//
//  GardenViewModel.swift
//  PocketGarden
//
//  Created by 伊藤瞭汰 on 2025/05/13.
//

import SwiftUI
import Combine
import os.log

enum FocusPhase { case focus, rest, stopped }

@MainActor
final class GardenViewModel: ObservableObject {
    // MARK: - Published States
    @Published private(set) var tasks: [Task] = []
    @Published private(set) var gardens: [String: GardenState] = ["Default": .init(exp: 0, level: 0)]
    @Published var currentCategory: String = "Default"
    
    // Focus Timer
    @Published var focusPhase: FocusPhase = .stopped
    @Published var remainingSeconds: Int = 25 * 60            // default 25 min
    @Published var sessionCount: Int = 1
    @Published var isTimerRunning: Bool = false
    @Published private(set) var lastLevelUp: Date? = nil
    
    private var timerCancellable: AnyCancellable?
    private var targetDate: Date? = nil
    
    // MARK: - TASK CRUD
    func addTask(_ title: String, category: String) {
        tasks.append(.init(title: title, category: category))
        save()
    }
    
    func addTask(_ task: Task) {
        tasks.append(task)
        save()
    }
    
    func toggleDone(task: Task) {
        guard let idx = tasks.firstIndex(of: task) else { return }
        tasks[idx].isDone.toggle()
        if tasks[idx].isDone { completeTask(category: task.category) }
        save()
    }
    
    func delete(task: Task) {
        tasks.removeAll { $0.id == task.id }
        save()
    }
    
    private func completeTask(category: String) {
        if gardens[category] == nil { gardens[category] = .init(exp: 0, level: 0) }
        let oldLevel = gardens[category]!.level
        gardens[category]!.addExp()
        if gardens[category]!.level > oldLevel {
            lastLevelUp = Date()
        }
    }
    
    // 一時的なリセット機能
    func resetExpAndLevel(category: String) {
        gardens[category] = .init(exp: 0, level: 0)  // level=0に統一
        save()
    }
    
    // テスト用のEXP増加機能
    func addExpForTest(category: String, amount: Int = 1) {
        if gardens[category] == nil { gardens[category] = .init(exp: 0, level: 0) }
        let oldLevel = gardens[category]!.level
        gardens[category]!.addExp(amount)
        if gardens[category]!.level > oldLevel {
            lastLevelUp = Date()
        }
        save()
    }
    
    // MARK: - FOCUS TIMER
    func startFocus() {
        focusPhase = .focus
        remainingSeconds = 25 * 60
        isTimerRunning = true
        targetDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        runTimer()
    }
    
    func pauseFocus() { 
        isTimerRunning.toggle()
        if isTimerRunning {
            // 再開時に残り時間から新しいtargetDateを計算
            targetDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))
            runTimer()
        } else {
            timerCancellable?.cancel()
        }
    }
    
    func skipPhase() { endPhase() }
    
    private func runTimer() {
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }
    
    private func tick() {
        remainingSeconds -= 1
        if remainingSeconds <= 0 { endPhase() }
    }
    
    private func endPhase() {
        timerCancellable?.cancel()
        switch focusPhase {
        case .focus:
            // ログを記録
            os_log("focus_end", type: .info, "remaining:%d", remainingSeconds)
            
            // 集中終了 → タスク 1 個分の EXP
            completeTask(category: currentCategory)
            focusPhase = .rest
            remainingSeconds = 5 * 60
            targetDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))
            isTimerRunning = true
            runTimer()
        case .rest:
            focusPhase = .focus
            remainingSeconds = 25 * 60
            targetDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))
            sessionCount += 1
            isTimerRunning = true
            runTimer()
        case .stopped:
            break
        }
    }
    
    // ScenePhaseが変更されたときに呼び出される
    func handleScenePhaseChange(to phase: ScenePhase) {
        if phase == .background {
            // バックグラウンドに移行したらタイマーを停止
            timerCancellable?.cancel()
        } else if phase == .active && isTimerRunning {
            // フォアグラウンドに戻ったらタイマーを再開し、残り時間を再計算
            if let target = targetDate {
                let now = Date()
                let remaining = Int(target.timeIntervalSince(now))
                // 0以下になった場合は終了
                if remaining <= 0 {
                    remainingSeconds = 0
                    endPhase()
                } else {
                    remainingSeconds = remaining
                    runTimer()
                }
            }
        }
    }
    
    // MARK: - Persistence (UserDefaults+JSON)
    private let key = "PocketGarden.store"
    
    func save() {
        let bundle = BundleData(tasks: tasks, gardens: gardens)
        guard let data = try? JSONEncoder().encode(bundle) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
    
    func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let bundle = try? JSONDecoder().decode(BundleData.self, from: data) else { return }
        tasks = bundle.tasks
        gardens = bundle.gardens
    }
    
    private struct BundleData: Codable {
        let tasks: [Task]
        let gardens: [String: GardenState]
    }
    
    // MARK: - Statistics (Heat-map)
    struct HeatEntry: Identifiable { let id = UUID(); let date: Date; let minutes: Int }
    
    func aggregatedStudyMinutes() -> [HeatEntry] {
        let calendar = Calendar.current
        // セッション=25min のみカウント
        var dict: [Date: Int] = [:]
        for task in tasks where task.isDone {
            let day = calendar.startOfDay(for: task.createdAt)
            dict[day, default: 0] += 25
        }
        return dict.map { HeatEntry(date: $0.key, minutes: $0.value) }
    }
}
