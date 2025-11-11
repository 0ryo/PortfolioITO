
# StatisticsView.swift 解説

このファイルは、ユーザーの学習活動に関する統計データを視覚的に表示する画面を定義しています。主に、特定の月の学習時間を日ごとに色分けして表示する「ヒートマップカレンダー」が中心的な機能です。

## 構成要素

このファイルは主に以下の4つのビューで構成されています。

1.  `StatisticsView`: 統計全体のメインビュー。ヒートマップカレンダーを表示します。
2.  `DayDetailView`: 特定の日付をタップしたときに、その日の詳細な学習データを表示するビュー。
3.  `MonthYearPickerView`: 年月を簡単に選択するためのカスタムピッカービュー。
4.  `FocusSession`: チャート表示用のデータモデル（構造体）。

---

### 1. `StatisticsView`

統計画面のメインビューです。

#### プロパティ

-   `@EnvironmentObject private var vm: GardenViewModel`: `ViewModel` から学習時間のデータを取得するために使用します。
-   `@State private var selectedMonth: Date`: 表示対象の月を管理します。
-   `@State private var selectedDay: Date?`: ユーザーがタップした日付を保持します。`nil` でない場合、`DayDetailView` がシートとして表示されます。
-   `@State private var showMonthYearPicker: Bool`: `MonthYearPickerView` を表示するかどうかのフラグです。
-   `@State private var tempYear`, `tempMonth`: `MonthYearPickerView` で一時的に年と月を保持するための変数です。

#### `body`の中身

-   `ScrollView`: コンテンツが画面に収まらない場合にスクロールできるようにします。
-   **月選択UI**:
    -   左右のシェブロン（`<`, `>`）ボタンで前後の月に移動できます。
    -   中央の年月表示ボタンをタップすると、`showMonthYearPicker` が `true` になり、`MonthYearPickerView` が表示されます。
-   **曜日ヘッダー**:
    -   「日」から「土」までの曜日ラベルを水平に表示します。
-   **カレンダーグリッド (`LazyVGrid`)**:
    -   `daysInMonth()`（後述）で生成された日付の配列を元に、7列のグリッドを構成します。
    -   各日付はボタンになっており、タップすると `selectedDay` にその日付がセットされます。
    -   `VStack` を使って、日付の数字と、その日の学習時間に応じた色の四角形 (`RoundedRectangle`) を表示します。
    -   `colorForMinutes()`（後述）メソッドが、学習時間（分）に応じて色の濃さを決定します。
-   `.sheet(item: $selectedDay)`:
    -   `selectedDay` に値が設定されると、その日付 (`day`) を使って `DayDetailView` をインスタンス化し、シートとして表示します。
-   `.sheet(isPresented: $showMonthYearPicker)`:
    -   `showMonthYearPicker` が `true` になると、`MonthYearPickerView` をシート表示します。

#### ヘルパーメソッド

-   `daysInMonth() -> [Date?]`:
    -   `selectedMonth` に基づいて、カレンダーに表示すべき日付の配列を生成します。
    -   月の初日が何曜日か計算し、それに応じて配列の先頭に `nil` を詰めて、カレンダーの開始位置を調整します。
    -   同様に、末尾も7の倍数になるように `nil` を詰めます。
-   `minutesForDay(_ date: Date) -> Int`:
    -   `ViewModel` の `aggregatedStudyMinutes()` から、特定の日付の合計学習分数を取得します。
-   `colorForMinutes(_ minutes: Int) -> Color`:
    -   学習分数に応じて、`Color("LeafPrimary")` の透明度を変化させた色を返します。学習時間が長いほど、色が濃くなります。

---

### 2. `DayDetailView`

特定の日付の学習詳細を表示するビューです。

#### `body`の中身

-   選択された日付を大きく表示します。
-   `dayFocusSessions`（後述）が空でなければ、`Charts` フレームワークを使って、時間帯ごとの学習時間を棒グラフで表示します。
-   `List` を使って、各フォーカスセッションの開始時刻と長さをテキストで表示します。

#### `dayFocusSessions` プロパティ

-   `ViewModel` が持つ完了済みタスクのリスト (`vm.tasks`) をフィルタリングし、選択された日付 (`date`) に完了したタスクを元に、`FocusSession` の配列を生成します。
-   ここでは、1つの完了タスクを「25分のフォーカスセッション」と見なしてデータを生成しています。

---

### 3. `MonthYearPickerView`

年月をホイール形式で選択するための専用ビューです。

#### `body`の中身

-   `HStack` の中に2つの `Picker` を配置しています。
    -   1つは年（2020〜2030年）を選択するためのピッカー。
    -   もう1つは月（1〜12月）を選択するためのピッカー。
-   「完了」ボタンが押されると、`onDone` クロージャが実行され、`StatisticsView` の `selectedMonth` が更新されます。

---

### 4. `FocusSession` 構造体

-   `Identifiable` に準拠したシンプルなデータ構造体です。
-   `id`: 各セッションの一意なID。
-   `date`: セッションの開始日時。
-   `minutes`: セッションの長さ（分）。
-   `DayDetailView` のチャート表示とリスト表示のために使われます。

## 使い方

`HomeView` の「Stats」リンクから遷移して表示されます。ユーザーが自身の学習パターンや継続状況を視覚的に確認し、モチベーションを高めるための機能を提供します。
