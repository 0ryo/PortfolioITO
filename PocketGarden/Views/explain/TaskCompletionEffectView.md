
# TaskCompletionEffectView.swift 解説

このファイルは、ユーザーがタスクを完了した瞬間に表示される、シンプルで気持ちの良いアニメーションエフェクトを定義しています。具体的には、チェックマークアイコンが拡大・回転しながら表示され、その後消えていくという演出です。

## 構成要素

このファイルは `TaskCompletionEffectView` という単一のSwiftUIビューで構成されています。

---

### `TaskCompletionEffectView`

タスク完了時の視覚的なフィードバックを提供するビューです。

#### プロパティ

-   `@State private var scale: CGFloat = 0.8`:
    -   チェックマークアイコンの拡大・縮小率を管理する状態変数です。初期値は `0.8`（少し小さい状態）です。
-   `@State private var opacity: Double = 0.0`:
    -   アイコンの透明度を管理する状態変数です。初期値は `0.0`（完全に透明）です。
-   `@State private var rotation: Double = 0`:
    -   アイコンの回転角度を管理する状態変数です。初期値は `0`度です。

#### `body`の中身

-   `Image(systemName: "checkmark.circle.fill")`:
    -   表示する画像として、システム提供の「塗りつぶされた円の中のチェックマーク」アイコンを指定します。
-   `.font(.system(size: 30))`: アイコンの基本サイズを30ポイントに設定します。
-   `.foregroundColor(.green)`: アイコンの色を緑色に設定します。
-   `.scaleEffect(scale)`:
    -   `scale` 状態変数の値に基づいて、アイコンを拡大・縮小します。
-   `.opacity(opacity)`:
    -   `opacity` 状態変数の値に基づいて、アイコンの透明度を変更します。
-   `.rotationEffect(.degrees(rotation))`:
    -   `rotation` 状態変数の値に基づいて、アイコンを回転させます。

#### `.onAppear` 修飾子

このビューの核心部分です。ビューが画面に表示された瞬間に、一連のアニメーションをトリガーします。

-   `withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { ... }`:
    -   バネのような弾む動き（`spring`）のアニメーションを定義します。
    -   `scale = 1.2`: アイコンを1.2倍に拡大します。
    -   `opacity = 1.0`: アイコンを完全に見える状態（不透明）にします。
    -   これにより、アイコンが「ポンッ」と現れるようなエフェクトが生まれます。

-   `withAnimation(.linear(duration: 0.5)) { ... }`:
    -   一定速度（`linear`）のアニメーションを定義します。
    -   `rotation = 360`: 0.5秒かけてアイコンを360度（一回転）させます。

-   `withAnimation(.easeOut(duration: 0.4).delay(0.2)) { ... }`:
    -   アニメーションの終わりがゆっくりになる（`easeOut`）アニメーションを定義します。
    -   `.delay(0.2)`: 0.2秒遅れてアニメーションを開始します。
    -   `scale = 0.8`: アイコンを元の小さいサイズに戻します。
    -   `opacity = 0.0`: アイコンを再び透明にして、見えなくします。
    -   これにより、アイコンが回転し終わった後に、すっと消えていくようなエフェクトが生まれます。

## 使い方

このビューは、単体で直接使われるというよりは、他のビューにオーバーレイ（重ねて表示）して使われます。

`HomeView` では、`ZStack` を使って `TaskListView` の上にこの `TaskCompletionEffectView` を重ねています。

```swift
ZStack {
    TaskListView(...)
    
    if showCompletionEffect {
        TaskCompletionEffectView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false)
    }
}
```

-   `HomeView` の `@State var showCompletionEffect` が `true` になったときだけ、このビューが生成されて画面に表示されます。
-   `TaskRowView` でタスク完了処理 (`handleTaskCompletion`) が呼ばれると、このフラグが `true` になり、アニメーションが再生されます。
-   アニメーションが終了すると、`HomeView` 側でフラグが `false` に戻され、このビューは画面から取り除かれます。
-   `.allowsHitTesting(false)` は、このエフェクトビューがユーザーのタップ操作を妨げないようにするための重要な設定です。これが `true` だと、エフェクト表示中に背後のタスクリストが操作できなくなってしまいます。
