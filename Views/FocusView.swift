//
//  FocusView.swift
//  PocketGarden
//
//  Created by 伊藤瞭汰 on 2025/05/11.
//

import SwiftUI

struct FocusView: View {
    @EnvironmentObject private var vm: GardenViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            FocusBackground(progress: progress, phase: vm.focusPhase)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                CircleTimer(progress: progress,
                            remainingSec: vm.remainingSeconds,
                            phase: vm.focusPhase,
                            sessionCount: vm.sessionCount)
                    .frame(width: 220, height: 220)
                
                HStack(spacing: 32) {
                    Button {
                        vm.skipPhase()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 32))
                    }

                    Button {
                        vm.pauseFocus()
                    } label: {
                        Image(systemName: vm.isTimerRunning ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 32))
                    }
                    
                    Button {
                        vm.focusPhase = .stopped
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                    }
                }
                .padding(.horizontal)
            }
        }
        .onReceive(vm.$focusPhase) { phase in
            if phase == .stopped && vm.remainingSeconds <= 0 { dismiss() }
        }
    }
    
    private var progress: Double {
        let denom = vm.focusPhase == .focus ? 1500.0 : 300.0
        return 1.0 - Double(vm.remainingSeconds) / denom
    }
}

// MARK: - Sub-Views
fileprivate struct CircleTimer: View {
    let progress: Double
    let remainingSec: Int
    let phase: FocusPhase
    let sessionCount: Int
    @State private var glow = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 16)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(phase == .focus ? Color("LeafPrimary") : Color.blue,
                        style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear, value: progress)
                .shadow(color: glow ? Color("LeafSecondary").opacity(reduceMotion ? 0.2 : 0.6) : Color.clear,
                        radius: glow ? 24 : 16)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
                    // この効果は完全に視覚的なものなので、アプリ終了時に何もする必要はありません
                }
            
            VStack {
                Text("Session: \(sessionCount)")
                    .font(.system(size: 16, weight: .medium))
                    .padding(.bottom, 5)
                
                Text(timeString)
                    .font(.system(size: 38, weight: .medium, design: .monospaced))
            }
        }
        .onChange(of: remainingSec) { sec in
            if sec == 5 && !glow && !reduceMotion && phase == .focus {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    glow = true
                }
            }
            if sec == 0 || sec > 5 || phase == .rest {
                withAnimation(.none) {
                    glow = false
                }
            }
        }
    }
    private var timeString: String {
        let m = remainingSec / 60
        let s = remainingSec % 60
        return String(format: "%02d:%02d", m, s)
    }
}

fileprivate struct FocusBackground: View {
    let progress: Double
    let phase: FocusPhase
    
    var body: some View {
        LinearGradient(colors: colors,
                       startPoint: .top, endPoint: .bottom)
            .animation(.easeInOut(duration: 2.0), value: phase)
            .animation(.easeInOut(duration: 0.5), value: progress)
    }
    private var colors: [Color] {
        switch phase {
        case .focus:
            // 深めの青と白のグラデーション - フォーカス時
            return [
                Color.white,
                Color.blue.opacity(0.25)
            ]
        case .rest:
            // 少し深めの青のグラデーション - 休憩時
            return [
                Color.white,
                Color.blue.opacity(0.18)
            ]
        case .stopped:
            // 最も薄いグレーのグラデーション - 停止時
            return [
                Color.white,
                Color.gray.opacity(0.05)
            ]
        }
    }
}
