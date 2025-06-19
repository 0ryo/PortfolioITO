import SwiftUI

struct FocusView: View {
    @EnvironmentObject private var vm: GardenViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var focusTimer = FocusTimerManager()
    
    var body: some View {
        ZStack {
            // Background Gradient
            FocusBackground()
            
            VStack(spacing: 40) {
                // Timer Display
                CircleTimer(
                    remainingSeconds: focusTimer.remainingSeconds,
                    phase: focusTimer.focusPhase
                )
                
                // Session Count
                Text("セッション \(focusTimer.sessionCount)")
                    .font(.title2)
                    .foregroundColor(.white)
                
                // Control Buttons
                HStack(spacing: 30) {
                    Button {
                        focusTimer.pauseFocus()
                    } label: {
                        Image(systemName: focusTimer.isTimerRunning ? "pause.fill" : "play.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Circle().fill(.white.opacity(0.2)))
                    }
                    
                    Button {
                        focusTimer.skipPhase()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Circle().fill(.white.opacity(0.2)))
                    }
                    
                    Button("終了") {
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(.white.opacity(0.2)))
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Focus画面表示時にタイマーを開始
            focusTimer.startFocus()
            
            // コールバック設定
            focusTimer.onFocusComplete = {
                // 集中完了時にGardenViewModelに通知
                vm.completeTask(category: vm.currentCategory)
            }
        }
    }
}

// MARK: - Circle Timer
struct CircleTimer: View {
    let remainingSeconds: Int
    let phase: FocusPhase
    
    var body: some View {
        ZStack {
            // Background Circle
            Circle()
                .stroke(.white.opacity(0.3), lineWidth: 12)
                .frame(width: 200, height: 200)
            
            // Progress Circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(.white, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1), value: progress)
            
            // Time Text
            VStack(spacing: 8) {
                Text(phaseText)
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                
                Text(timeText)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Computed Properties
    private var progress: Double {
        let totalSeconds = phase == .focus ? 25 * 60 : 5 * 60
        return 1.0 - (Double(remainingSeconds) / Double(totalSeconds))
    }
    
    private var phaseText: String {
        switch phase {
        case .focus: return "集中時間"
        case .rest: return "休憩時間"
        case .stopped: return "停止中"
        }
    }
    
    private var timeText: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Focus Background
struct FocusBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.4, blue: 0.8),
                Color(red: 0.2, green: 0.6, blue: 0.9),
                Color(red: 0.0, green: 0.3, blue: 0.7)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}
