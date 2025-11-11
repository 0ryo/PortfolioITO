
# CompletedTasksView.swift 解説

このファイルは、ユーザーが過去に達成したタスクを日付ごとに閲覧できる画面を定義しています。ユーザーは特定の日付に完了したタスクの一覧を確認できます。

## 構成要素

このビューは `CompletedTasksView` という単一のSwiftUIビューで構成されています。

---

### `CompletedTasksView`

達成済みタスクを表示するためのメインビューです。

#### プロパティ

-   `@EnvironmentObject private var vm: GardenViewModel`:
    -   アプリ全体のデータ（特にタスクのリスト）にアクセスするために、`GardenViewModel` を環境オブジェクトとして受け取ります。
-   `@State private var showingDatePicker: Bool = false`:
    -   日付選択ピッカー（カレンダー）を表示するかどうかを管理するための状態変数です。`true` になると、画面下からシートとしてカレンダーが表示されます。
-   `@State private var selectedDate: Date = Date()`:
    -   ユーザーが選択している日付を保持するための状態変数です。初期値は現在の日付 (`Date()`) です。この日付に基づいて、表示するタスクがフィルタリングされます。

#### `body`の中身

-   `List`:
    -   画面全体をリスト形式で構成します。リストの中には複数の `Section` が含まれます。

-   **日付選択セクション**:
    -   `Section { HStack { ... } }`:
        -   日付を操作するためのUIを水平に（`H`orizontal）配置します。
    -   **前日へボタン**:
        -   `Button { ... } label: { Image(systemName: "chevron.left") }`:
            -   タップすると `selectedDate` を1日前の日付に更新します。
            -   `withAnimation(.easeInOut(duration: 0.3))` で、日付の切り替え時に滑らかなアニメーション効果を加えています。
    -   **日付表示ボタン**:
        -   `Button { showingDatePicker.toggle() } label: { Text(...) }`:
            -   中央に現在選択されている日付（例：「2023年10月27日」）を表示します。
            -   タップすると `showingDatePicker` の値が切り替わり（`toggle()`）、日付選択ピッカーが表示または非表示になります。
    -   **翌日へボタン**:
        -   前日ボタンと同様に、タップすると `selectedDate` を1日後の日付に更新します。

-   **タスク表示セクション**:
    -   `if completedTasks.isEmpty { ... } else { ... }`:
        -   `completedTasks`（計算プロパティ、後述）が空かどうかで表示を切り替えます。
    -   **タスクがない場合**:
        -   `Text("この日に達成したタスクはありません 😌")`: タスクがない旨のメッセージを表示します。
    -   **タスクがある場合**:
        -   `Section("達成したタスク") { ForEach(completedTasks) { task in ... } }`:
            -   `completedTasks` 配列内の各タスクについて、繰り返し表示（`ForEach`）します。
            -   `HStack` を使って、各タスクの情報を横並びに表示します。
                -   `Image(systemName: "checkmark.circle.fill")`: 完了を示すチェックマークアイコン。
                -   `VStack`: タスクのタイトルとカテゴリを縦に並べて表示。
                -   `Spacer()`: 要素間にスペースを空けて右寄せを実現します。
                -   `Text(timeFormatter.string(from: task.createdAt))`: タスクが完了した時刻（例：「14:30」）を表示します。

-   `.id(selectedDate)`:
    -   `List` にユニークなIDとして `selectedDate` を設定しています。これにより、日付が変更されたときにSwiftUIが `List` 全体を新しいビューとして再描画するため、日付の切り替えが確実かつスムーズに行われます。

-   `.navigationTitle("達成したタスク")`:
    -   画面上部のナビゲーションバーに表示されるタイトルを設定します。

-   `.sheet(isPresented: $showingDatePicker) { ... }`:
    -   `showingDatePicker` が `true` になったときに、画面下からシートモーダルを表示します。
    -   **シートの中身**:
        -   `DatePicker`: グラフィカルなカレンダーUIを表示し、ユーザーが日付を選択できるようにします。
        -   `selection: $selectedDate`: ピッカーでの選択が `selectedDate` プロパティに直接反映されます。
        -   「キャンセル」と「完了」ボタンでシートを閉じることができます。

#### 計算プロパティ (Computed Properties)

-   `private var completedTasks: [Task]`:
    -   このビューの核心部分です。表示すべき達成済みタスクを計算して返します。
    -   `vm.tasks.filter { task in ... }`:
        -   `GardenViewModel` が持つすべてのタスク (`vm.tasks`) から、以下の2つの条件を満たすものだけを絞り込みます。
            1.  `task.isDone`: タスクが完了済みである。
            2.  `calendar.isDate(task.createdAt, inSameDayAs: selectedDate)`: タスクの作成日 (`createdAt`) が、ユーザーが選択した日付 (`selectedDate`) と同じ日である。
    -   この結果、`selectedDate` に達成されたタスクの配列が動的に生成されます。

-   `private var dateFormatter: DateFormatter`:
    -   日付を「yyyy年M月d日」形式の日本語文字列に変換するためのフォーマッターです。

-   `private var timeFormatter: DateFormatter`:
    -   時刻を「HH:mm」形式の文字列に変換するためのフォーマッターです。

## 使い方

このビューは `HomeView` の `ActionButtonsView` にある「達成したタスク」リンクから遷移して表示されます。ユーザーが自分の達成記録を振り返るための重要な画面です。
