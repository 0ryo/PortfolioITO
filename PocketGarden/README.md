# Pocket Garden 🌱

> *25分集中 → 5分休憩 → 瞬間成長！* - 学生のための最小限でハビット形成をサポートする、**SwiftUI Canvas**で作られたコンパニオンアプリ

---

## ✨ 実装済み機能

|  🌿  |  機能                                                                        | 状況  |
| ---- | --------------------------------------------------------------------------- | ----- |
|  1   | **タスクリストCRUD** - スワイプで追加/編集/削除                                   | ✅ 完了 |
|  2   | **フォーカスタイマー (25→5分ループ)** - 円型プログレスリング + 等幅フォントカウントダウン | ✅ 完了 |
|  3   | **ダイナミック植物成長** - `Canvas` & `Path`でベクター葉を生成                    | ✅ 完了 |
|  4   | **滑らかなアニメーション + ハプティクス** - スプリングスケールアップ & 葉の揺れ        | ✅ 完了 |
|  5   | **オフライン永続化** - `@AppStorage` + JSONバックアップ                         | ✅ 完了 |
|  6   | **統計・熱量マップ** - 日毎の総集中時間をカレンダー表示                           | ✅ 完了 |
|  7   | **完了タスク履歴** - 日付選択機能で過去の達成記録を閲覧                           | ✅ 完了 |
|  8   | **経験値システム** - レベルアップゲージとアニメーション                           | ✅ 完了 |
|  9   | **リファクタリング済み** - 責務分離とコンポーネント化                            | ✅ 完了 |

## 🏗 技術スタック

* **Swift 5.10** + **SwiftUI (iOS 17+)**
* `Canvas`, `TimelineView`, `GeometryEffect`, `CHHapticEngine`
* `Swift Charts` (熱量マップ)
* GitHub Actions - 全PRでビルド & リント

---

## 📁 ファイル構造

```
PocketGarden/
├── PocketGardenApp.swift           // アプリエントリーポイント
├── Models/                         // データモデル & ビジネスロジック
│   ├── Task.swift                  // タスクデータモデル
│   ├── GardenViewModel.swift       // メインビジネスロジック
│   └── FocusTimerManager.swift     // フォーカスタイマー専用管理
├── Views/                          // UI コンポーネント
│   ├── HomeView.swift              // メイン画面
│   ├── TaskListView.swift          // タスクリスト表示
│   ├── ActionButtonsView.swift     // アクションボタン群
│   ├── FocusView.swift             // フォーカス画面
│   ├── ExpGaugeView.swift          // 経験値ゲージ
│   ├── StatisticsView.swift        // 統計・カレンダー表示
│   ├── CompletedTasksView.swift    // 完了タスク履歴
│   ├── TaskCompletionEffectView.swift // タスク完了エフェクト
│   └── DebugControlsView.swift     // デバッグ用コントロール
├── Resources/                      // アセット・リソース
│   └── Assets.xcassets/
├── Tests/                          // テストファイル
└── README.md
```

---

## 🎯 アーキテクチャの特徴

### 責務分離の実現
- **HomeView**: 全体構成とナビゲーション（233行）
- **TaskListView**: タスク表示とアニメーション専用（124行）
- **FocusTimerManager**: タイマー機能とセッション管理専用（117行）
- **GardenViewModel**: コアビジネスロジック（145行）
- **DebugControlsView**: 開発時のみビルドされるテスト機能

### コード品質向上
- **可読性**: 単一責任原則の適用でコンポーネント分離
- **保守性**: 機能追加時の影響範囲を最小化
- **テスト可能性**: ユニットテスト完備（全てgreen）
- **再利用性**: コンポーネントベースの設計

---

## 🛠 開発環境セットアップ

```bash
# 1. クローン
$ git clone https://github.com/yourname/PocketGarden.git
$ cd PocketGarden

# 2. Xcode 15+で開く
$ open PocketGarden.xcodeproj

# 3. iOS 17シミュレーターまたはデバイスで実行
```

---

## 📜 ライセンス

Pocket Gardenは **MIT License** の下でリリースされています。詳細は `LICENSE` を参照してください。
