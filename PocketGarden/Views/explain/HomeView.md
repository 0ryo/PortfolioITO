
# HomeView.swift 解説

このファイルは、PocketGardenアプリのメイン画面（ホーム画面）を定義しています。ユーザーの進捗（経験値ゲージ）、タスクリスト、そして他の画面へのナビゲーション機能など、アプリの中心となる要素を統合しています。

## 構成要素

このファイルは `HomeView` を中心に、タスク追加用の `AddTaskSheet`、日付選択用の `DateSelectionRow` と `DatePickerSheet` など、複数のビューで構成されています。

---

### 1. `HomeView`

アプリのメイン画面です。

#### プロパティ

-   `@EnvironmentObject private var vm: GardenViewModel`:
    -   アプリ全体のデータとロジックを管理する `GardenViewModel` を受け取ります。このビュー内のほぼすべてのコンポーネントがこの `vm` を参照して、データの表示や更新を行います。
-   `@State private var showAdd: Bool = false`:
    -   新規タスク追加用のシート (`AddTaskSheet`) を表示するかどうかを管理するフラグです。
-   `@State private var goFocus: Bool = false`:
    -   集中タイマー画面 (`FocusView`) へ遷移するかどうかを管理するフラグです。`ActionButtonsView` に `Binding` として渡されます。
-   `@State private var completingTasks: Set<UUID> = []`:
    -   完了アニメーション中のタスクのIDを保持する集合（Set）。`TaskListView` に渡され、アニメーションの制御に使われます。
-   `@State private var expandingTasks: Set<UUID> = []`:
    -   タスク完了時に一瞬拡大するアニメーション対象のタスクIDを保持する集合。同様に `TaskListView` に渡されます。
-   `@State private var showCompletionEffect: Bool = false`:
    -   タスク完了時のチェックマークエフェクト (`TaskCompletionEffectView`) を表示するためのフラグです。

#### `body`の中身

-   `NavigationStack`:
    -   画面遷移（ナビゲーション）を管理するためのコンテナです。これにより、`NavigationLink` や `.navigationDestination` が機能します。

-   `VStack(spacing: 20)`:
    -   画面の主要な要素（経験値ゲージ、タスクリスト、アクションボタン）を垂直に配置します。

-   `ExpGaugeView`:
    -   現在のカテゴリの庭の経験値 (`exp`) とレベル (`level`) を `vm` から取得して表示します。

-   `ZStack`:
    -   `TaskListView` と `TaskCompletionEffectView` を重ねて表示します。
    -   `TaskListView`: 未完了のタスクリストを表示します。
    -   `TaskCompletionEffectView`: `showCompletionEffect` が `true` のときだけ、タスクリストの上にチェックマークのエフェクトをオーバーレイ表示します。

-   `ActionButtonsView`:
    -   「Start Focus」ボタンと「達成したタスク」へのリンクを表示します。`goFocus` を `Binding` で渡しているため、このビュー内のボタンで画面遷移をトリガーできます。

-   `.navigationTitle("Pocket Garden")`:
    -   画面上部のナビゲーションバーにタイトルを表示します。

-   `.toolbar { ... }`:
    -   ナビゲーションバーや下部のバーにボタンを追加します。
        -   `ToolbarItem(placement: .navigationBarTrailing)`: 右上に「+」ボタンを配置し、タップすると `showAdd` が `true` になり、タスク追加シートが表示されます。
        -   `ToolbarItem(placement: .navigationBarLeading)`: 左上に「Stats」への `NavigationLink` を配置し、統計画面 (`StatisticsView`) へ遷移できるようにします。
        -   `ToolbarItem(placement: .bottomBar)`: 画面下部のツールバーに `CompleteAllTasksButton` を配置します。

-   `.sheet(isPresented: $showAdd) { AddTaskSheet() }`:
    -   `showAdd` が `true` になると、`AddTaskSheet` をモーダル表示します。

-   `.navigationDestination(isPresented: $goFocus) { FocusView() }`:
    -   `goFocus` が `true` になると、`FocusView` へと画面遷移します。これは SwiftUI の新しいナビゲーション方法です。

---

### 2. `AddTaskSheet`

新しいタスクを追加するためのフォーム画面です。

#### プロパティ

-   `@Environment(\.dismiss)`: シートを閉じるための機能。
-   `@EnvironmentObject private var vm`: `GardenViewModel` を使ってタスクを追加するため。
-   `@State` 変数群: タスク名 (`title`)、カテゴリ (`selectedCategory`)、開始/終了日時、締切日などのユーザー入力を保持します。

#### `body`の中身

-   `NavigationStack` と `Form` を使って、入力項目を整理されたリスト形式で表示します。
-   `TextField`: タスク名を入力します。
-   `Picker`: `vm` が持つ庭のカテゴリリストから、タスクのカテゴリを選択します。
-   `DateSelectionRow`: 日付や時刻を表示し、タップすると対応する `DatePickerSheet` を表示するためのカスタムビューです。
-   ツールバーに「キャンセル」と「追加」ボタンを配置。「追加」ボタンを押すと、入力された情報から新しい `Task` オブジェクトを作成し、`vm.addTask()` メソッドを呼び出して保存します。その後、`dismiss()` でシートを閉じます。

---

### 3. `DateSelectionRow` と `DatePickerSheet`

これらは `AddTaskSheet` 内で日付や時刻をユーザーに選択させるための補助的なビューです。

-   `DateSelectionRow`:
    -   「開始日時」などのラベルと、選択された日時をフォーマットして表示します。
    -   タップされると、`action` クロージャを実行し、対応する `DatePickerSheet` を表示させます。

-   `DatePickerSheet`:
    -   グラフィカルな `DatePicker` をモーダル表示するためのビューです。
    -   `@Binding` で渡された `date` を更新し、「完了」ボタンでシートを閉じます。

## 使い方

`HomeView` はアプリ起動時に最初に表示される画面です。ここからすべての主要機能（タスク管理、集中タイマー、統計確認）にアクセスできます。状態管理は `GardenViewModel` に集約されており、`HomeView` はそのデータを元にUIを構築し、ユーザー操作を `ViewModel` に伝える役割を担っています。
