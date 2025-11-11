
# ActionButtonsView.swift 解説

このファイルは、PocketGardenアプリのホーム画面に表示される主要なアクションボタンを定義しています。具体的には、「集中を開始」ボタンと「達成したタスク一覧へ」のナビゲーションリンクです。

## 構成要素

このファイルは2つのSwiftUIビューで構成されています。

1.  `ActionButtonsView`
2.  `CompleteAllTasksButton`

---

### 1. `ActionButtonsView`

メインとなるビューで、2つの主要なボタンを垂直に配置します。

#### プロパティ

-   `@EnvironmentObject private var vm: GardenViewModel`:
    -   アプリ全体のデータとロジックを管理する `GardenViewModel` を環境オブジェクトとして受け取ります。これにより、タスクデータや庭の状態にアクセスできます。
-   `@Binding var goFocus: Bool`:
    -   親ビュー（`HomeView`）から渡される真偽値（`Bool`）です。この値が `true` になると、集中タイマー画面（`FocusView`）への画面遷移がトリガーされます。`@Binding` を使うことで、このビュー内での変更が親ビューにも反映されます。

#### bodyの中身

-   `VStack(spacing: 16)`:
    -   2つのボタンを垂直に（`V`ertical）並べるためのコンテナです。`spacing: 16` はボタン間の間隔を16ポイントに設定します。

-   **集中を開始ボタン (Start Focus Button)**:
    -   `Button { goFocus = true } label: { ... }`:
        -   このボタンをタップすると、`goFocus` が `true` に設定されます。これにより、`HomeView` の `navigationDestination` が作動し、`FocusView` が表示されます。
    -   `Label("Start Focus", systemImage: "timer")`:
        -   ボタンの見た目を定義します。「Start Focus」というテキストと、タイマーのアイコン（`timer`）を組み合わせたラベルです。
    -   `.font(.headline)`: テキストのフォントを少し大きめの見出しスタイルに設定します。
    -   `.padding()`: ラベルの周囲に余白を追加します。
    -   `.frame(maxWidth: .infinity)`: ボタンの幅を画面の横幅いっぱいに広げます。
    -   `.background(.green.opacity(0.2), in: .capsule)`:
        -   背景を半透明の緑色（`green.opacity(0.2)`）で塗りつぶします。
        -   `in: .capsule` は、背景の形をカプセル形状（角が丸い長方形）にすることを指定します。
    -   `.buttonStyle(.plain)`: ボタンがタップされたときに背景が暗くなるなどのデフォルトのスタイルを無効にし、シンプルな見た目を保ちます。

-   **達成したタスクへのナビゲーション (Completed Tasks Navigation)**:
    -   `NavigationLink { CompletedTasksView() } label: { ... }`:
        -   `NavigationLink` は、タップすると別のビューに遷移するためのコンポーネントです。
        -   `destination`（波括弧の中）には、遷移先のビューである `CompletedTasksView()` を指定します。
        -   `label` には、リンクの見た目を定義します。
    -   `Label("達成したタスク", systemImage: "checkmark.seal.fill")`:
        -   「達成したタスク」というテキストと、チェックマークのアイコンを表示します。
    -   その他の修飾子（`.font`, `.padding`, `.frame`, `.background`, `.buttonStyle`）は、集中ボタンと同様の目的で使われています。

---

### 2. `CompleteAllTasksButton`

現在選択されているカテゴリの未完了タスクをすべて一括で完了するためのボタンです。

#### プロパティ

-   `@EnvironmentObject private var vm: GardenViewModel`:
    -   `ActionButtonsView` と同様に、`GardenViewModel` にアクセスするために使用します。

#### bodyの中身

-   `Button { ... } label: { ... }`:
    -   ボタンがタップされたときのアクションを定義します。
    -   **アクション**:
        1.  `let tasks = vm.tasks.filter { $0.category == vm.currentCategory && !$0.isDone }`:
            -   `vm.tasks`（すべてのタスクの配列）から、現在のカテゴリに属し（`$0.category == vm.currentCategory`）、かつ未完了（`!$0.isDone`）のタスクだけを絞り込みます。
        2.  `for task in tasks { vm.toggleDone(task: task) }`:
            -   絞り込んだタスクを一つずつループ処理し、`vm.toggleDone(task:)` メソッドを呼び出して完了状態に切り替えます。
    -   **ラベル**:
        -   `Label("全てのタスクを達成", systemImage: "checkmark.circle.fill")`: ボタンの見た目を定義します。
        -   `.font(.caption)`: テキストを少し小さめのキャプションスタイルに設定します。

-   `.disabled(vm.tasks.filter { ... }.isEmpty)`:
    -   ボタンを有効にするか無効にするかを決める重要な修飾子です。
    -   `vm.tasks.filter { ... }.isEmpty` は、未完了のタスクが **ない** 場合に `true` を返します。
    -   したがって、完了すべきタスクが1つもない場合は、このボタンは自動的に無効化（灰色表示）され、タップできなくなります。

## 使い方

-   `ActionButtonsView` は `HomeView` の中で使われ、画面下部に配置されます。
-   `CompleteAllTasksButton` は `HomeView` のツールバー（下部）に配置され、タスクを一括で完了する便利な機能を提供します。
