import SwiftUI

struct ExpGaugeView: View {
    let currentExp: Int
    let currentLevel: Int
    let maxExp: Int  // 次のレベルまでの必要EXP
    @State private var animatedProgress: Double = 0.0
    @State private var showLevelUp = false
    @State private var pulsing = false
    
    // 新しいEXP増加アニメーション用の状態
    @State private var expGain = false
    @State private var gainAmount = 0
    @State private var previousExp = 0
    @State private var previousLevel = 0  // レベルアップ検知用
    @EnvironmentObject private var vm: GardenViewModel
    
    // レベルアップエフェクト用
    @State private var levelUpScale: CGFloat = 1.0
    @State private var levelUpRings: [RingEffect] = []
    @State private var showLevelUpText = false
    @State private var levelUpSparkles: [SparkleEffect] = []
    
    // エフェクト用データ構造
    struct RingEffect: Identifiable {
        let id = UUID()
        var scale: CGFloat = 1.0
        var opacity: Double = 1.0
    }
    
    struct SparkleEffect: Identifiable {
        let id = UUID()
        var position: CGPoint
        var scale: CGFloat = 1.0
        var opacity: Double = 1.0
    }
    
    // 現在レベル内での進行度を計算
    private var progressInCurrentLevel: Double {
        // 現在のレベルの開始EXP
        let currentLevelStartExp = currentLevel * 10
        // 次のレベルの開始EXP  
        let nextLevelStartExp = (currentLevel + 1) * 10
        // 現在レベル内でのEXP進行度
        let expInCurrentLevel = currentExp - currentLevelStartExp
        // このレベルで必要なEXP総量
        let expNeededForThisLevel = nextLevelStartExp - currentLevelStartExp
        
        if expNeededForThisLevel <= 0 { return 0.0 }
        return min(1.0, max(0.0, Double(expInCurrentLevel) / Double(expNeededForThisLevel)))
    }
    
    // 次のレベルまでのポイント数
    private var expToNextLevel: Int {
        let nextLevelStartExp = (currentLevel + 1) * 10
        return nextLevelStartExp - currentExp
    }
    
    // 表示用レベル（内部レベル+1）
    private var displayLevel: Int {
        return currentLevel + 1
    }
    
    var body: some View {
        ZStack {
            // 背景リング（グレー）
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                .frame(width: 150, height: 150)
            
            // 進行度リング（緑）
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    Color("LeafPrimary"),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 150, height: 150)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.8), value: animatedProgress)
            
            // 中央テキスト表示
            VStack(spacing: 4) {
                Text("Lv")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text("\(displayLevel)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("あと \(expToNextLevel)pt で Lv Up")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            
            // レベルアップエフェクト：拡散リング
            ForEach(levelUpRings) { ring in
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color("LeafPrimary"), Color("LeafPrimary").opacity(0.5)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 150, height: 150)
                    .scaleEffect(ring.scale)
                    .opacity(ring.opacity)
            }
            
            // レベルアップエフェクト：キラキラ
            ForEach(levelUpSparkles) { sparkle in
                Image(systemName: "sparkle")
                    .font(.system(size: 16))
                    .foregroundColor(.yellow)
                    .position(sparkle.position)
                    .scaleEffect(sparkle.scale)
                    .opacity(sparkle.opacity)
            }
            
            // レベルアップテキスト
            if showLevelUpText {
                Text("LEVEL UP!")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [Color("LeafPrimary"), Color("LeafPrimary").opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    .scaleEffect(levelUpScale)
                    .offset(y: -100)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .scaleEffect(expGain ? 1.1 : (pulsing ? 1.05 : 1.0))
        .overlay(
            // +X EXP 表示
            Group {
                if expGain && gainAmount > 0 {
                    Text("+\(gainAmount) EXP")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.green)
                        .offset(y: -100)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        )
        .onAppear {
            // 初期表示時にアニメーション
            previousExp = currentExp
            previousLevel = currentLevel
            withAnimation(.easeInOut(duration: 1.0)) {
                animatedProgress = progressInCurrentLevel
            }
        }
        .onChange(of: currentExp) { oldValue, newValue in
            let expDelta = newValue - oldValue
            
            // EXP増加時のアニメーション
            if expDelta > 0 {
                gainAmount = expDelta
                
                // スプリングアニメーションでパルス
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    expGain = true
                }
                
                // プログレス更新アニメーション
                withAnimation(.easeInOut(duration: 0.8)) {
                    animatedProgress = progressInCurrentLevel
                }
                
                // 0.8秒後にEXP表示を非表示
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        expGain = false
                    }
                }
            } else {
                // EXP変更時（減少も含む）
                withAnimation(.easeInOut(duration: 0.8)) {
                    animatedProgress = progressInCurrentLevel
                }
            }
            
            previousExp = newValue
        }
        .onChange(of: currentLevel) { oldLevel, newLevel in
            // レベルアップ検知
            if newLevel > oldLevel {
                triggerLevelUpEffect()
            }
            previousLevel = newLevel
        }
    }
    
    // レベルアップエフェクトをトリガー
    private func triggerLevelUpEffect() {
        // テキスト表示
        showLevelUpText = true
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            levelUpScale = 1.2
        }
        
        // 拡散リングを作成（3つのリングを0.2秒間隔で）
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                createExpandingRing()
            }
        }
        
        // キラキラエフェクト
        createSparkles()
        
        // 1.5秒後にテキストを縮小
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.3)) {
                levelUpScale = 1.0
            }
        }
        
        // 2秒後にすべてクリーンアップ
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showLevelUpText = false
            levelUpRings.removeAll()
            levelUpSparkles.removeAll()
        }
    }
    
    // 拡散リング作成
    private func createExpandingRing() {
        let ring = RingEffect()
        levelUpRings.append(ring)
        
        // リングを拡大＆フェードアウト
        if let index = levelUpRings.firstIndex(where: { $0.id == ring.id }) {
            withAnimation(.easeOut(duration: 1.0)) {
                levelUpRings[index].scale = 2.0
                levelUpRings[index].opacity = 0.0
            }
        }
    }
    
    // キラキラエフェクト作成
    private func createSparkles() {
        // 円周上に8個のキラキラを配置
        for i in 0..<8 {
            let angle = Double(i) * .pi / 4
            let radius: CGFloat = 80
            let x = 75 + cos(angle) * radius  // 中心からの位置
            let y = 75 + sin(angle) * radius
            
            let sparkle = SparkleEffect(position: CGPoint(x: x, y: y))
            levelUpSparkles.append(sparkle)
            
            // キラキラアニメーション
            if let index = levelUpSparkles.firstIndex(where: { $0.id == sparkle.id }) {
                // 少し遅れて開始（バラつかせる）
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) {
                    withAnimation(.easeOut(duration: 1.5)) {
                        levelUpSparkles[index].scale = 1.5
                        levelUpSparkles[index].opacity = 0.0
                    }
                }
            }
        }
    }
}

// プレビュー用
#Preview {
    VStack(spacing: 30) {
        // レベル1表示、進行度50%（5pt / 10pt、内部level=0）
        ExpGaugeView(
            currentExp: 5,
            currentLevel: 0,
            maxExp: 10
        )
        .frame(width: 200, height: 200)
        
        // レベル2表示、進行度70%（17pt、内部level=1、10-20ptなので7pt/10pt = 70%）
        ExpGaugeView(
            currentExp: 17,
            currentLevel: 1,
            maxExp: 20
        )
        .frame(width: 200, height: 200)
    }
    .padding()
} 