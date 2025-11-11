# Pocket Garden コードリーディングガイドブック

## 1. はじめに

このドキュメントは、SwiftUIで構築されたiOSアプリケーション「Pocket Garden」のソースコードを理解するための一助となることを目的としています。

`Pocket Garden`は、ポモドーロテクニック（25分集中＋5分休憩）とタスク管理を組み合わせ、学習の習慣化をサポートするアプリです。ユーザーはタスクをこなし、集中タイマーを利用することで経験値（EXP）を獲得し、アプリ内の庭を育てることができます。

このガイドでは、プロジェクトの全体像、アーキテクチャ、主要な機能の実装方法、そしてデータフローについて詳細に解説します。

## 2. アーキテクチャ概要

このアプリケーションは、Appleが推奨するモダンなUIフレームワークである **SwiftUI** を全面的に採用しており、アーキテクチャとしては **MVVM (Model-View-ViewModel)** に近い設計思想で構築されています。

-   **Model**: アプリケーションのデータ構造を定義します。
    -   `Task.swift`: `Task`（タスク情報）と`GardenState`（庭の状態、経験値、レベル）の構造体を定義。これらは`Codable`に準拠しており、永続化のためにJSONへのエンコード/デコードが可能です。
-   **View**: ユーザーインターフェースの構造、レイアウト、外観を定義します。
    -   `Views/`ディレクトリ内の全ての`*.swift`ファイルが該当します。
    -   SwiftUIの宣言的な構文で記述されており、状態に応じてUIが自動的に更新されます。
    -   責務に応じて細かくコンポーネント化されており、再利用性と可読性が高められています。（例: `ExpGaugeView`, `TaskListView`）
-   **ViewModel**: Viewのための状態とロジックを管理します。
    -   `GardenViewModel.swift`: アプリケーション全体のコアとなるViewModel。タスクのCRUD（作成、読み取り、更新、削除）、庭の成長ロジック、データの永続化（保存・読み込み）など、ほとんどのビジネスロジックを担います。`@Published`プロパティラッパーを通じて、UIに変更を通知します。
    -   `FocusTimerManager.swift`: フォーカスタイマー機能に特化したViewModel。タイマーの状態（集中、休憩、停止）、残り時間、セッション数などを管理し、UI（`FocusView`）に状態を提供します。

**特徴**:

-   **単一の`ObservableObject`**: `GardenViewModel`がアプリケーション全体の主要な状態を管理する「Single Source of Truth（信頼できる唯一の情報源）」として機能しています。
-   **責務の分離**: `FocusTimerManager`のように、特定の機能に関するロジックを別のクラスに分離することで、`GardenViewModel`が過度に肥大化することを防いでいます。
-   **プレビューとテスト**: SwiftUIのプレビュー機能や、`XCTest`によるユニットテストが記述されており、開発効率とコード品質を向上させています。

## 3. 主要なデータフロー

アプリケーションの動作を理解するために、いくつかの主要なシナリオにおけるデータの流れを追ってみましょう。

### シナリオ1: アプリ起動とデータ表示

1.  **`PocketGardenApp.swift`**: アプリが起動すると、`@main`でマークされた`PocketGardenApp`がインスタンス化されます。
2.  **`@StateObject`**: `gardenVM`（`GardenViewModel`のインスタンス）が`@StateObject`として生成され、アプリのライフサイクルを通じて生存します。
3.  **`HomeView`**: アプリのメインビューである`HomeView`が表示されます。
4.  **`.environmentObject(gardenVM)`**: `gardenVM`が`HomeView`とその全ての子ビューに`EnvironmentObject`として注入（DI）され、どのビューからでも`@EnvironmentObject`を通じてアクセスできるようになります。
5.  **`.onAppear { gardenVM.load() }`**: `HomeView`が表示される直前に、`gardenVM.load()`メソッドが呼び出されます。
6.  **`GardenViewModel.load()`**: `UserDefaults`に保存されているJSONデータをデコードし、`tasks`と`gardens`プロパティを復元します。
7.  **UIの更新**: `@Published`でマークされた`tasks`と`gardens`が更新されると、これらのデータを監視している`HomeView`や`TaskListView`などのUIが自動的に再描画され、最新のデータが画面に表示されます。

### シナリオ2: タスク完了と経験値獲得

1.  **`TaskListView.swift`**: ユーザーがタスク行のチェックマークをタップします。
2.  **`TaskRowView.handleTaskCompletion()`**: タスク完了のアニメーションシーケンスを開始します。
    -   `expandingTasks`と`completingTasks`という`@State`変数を操作して、拡大・縮小・フェードアウトといった一連のアニメーションを`DispatchQueue.main.asyncAfter`を駆使して実現しています。
3.  **`onToggle()`クロージャの実行**: アニメーションの最後に、`vm.toggleDone(task: task)`を呼び出すクロージャが実行されます。
4.  **`GardenViewModel.toggleDone(task:)`**:
    -   指定されたタスクの`isDone`プロパティを`true`に切り替えます。
    -   `completeTask(category:)`メソッドを呼び出します。
5.  **`GardenViewModel.completeTask(category:)`**:
    -   対応するカテゴリの庭の`addExp()`メソッドを呼び出します。
6.  **`GardenState.addExp()`**:
    -   `exp`（経験値）を加算し、`level`を再計算します (`level = exp / 10`)。
7.  **`GardenViewModel.save()`**: 変更された`tasks`と`gardens`の状態を`UserDefaults`に保存します。
8.  **UIの更新**: `tasks`と`gardens`の変更が`@Published`を通じて`HomeView`や`ExpGaugeView`に通知され、タスクリストから完了したタスクが消え、経験値ゲージがアニメーション付きで更新されます。

### シナリオ3: フォーカスタイマーの利用

1.  **`HomeView.swift`**: ユーザーが「Start Focus」ボタンをタップします。
2.  **`goFocus`の更新**: `@State`変数`goFocus`が`true`になり、`NavigationStack`が`FocusView`に遷移します。
3.  **`FocusView.swift`**:
    -   `FocusView`が表示されると、`.onAppear`で`focusTimer.startFocus()`が呼び出されます。
    -   同時に、`focusTimer.onFocusComplete`コールバックが設定されます。このコールバックは、集中セッションが完了したときに`vm.completeTask(category:)`を呼び出すように設定されています。
4.  **`FocusTimerManager.startFocus()`**:
    -   `focusPhase`を`.focus`に設定し、`remainingSeconds`を25分（1500秒）に初期化します。
    -   `Timer.scheduledTimer`を使って、1秒ごとに`tick()`メソッドを呼び出すタイマーを開始します。
5.  **`FocusTimerManager.tick()`**: `remainingSeconds`を1ずつ減らします。残り時間が0になると`endPhase()`を呼び出します。
6.  **`FocusTimerManager.endPhase()`**:
    -   現在のフェーズが`.focus`の場合、`onFocusComplete`コールバックを実行します。これにより`GardenViewModel`の`completeTask`が呼ばれ、経験値が加算されます。
    -   次に`focusPhase`を`.rest`（休憩）に切り替え、残り時間を5分に設定してタイマーを再開します。
7.  **UIの更新**: `focusTimer`の`@Published`プロパティ（`remainingSeconds`, `focusPhase`など）が更新されるたびに、`FocusView`内の`CircleTimer`が再描画され、カウントダウンが進みます。

## 4. ファイル構造と各ファイルの役割

`README.md`にも記載がありますが、ここではより詳細に各ファイルの役割を解説します。

```
PocketGarden/
├── PocketGardenApp.swift           // 1. アプリエントリーポイント
├── Models/                         // 2. データモデル & ビジネスロジック
│   ├── Task.swift
│   ├── GardenViewModel.swift
│   └── FocusTimerManager.swift
├── Views/                          // 3. UIコンポーネント
│   ├── HomeView.swift
│   ├── TaskListView.swift
│   ├── FocusView.swift
│   ├── ExpGaugeView.swift
│   ├── StatisticsView.swift
│   └── ... (その他のUIコンポーネント)
├── Resources/                      // 4. アセット・リソース
│   └── Assets.xcassets/
├── Tests/                          // 5. テストファイル
│   ├── PocketGardenTests.swift
│   └── PocketGardenUITests.swift
└── ... (プロジェクトファイルなど)
```

1.  **`PocketGardenApp.swift`**: アプリケーションの起動点。`GardenViewModel`を生成し、`HomeView`に`EnvironmentObject`として提供する重要な役割を担います。また、`scenePhase`を監視してアプリがバックグラウンドに移行した際にデータを保存するなど、アプリ全体のライフサイクルイベントを処理します。

2.  **`Models/`**:
    -   **`Task.swift`**: `Task`と`GardenState`という、このアプリで最も基本的なデータ構造を定義しています。全てのデータ操作の基礎となります。
    -   **`GardenViewModel.swift`**: アプリの頭脳。タスクリスト(`tasks`)と庭の状態(`gardens`)を保持し、それらを変更するためのメソッド（`addTask`, `toggleDone`, `save`, `load`など）を提供します。UIからのイベントを受け取り、Modelを更新し、その結果をUIに反映させるハブとしての役割を果たします。
    -   **`FocusTimerManager.swift`**: タイマーという特定の機能に関する状態とロジックをカプセル化しています。これにより、`GardenViewModel`の責務を軽減し、コードの見通しを良くしています。

3.  **`Views/`**:
    -   **`HomeView.swift`**: メイン画面。`ExpGaugeView`, `TaskListView`, `ActionButtonsView`といった複数のコンポーネントを組み合わせて構成されています。画面遷移（`NavigationStack`）やシート表示（`.sheet`）のロジックもここにあります。
    -   **`TaskListView.swift`**: 未完了タスクのリスト表示に特化したView。スワイプアクションや、`TaskRowView`と連携した複雑な完了アニメーションを管理します。
    -   **`FocusView.swift`**: `FocusTimerManager`の状態を監視し、円形のプログレスバーや残り時間を表示する集中モード専用の画面です。
    -   **`ExpGaugeView.swift`**: 経験値とレベルを視覚的に表現するコンポーネント。`currentExp`と`currentLevel`を受け取り、円形ゲージやレベルアップ時の複雑なアニメーション（`RingEffect`, `SparkleEffect`）を描画します。
    -   **`StatisticsView.swift`**: `Swift Charts`フレームワークを利用して、日々の学習時間をヒートマップ形式で可視化します。
    -   **その他のView**: `ActionButtonsView`, `CompletedTasksView`など、特定のUIパーツを再利用可能なコンポーネントとして切り出しています。

4.  **`Resources/`**: `Assets.xcassets`には、アプリアイコンや、ライトモード/ダークモードで色が変わるカスタムカラー（`LeafPrimary`, `LeafSecondary`）が定義されています。

5.  **`Tests/`**:
    -   **`PocketGardenTests.swift`**: `GardenState`のレベルアップロジックや、`GardenViewModel`のタスク完了時の経験値加算など、コアなビジネスロジックを検証するユニットテストが含まれています。
    -   **`PocketGardenUITests.swift`**: UIテストのファイル。

## 5. コア機能の実装詳細

### 永続化戦略

-   **方法**: `UserDefaults`と`JSONEncoder`/`JSONDecoder`を組み合わせています。
-   **実装**:
    1.  `GardenViewModel`内に、永続化対象のデータ（`tasks`, `gardens`）をまとめるためのプライベートな構造体`BundleData`が定義されています。
    2.  `save()`メソッドでは、`BundleData`のインスタンスを`JSONEncoder`で`Data`型にエンコードし、`UserDefaults.standard.set()`で保存します。
    3.  `load()`メソッドでは、`UserDefaults`から`Data`型でデータを取り出し、`JSONDecoder`で`BundleData`にデコードしてプロパティを復元します。
-   **タイミング**: アプリ起動時(`onAppear`)、バックグラウンド移行時(`onChange(of: scenePhase)`)、アプリ終了時(`onReceive(willTerminateNotification)`)に読み書きが行われ、データの損失を防いでいます。

### 経験値ゲージとレベルアップアニメーション (`ExpGaugeView.swift`)

このViewは、SwiftUIの強力なアニメーション機能を駆使した良い例です。

-   **プログレスゲージ**: `Circle`の`.trim(from:to:)`モディファイアを使い、`animatedProgress`という`@State`変数の値に応じて円弧の長さを変えています。`currentExp`が変更されると、`.onChange(of: currentExp)`内で`withAnimation`ブロックが実行され、ゲージが滑らかに変化します。
-   **レベルアップエフェクト**: `currentLevel`の変更を検知すると`triggerLevelUpEffect()`が呼ばれます。
    -   **拡散リング**: `levelUpRings`という`@State`配列に`RingEffect`を追加し、`.onAppear`やタイマーで`scale`と`opacity`をアニメーションさせて、波紋が広がるようなエフェクトを実現しています。
    -   **キラキラ**: `levelUpSparkles`配列と`SparkleEffect`を使い、円周上に`Image(systemName: "sparkle")`を配置し、同様にアニメーションさせています。
    -   **テキスト**: "LEVEL UP!"というテキストを`.transition`と`.scaleEffect`でアニメーション表示しています。

### 非同期処理とUI更新

-   **`DispatchQueue.main.asyncAfter`**: `TaskRowView`の完了アニメーションや`ExpGaugeView`のレベルアップエフェクトなど、複数のアニメーションを特定の遅延をもって順番に実行するために多用されています。これにより、リッチなユーザー体験を生み出しています。
-   **`@MainActor`**: `GardenViewModel`やテストクラスに`@MainActor`が付与されています。これにより、UI関連のプロパティ（`@Published`がついたものなど）へのアクセスが常にメインスレッドで行われることが保証され、UI更新に起因するランタイムエラーを防いでいます。

## 6. コードリーディングの進め方（推奨）

このプロジェクトを効率的に理解するために、以下のアプローチをお勧めします。

1.  **データ構造から (ボトムアップ)**
    -   最初に`Models/Task.swift`を読み、`Task`と`GardenState`がどのようなプロパティを持っているかを把握します。
    -   次に`Models/GardenViewModel.swift`を読み、これらのデータがどのように操作されるか（追加、更新、保存など）を理解します。
    -   最後に`Views/`ディレクトリ内の各Viewが、ViewModelのどのデータをどのように表示しているかを確認していきます。

2.  **UIから (トップダウン)**
    -   `PocketGardenApp.swift`から始め、エントリーポイントの処理を理解します。
    -   次に`Views/HomeView.swift`を読み、メイン画面がどのようなコンポーネントで構成されているかを確認します。
    -   興味のあるUIコンポーネント（例: `ExpGaugeView`）を見つけたら、そのファイルを開き、どの`@State`や`@Binding`、`@EnvironmentObject`のプロパティを使ってUIを構築しているかを分析します。

3.  **機能単位で**
    -   「フォーカスタイマーの仕組みが知りたい」と思ったら、`Views/FocusView.swift`と`Models/FocusTimerManager.swift`をセットで読みます。
    -   「統計表示の仕組みが知りたい」と思ったら、`Views/StatisticsView.swift`と、そこで使われている`GardenViewModel.aggregatedStudyMinutes()`をセットで読みます。

## 7. まとめ

`Pocket Garden`は、SwiftUIの基本的な概念から、高度なアニメーション、状態管理、責務の分離といった実践的なテクニックまで、多くのことを学べる素晴らしい教材です。特に、単一のViewModelと複数のViewコンポーネントが連携する様子や、ユーザーのアクションに応じて状態が変化し、UIが滑らかに追従していく様は、現代的なiOSアプリ開発の良い手本となります。

このガイドが、あなたのコードリーディングの一助となれば幸いです。
