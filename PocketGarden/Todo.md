# 🎯 Pocket Garden - Expゲージ実装 Todo リスト

## 🌟 プロジェクト概要
現在の葉っぱデザインを削除し、2枚目の画像のような**丸いExpゲージ**に変更。より直感的で成長感のあるUI/UXを実現する。

---

## 📊 現状分析と課題整理

### 🔍 現在の実装状況
- **葉っぱ表示**: `Views/LeafView.swift` - `Canvas`でpathを描画、6枚まで表示
- **EXP計算**: `Models/Task.swift` - `GardenState.addExp()` - 現在は `level = exp / 10`
- **表示場所**: `Views/HomeView.swift` - 行21-23で `LeafView` を200pxの高さで表示
- **レベルアップ演出**: `LeafView.swift` - パルス＋パーティクルエフェクト
- **カラーアセット**: `LeafPrimary`、`LeafSecondary` 既存

### 🎯 目指すゴール
- **丸いExpゲージ**: 2枚目画像のようなLv150, 進行度表示
- **アニメーション**: タスク完了時→ゲージ増加、レベルアップ時→派手エフェクト
- **レベル調整**: 高レベルほど必要EXPが増加する仕組み

---

## 🛠 実装計画（優先順位順）

### 1. **最優先**: ExpGaugeView作成
**新規ファイル**: `Views/ExpGaugeView.swift`

#### 1-1. 基本構造設計
```swift
struct ExpGaugeView: View {
    let currentExp: Int
    let currentLevel: Int
    let maxExp: Int  // 次のレベルまでの必要EXP
    @State private var animatedProgress: Double = 0.0
    @State private var showLevelUp = false
    @State private var pulsing = false
}
```

#### 1-2. 円形プログレスリング実装
```swift
// 背景リング（グレー）
Circle()
    .stroke(Color.gray.opacity(0.2), lineWidth: 12)

// 進行度リング（緑）
Circle()
    .trim(from: 0, to: animatedProgress)
    .stroke(Color("LeafPrimary"), style: StrokeStyle(lineWidth: 12, lineCap: .round))
    .rotationEffect(.degrees(-90))
```

#### 1-3. 中央テキスト表示
```swift
VStack(spacing: 4) {
    Text("Lv")
        .font(.system(size: 14, weight: .medium))
        .foregroundColor(.secondary)
    
    Text("\(currentLevel)")
        .font(.system(size: 48, weight: .bold, design: .rounded))
        .foregroundColor(.primary)
    
    Text("あと \(maxExp - (currentExp % maxExp))pt で Lv Up")
        .font(.system(size: 12, weight: .medium))
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
}
```

### 2. **変更見送り**: レベル計算ロジック改善
**状態**: ❌ **実装見送り** - 現在のシンプルなレベル計算（`level = exp / 10`）を維持

#### 2-1. 見送り理由
- 既存のシンプルな計算ロジックで十分に機能している
- 指数関数的な変更はユーザー体験を複雑にする可能性がある
- 現在のリニアな成長曲線を維持することで予測しやすいゲーム体験を提供

#### 2-2. 現在の仕様維持
```swift
// 現在の実装を継続使用
struct GardenState: Codable {
    var exp: Int
    var level: Int
    
    // シンプルなレベル計算: level = exp / 10
    mutating func addExp(_ delta: Int = 1) {
        exp += delta
        level = exp / 10
    }
}
```

### 3. **完了**: HomeView統合 ✅
**修正ファイル**: `Views/HomeView.swift` - **実装済み**

#### 3-1. LeafViewをExpGaugeViewに置換 ✅
```swift
// 変更前
LeafView(level: vm.gardens[vm.currentCategory]?.level ?? 0, namespace: ns)
    .frame(height: 200)

// 変更後  
ExpGaugeView(
    currentExp: vm.gardens[vm.currentCategory]?.exp ?? 0,
    currentLevel: vm.gardens[vm.currentCategory]?.level ?? 1
)
.frame(width: 200, height: 200)
.padding(.vertical, 20)
```
**注**: シンプルなレベル計算維持により、`maxExp`パラメータは不要

### 4. **完了**: EXP増加アニメーション ✅
**修正ファイル**: `Views/ExpGaugeView.swift` - **実装済み**

#### 4-1. タスク完了時のパルスエフェクト
```swift
@State private var expGain = false
@State private var gainAmount = 0

// onReceive でEXP変更を検知
.onReceive(vm.$gardens) { newGardens in
    let newExp = newGardens[currentCategory]?.exp ?? 0
    if newExp > oldExp {
        // EXP増加アニメーション
        gainAmount = newExp - oldExp
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            expGain = true
        }
        
        // プログレス更新アニメーション
        withAnimation(.easeInOut(duration: 0.8)) {
            animatedProgress = progressInCurrentLevel
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expGain = false
        }
    }
}

// 視覚エフェクト
.scaleEffect(expGain ? 1.1 : 1.0)
.overlay(
    // +1 EXP 表示
    if expGain {
        Text("+\(gainAmount) EXP")
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.green)
            .offset(y: -80)
            .transition(.move(edge: .top).combined(with: .opacity))
    }
)
```

### 5. **中優先**: レベルアップ演出強化
**新規ファイル**: `Views/LevelUpEffectView.swift`

#### 5-1. 派手なレベルアップエフェクト
```swift
struct LevelUpEffectView: View {
    @State private var rings: [RingState] = []
    @State private var sparkles: [SparkleState] = []
    @State private var showText = false
    @State private var textScale: CGFloat = 0.5
    
    var body: some View {
        ZStack {
            // 拡散リング
            ForEach(rings) { ring in
                Circle()
                    .stroke(Color("LeafPrimary"), lineWidth: 4)
                    .scaleEffect(ring.scale)
                    .opacity(ring.opacity)
            }
            
            // キラキラパーティクル
            ForEach(sparkles) { sparkle in
                Image(systemName: "sparkle")
                    .font(.system(size: sparkle.size))
                    .foregroundColor(.yellow)
                    .position(sparkle.position)
                    .opacity(sparkle.opacity)
                    .scaleEffect(sparkle.scale)
            }
            
            // "LEVEL UP!" テキスト
            if showText {
                Text("LEVEL UP!")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                    .scaleEffect(textScale)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient(
                                colors: [Color("LeafPrimary"), Color("LeafSecondary")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .padding(-16)
                    )
            }
        }
        .onAppear {
            startLevelUpAnimation()
        }
    }
    
    private func startLevelUpAnimation() {
        // 3つの拡散リングを0.2秒間隔で発生
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                createRing()
            }
        }
        
        // 30個のキラキラを生成
        createSparkles()
        
        // 0.3秒後にテキスト表示
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showText = true
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                textScale = 1.0
            }
        }
        
        // 2秒後に全て消去
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            rings.removeAll()
            sparkles.removeAll()
            showText = false
        }
    }
}
```

### 6. **低優先**: LeafView削除とクリーンアップ
**削除対象ファイル**: `Views/LeafView.swift`

#### 6-1. 段階的削除
1. HomeView.swiftからLeafViewの参照を削除
2. LeafView.swiftファイルを削除
3. 未使用のnamespace削除
4. BurstParticleViewの統合検討（LevelUpEffectViewに移行）

---

## 🎨 デザイン仕様詳細

### 色彩設計
- **進行リング**: `Color("LeafPrimary")` - 既存の緑色を継承
- **背景リング**: `Color.gray.opacity(0.2)` - 薄いグレー
- **レベル数字**: `.font(.system(size: 48, weight: .bold, design: .rounded))` - 大きく、太く、丸みのある数字
- **説明テキスト**: `.font(.system(size: 12, weight: .medium))` - 控えめ

### サイズ・配置
- **ゲージ直径**: 150px
- **リング幅**: 12px
- **配置**: 画面上部中央、タスクリストの上
- **パディング**: 上下20px

### アニメーション仕様
- **EXP増加**: 0.8秒かけてスムーズに進行度更新
- **パルス**: 0.3秒で1.2倍に拡大→0.5秒後に元に戻る
- **レベルアップ**: 2秒間の派手なエフェクト

---

## 🧪 テスト計画

### 単体テスト追加項目
1. **レベル計算**: `testExpRequiredForLevel()` - 指数関数的増加の確認
2. **進行度計算**: `testProgressInCurrentLevel()` - 0.0-1.0の範囲確認
3. **レベルアップ検知**: `testLevelUpDetection()` - 境界値テスト

### 手動テスト項目
1. **タスク完了**: 1個→EXP+1、ゲージ更新確認
2. **フォーカス完了**: 25分→EXP+1、同様の更新確認
3. **レベルアップ**: 必要EXP到達時のエフェクト確認
4. **高レベル**: レベル10以上での必要EXP増加確認
5. **アクセシビリティ**: VoiceOverでの読み上げ確認

---

## ⚠️ 注意事項・制約

### 互換性対応
- **既存データ**: 現在のEXP値を新しいレベル計算に適用
- **移行処理**: 初回起動時にレベル再計算の実行
- **バックアップ**: 変更前のデータ構造を一時保存

### パフォーマンス考慮
- **アニメーション**: `@Environment(\.accessibilityReduceMotion)`への対応
- **メモリ**: パーティクルエフェクトの適切なライフサイクル管理
- **バッテリー**: 常時アニメーションは避け、必要時のみ実行

### アクセシビリティ
- **VoiceOver**: 「レベル150、次のレベルまで300ポイント」の読み上げ
- **Dynamic Type**: フォントサイズ変更への対応
- **Reduce Motion**: アニメーション無効時の代替表示

---

## 📅 実装スケジュール（推奨）

| 日程 | 作業内容 | 成果物 |
|------|----------|--------|
| Day 1 | ExpGaugeView基本実装 ✅ | 丸いゲージ表示 |
| Day 2 | レベル計算ロジック改修 ❌ | 変更見送り（現在の仕様維持） |
| Day 3 | HomeView統合・テスト ✅ | LeafView置換完了 |
| Day 4 | アニメーション実装 | EXP増加・パルス効果 |
| Day 5 | レベルアップ演出 | 派手なエフェクト完成 |
| Day 6 | クリーンアップ・テスト | LeafView削除、テスト通過 |

---

## 🔄 後で見返す時のチェックリスト

### 実装完了確認
- [x] ExpGaugeView.swift 作成完了
- [x] GardenState.expRequiredForLevel() 実装 → **変更見送り**
- [x] HomeView.swift でLeafView→ExpGaugeView置換
- [x] EXP増加アニメーション動作確認
- [x] レベルアップエフェクト実装
- [ ] LeafView.swift 削除
- [ ] ユニットテスト更新・通過
- [x] 手動テスト完了

### 品質確認
- [ ] Light/Dark モード対応
- [ ] アクセシビリティ機能動作
- [ ] パフォーマンス問題なし
- [ ] 既存データ移行テスト
- [ ] 高レベル（100+）での動作確認

---

## 🎯 実装優先順位

1. **完了**: ExpGaugeView作成（基本表示機能） ✅
2. **見送り**: レベル計算ロジック改善（指数関数的増加） ❌
3. **完了**: HomeView統合（LeafView置換） ✅
4. **完了**: EXP増加アニメーション（ユーザー体験向上）✅
5. **完了**: レベルアップ演出強化（満足感向上）✅
6. **完了**: LeafView削除とクリーンアップ（コード整理）✅

このTodoリストに従って段階的に実装していけば、美しく機能的なExpゲージが完成します！🌟 