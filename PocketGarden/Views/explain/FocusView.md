
# FocusView.swift 解説

このファイルは、ポモドーロテクニックに基づいた集中タイマー画面を定義しています。ユーザーがタスクに集中するための「集中時間」と、その後の「休憩時間」を交互に繰り返すタイマー機能を提供します。

## 構成要素

このファイルは3つの主要なSwiftUIビューで構成されています。

1.  `FocusView`: タイマー全体のUIとロジックを管理するメインビュー。
2.  `CircleTimer`: 残り時間を円形のプログレスバーと共に表示するビュー。
3.  `FocusBackground`: 画面の背景に表示されるグラデーションビュー。

---

### 1. `FocusView`

集中タイマー画面のメインビューです。

#### プロパティ

-   `@EnvironmentObject private var vm: GardenViewModel`:
    -   アプリ全体のデータ管理を行う `GardenViewModel` を受け取ります。集中セッションが完了したときに、タスク完了の処理を依頼するために使用します。
-   `@Environment(\.dismiss) private var dismiss`:
    -   現在のビューを閉じる（前の画面に戻る）ための機能を提供します。
-   `@StateObject private var focusTimer = FocusTimerManager()`:
    -   タイマーのロジック（開始、一時停止、スキップ、残り時間の計算など）をすべて管理する `FocusTimerManager` のインスタンスを作成します。
    -   `@StateObject` を使うことで、`FocusView` が再描画されても `focusTimer` のインスタンスは破棄されず、状態を維持し続けます。

#### `body`の中身

-   `ZStack`:
    -   背景 (`FocusBackground`) と前景のUI要素を重ねて表示します。

-   `VStack(spacing: 40)`:
    -   UI要素（タイマー、セッション数、ボタン）を垂直に配置します。
    -   `CircleTimer`: 残り時間と現在のフェーズ（集中/休憩）を表示します。
    -   `Text("セッション \(focusTimer.sessionCount)")`: 現在のセッション数を表示します。
    -   `HStack(spacing: 30)`: 操作ボタンを水平に配置します。
        -   **再生/一時停止ボタン**: `focusTimer.isTimerRunning` の状態に応じて、アイコンが「一時停止 (`pause.fill`)」と「再生 (`play.fill`)」に切り替わります。タップすると `focusTimer.pauseFocus()` が呼ばれ、タイマーが一時停止または再開します。
        -   **スキップボタン**: タップすると `focusTimer.skipPhase()` が呼ばれ、現在のフェーズ（集中または休憩）をスキップして次のフェーズに進みます。
        -   **終了ボタン**: タップすると `dismiss()` が呼ばれ、`HomeView` に戻ります。

-   `.navigationBarHidden(true)`:
    -   この画面ではナビゲーションバーを非表示にし、没入感を高めます。

-   `.onAppear`:
    -   このビューが表示されたときに実行されます。
    -   `focusTimer.startFocus()`: タイマーを開始します。
    -   `focusTimer.onFocusComplete = { ... }`: タイマーの集中フェーズが完了したときに実行される処理（コールバック）を設定します。ここでは、`vm.completeTask(category:)` を呼び出して、現在のカテゴリのタスクを完了させ、経験値を獲得する処理を依頼しています。

---

### 2. `CircleTimer`

円形のタイマー表示を担当するコンポーネントです。

#### プロパティ

-   `let remainingSeconds: Int`: 表示すべき残り時間（秒）。
-   `let phase: FocusPhase`: 現在のタイマーの状態（集中、休憩、停止中）。

#### `body`の中身

-   `ZStack`:
    -   背景の円、進行度を示す円、そして中央のテキストを重ね合わせます。
    -   **背景の円**: `Circle().stroke(...)` で薄い白色の円を描画します。
    -   **進行度の円**: `Circle().trim(...)` を使って、時間の経過とともに円弧が伸びていくアニメーションを表現します。`progress`（計算プロパティ）の値に応じて円弧の長さが変わります。
    -   **中央のテキスト**: `VStack` を使って、現在のフェーズ名（「集中時間」など）と、残り時間を「分:秒」形式で表示します。

#### 計算プロパティ

-   `progress: Double`:
    -   残り時間から、ゲージの進行度を0.0〜1.0の値で計算します。時間は減っていくので、`1.0 - (残り時間 / 全体時間)` という計算式になっています。
-   `phaseText: String`:
    -   `phase` の値に応じて、「集中時間」「休憩時間」「停止中」のいずれかの文字列を返します。
-   `timeText: String`:
    -   `remainingSeconds` を分と秒に変換し、「04:59」のような `MM:SS` 形式の文字列を作成します。

---

### 3. `FocusBackground`

画面全体の背景を描画するビューです。

#### `body`の中身

-   `LinearGradient`:
    -   複数の青系の色を使って、左上から右下にかけて色が変化する美しいグラデーション背景を作成します。
-   `.ignoresSafeArea()`:
    -   ステータスバー領域などを含め、画面全体をグラデーションで塗りつぶします。

## 使い方

`HomeView` の「Start Focus」ボタンをタップすると、この `FocusView` が全画面で表示されます。ユーザーはここで集中セッションを開始し、完了すると自動的にタスクが達成され、経験値を獲得できます。
