import SwiftUI
import Combine
import Foundation
import os.log

// MARK: - Focus Phase
enum FocusPhase {
    case focus, rest, stopped
}

// MARK: - Focus Timer Manager
final class FocusTimerManager: ObservableObject {
    // MARK: - Published States
    @Published var focusPhase: FocusPhase = .stopped
    @Published var remainingSeconds: Int = 25 * 60
    @Published var sessionCount: Int = 1
    @Published var isTimerRunning: Bool = false
    
    // MARK: - Private Properties
    private var timer: Timer?
    private var targetDate: Date?
    
    // MARK: - Callbacks
    var onFocusComplete: (() -> Void)?
    
    // MARK: - Public Methods
    func startFocus() {
        focusPhase = .focus
        remainingSeconds = 25 * 60
        isTimerRunning = true
        targetDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        runTimer()
    }
    
    func pauseFocus() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.isTimerRunning.toggle()
            if self.isTimerRunning {
                // 再開時に残り時間から新しいtargetDateを計算
                self.targetDate = Date().addingTimeInterval(TimeInterval(self.remainingSeconds))
                self.runTimer()
            } else {
                self.timer?.invalidate()
            }
        }
    }
    
    func skipPhase() {
        endPhase()
    }
    
    func handleScenePhaseChange(to phase: ScenePhase) {
        if phase == .background {
            // バックグラウンドに移行したらタイマーを停止
            timer?.invalidate()
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
    
    // MARK: - Private Methods
    private func runTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
    }
    
    @objc private func tick() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.remainingSeconds -= 1
            
            if self.remainingSeconds <= 0 {
                self.endPhase()
            }
        }
    }
    
    private func endPhase() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.timer?.invalidate()
            
            switch self.focusPhase {
            case .focus:
                // ログを記録
                os_log("focus_end", type: .info, "remaining:%d", self.remainingSeconds)
                
                // 集中終了時のコールバック実行
                self.onFocusComplete?()
                
                self.focusPhase = .rest
                self.remainingSeconds = 5 * 60
                self.targetDate = Date().addingTimeInterval(TimeInterval(self.remainingSeconds))
                self.isTimerRunning = true
                self.runTimer()
                
            case .rest:
                self.focusPhase = .focus
                self.remainingSeconds = 25 * 60
                self.targetDate = Date().addingTimeInterval(TimeInterval(self.remainingSeconds))
                self.sessionCount += 1
                self.isTimerRunning = true
                self.runTimer()
                
            case .stopped:
                break
            }
        }
    }
} 