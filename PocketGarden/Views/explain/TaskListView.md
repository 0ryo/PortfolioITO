
# TaskListView.swift 解説

このファイルは、ユーザーが作成したタスクをリスト形式で表示し、操作（完了、削除）するためのUIを定義しています。タスク完了時には、ユーザー体験を向上させるためのリッチなアニメーションが実行されます。

## 構成要素

このファイルは2つの主要なSwiftUIビューで構成されています。

1.  `TaskListView`: タスクのリスト全体を管理するビュー。
2.  `TaskRowView`: リスト内の各タスク一行分を表示・操作するビュー。

---

### 1. `TaskListView`

未完了のタスクをリスト表示するメインのコンポーネントです。

#### プロパティ

-   `@EnvironmentObject private var vm: GardenViewModel`:
    -   `ViewModel` からタスクのデータを取得したり、タスクの完了・削除といった操作を依頼したりするために使用します。
-   `@Binding var completingTasks: Set<UUID>`:
    -   親ビュー（`HomeView`）から渡される、完了アニメーション中のタスクIDを保持する集合。`TaskRowView` にそのまま渡されます。
-   `@Binding var expandingTasks: Set<UUID>`:
    -   同様に、拡大アニメーション中のタスクIDを保持する集合。
-   `@Binding var showCompletionEffect: Bool`:
    -   同様に、中央に表示されるチェックマークエフェクトの表示フラグ。

#### `body`の中身

-   `List`:
    -   タスクをリスト形式で表示します。
    -   `ForEach(uncompletedTasks) { task in ... }`:
        -   `uncompletedTasks`（計算プロパティ、後述）の各タスクに対して `TaskRowView` を生成します。
    -   `.onDelete(perform: deleteTask)`:
        -   リストの行を左にスワイプして「削除」ボタンを押したときのアクションを定義します。`deleteTask` メソッドが呼ばれます。

-   `.swipeActions(...)`:
    -   リスト全体に対するスワイプアクションを定義します。これは、リストの何もない領域をスワイプしたときに機能します。
        -   `.edge(.trailing)`: 右からのスワイプ（左方向へスワイプ）で「削除」アクション。リストの最初のタスクを削除します。
        -   `.edge(.leading)`: 左からのスワイプ（右方向へスワイプ）で「達成」アクション。リストの最初のタスクを完了します。

-   `.animation(.spring(...), value: vm.tasks)`:
    -   `vm.tasks` 配列が変更（追加や削除）されたときに、リスト全体にバネのようなアニメーションを適用します。これにより、タスクの追加・削除が滑らかに見えます。

#### 計算プロパティ

-   `private var uncompletedTasks: [Task]`:
    -   `ViewModel` が持つ全タスク (`vm.tasks`) から、現在のカテゴリに属し (`$0.category == vm.currentCategory`)、かつ未完了 (`!$0.isDone`) のタスクだけをフィルタリングして返します。このビューには未完了のタスクしか表示されません。

#### メソッド

-   `deleteTask(at offsets: IndexSet)`:
    -   `onDelete` 修飾子から呼び出され、指定されたインデックスのタスクを `ViewModel` に依頼して削除します。
-   `deleteFirstTask()` / `completeFirstTask()`:
    -   リスト全体のスワイプアクションから呼び出され、リストの先頭にあるタスクを削除または完了します。

---

### 2. `TaskRowView`

タスクリストの一行分の表示と、そのタスクに対する操作（特に完了アニメーション）を担当します。

#### プロパティ

-   `let task: Task`: 表示するタスクのデータ。
-   `@Binding` プロパティ群: `TaskListView` から渡されたアニメーション制御用の状態変数。
-   `let onToggle: () -> Void`: タスクの完了状態を切り替える処理（クロージャ）。`ViewModel` の `toggleDone` メソッドが渡されます。

#### `body`の中身

-   `HStack`:
    -   円形のチェックボックスとタスクのタイトルを水平に並べます。
    -   `Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")`:
        -   タスクの完了状態 (`isDone`) に応じて、アイコンを「チェックマーク付きの円」と「ただの円」で切り替えます。
        -   `.onTapGesture { handleTaskCompletion() }`: このアイコンをタップすると、`handleTaskCompletion` メソッドが呼ばれ、完了アニメーションが開始されます。
    -   `Text(task.title)`: タスクのタイトルを表示します。

-   **アニメーション関連の修飾子**:
    -   `.opacity(...)`: `completingTasks` に自身のIDが含まれている間、ビューを透明にします（フェードアウト）。
    -   `.scaleEffect(taskScale)`: `taskScale`（計算プロパティ）の値に応じて、ビューを拡大・縮小します。
    -   `.transition(...)`: タスクがリストから削除されるときのアニメーション（右にスライドアウト）を定義します。

#### 計算プロパティ

-   `private var taskScale: CGFloat`:
    -   タスクの状態に応じて、適用すべき拡大率を返します。
        -   拡大中 (`expandingTasks` にIDがある) なら `1.1`。
        -   完了処理中 (`completingTasks` にIDがある) なら `0.0` (完全に縮小)。
        -   通常時は `1.0`。

#### `handleTaskCompletion` メソッド

このビューで最も複雑かつ重要な部分で、タスク完了時のアニメーションを順序立てて実行します。

1.  `showCompletionEffect = true`: `HomeView` にある中央のチェックマークエフェクトを表示させます。

2.  **ステップ1: 拡大 (0.0秒後)**
    -   `withAnimation(.spring(...)) { expandingTasks.insert(task.id) }`:
    -   `expandingTasks` に自身のIDを追加し、`taskScale` を `1.1` にして、自分自身を「ポンッ」と拡大させます。

3.  **ステップ2: 縮小＆フェードアウト (0.2秒後)**
    -   `DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { ... }`:
    -   0.2秒待ってから実行します。
    -   `expandingTasks` からIDを削除し、`completingTasks` にIDを追加します。これにより、`taskScale` が `0.0` に、`opacity` が `0.0` にアニメーションし、タスク行が縮小しながら消えていきます。

4.  **ステップ3: 実際のデータ更新 (0.6秒後)**
    -   `DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { ... }`:
    -   アニメーションが終わるのを待ってから、`onToggle()`（`vm.toggleDone`）を呼び出し、`ViewModel` 内の実際のタスクデータを更新します。
    -   その後、`completingTasks` からIDを削除して、状態をクリーンアップします。

5.  **エフェクト非表示 (1.0秒後)**
    -   `showCompletionEffect = false`: 中央のエフェクトを非表示にします。
