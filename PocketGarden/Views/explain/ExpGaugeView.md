
# ExpGaugeView.swift 解説

このファイルは、ユーザーの経験値（EXP）とレベルを視覚的に表示する円形のゲージビューを定義しています。レベルアップ時には、アニメーションやエフェクトを伴う華やかな演出が実行されます。

## 構成要素

このファイルは `ExpGaugeView` という単一のSwiftUIビューで構成されています。また、エフェクトを管理するための内部的なデータ構造（`RingEffect`, `SparkleEffect`）も定義されています。

---

### `ExpGaugeView`

経験値ゲージの表示とアニメーションを管理するメインビューです。

#### プロパティ

-   **外部から渡される値**:
    -   `let currentExp: Int`: 現在の総経験値。
    -   `let currentLevel: Int`: 現在のレベル。
    -   `let maxExp: Int`: 次のレベルに到達するために必要な総経験値。

-   **状態変数 (`@State`)**:
    -   `animatedProgress: Double`: ゲージの進行度をアニメーションさせるための変数（0.0〜1.0）。
    -   `showLevelUp: Bool`: レベルアップ演出を表示するかどうかのフラグ（現在は直接使われていないが、関連ロジックの名残）。
    -   `pulsing: Bool`: パルス（脈動）アニメーション用のフラグ。
    -   `expGain: Bool`: EXPが増加した瞬間のアニメーションをトリガーするフラグ。
    -   `gainAmount: Int`: 増加したEXPの量を一時的に保持し、「+X EXP」のように表示するために使用。
    -   `previousExp`, `previousLevel`: EXPやレベルが変化したことを検知するために、以前の値を保持。

-   **エフェクト用の状態変数**:
    -   `levelUpScale: CGFloat`: 「LEVEL UP!」テキストの拡大・縮小アニメーション用。
    -   `levelUpRings: [RingEffect]`: 拡散するリングエフェクトのデータを保持する配列。
    -   `showLevelUpText: Bool`: 「LEVEL UP!」テキストの表示フラグ。
    -   `levelUpSparkles: [SparkleEffect]`: キラキラエフェクトのデータを保持する配列。

-   `@EnvironmentObject private var vm: GardenViewModel`: `GardenViewModel` にアクセスするために使用（現在は直接利用されていないが、将来的な拡張のため）。

#### 計算プロパティ (Computed Properties)

-   `progressInCurrentLevel: Double`:
    -   現在のレベル内でのEXPの進行度を0.0から1.0の間の値で計算します。
    -   例えば、Lv1 (EXP 10で到達) から Lv2 (EXP 20で到達) の間で、現在のEXPが15の場合、進行度は (15-10) / (20-10) = 0.5 (50%) となります。
-   `expToNextLevel: Int`:
    -   次のレベルアップまでに必要な残りのEXPを計算します。
-   `displayLevel: Int`:
    -   内部的なレベル (`currentLevel`、0から始まる) を、ユーザーに見せるための表示用レベル（1から始まる）に変換します。

#### `body`の中身

-   `ZStack`:
    -   複数のビューを重ねて表示するためのコンテナ。ゲージ、テキスト、エフェクトをすべて重ね合わせます。

-   **ゲージの円**:
    -   `Circle().stroke(...)`: 背景の薄い灰色の円（ゲージの土台）。
    -   `Circle().trim(...)`: `animatedProgress` の値に応じて、ゲージの進行度（緑色の円弧）を描画します。`.trim` 修飾子で円の一部だけを描いています。

-   **中央のテキスト**:
    -   `VStack`: 「Lv」、レベル番号、次のレベルまでのポイント数を垂直に表示します。

-   **レベルアップエフェクト**:
    -   `ForEach(levelUpRings)`: `levelUpRings` 配列内のデータに基づいて、拡散するリングを複数描画します。
    -   `ForEach(levelUpSparkles)`: `levelUpSparkles` 配列内のデータに基づいて、キラキラエフェクトを複数描画します。
    -   `if showLevelUpText`: `showLevelUpText` が `true` の場合に、「LEVEL UP!」というテキストをアニメーション付きで表示します。

-   **オーバーレイ (Overlay)**:
    -   `.overlay(...)`: EXPが増加したときに「+X EXP」というテキストをビューの上（Y座標が-100の位置）に表示します。

#### `onAppear` と `onChange`

-   `.onAppear`:
    -   ビューが最初に表示されたときに一度だけ実行されます。
    -   `animatedProgress` を現在の進行度に設定し、初期表示時のアニメーションを開始します。

-   `.onChange(of: currentExp)`:
    -   `currentExp` の値が変化するたびに実行されます。
    -   EXPが増加した場合 (`expDelta > 0`)、`gainAmount` を設定し、`expGain` を `true` にしてパルスアニメーションと「+X EXP」表示をトリガーします。
    -   その後、ゲージのプログレスを新しい値までアニメーションさせます。

-   `.onChange(of: currentLevel)`:
    -   `currentLevel` の値が変化するたびに実行されます。
    -   新しいレベルが古いレベルより大きい場合、レベルアップしたと判断し、`triggerLevelUpEffect()` メソッドを呼び出します。

#### エフェクト関連のメソッド

-   `triggerLevelUpEffect()`:
    -   レベルアップ演出を開始するメソッドです。
    -   テキストの表示、リングの生成、キラキラの生成を適切なタイミングで実行し、一定時間後にすべてを非表示にしてクリーンアップします。

-   `createExpandingRing()`:
    -   拡散するリングを1つ生成し、`levelUpRings` 配列に追加します。リングは時間ととも徐々に大きく、そして透明になって消えていきます。

-   `createSparkles()`:
    -   円周上に複数のキラキラエフェクトを生成し、`levelUpSparkles` 配列に追加します。各キラキラも時間とともにアニメーションして消えます。

## 使い方

このビューは `HomeView` の中で、現在のカテゴリに対応する庭の経験値とレベルを渡して使用されます。ユーザーの進捗を視覚的にフィードバックする、アプリのモチベーション維持に重要な役割を担うコンポーネントです。
