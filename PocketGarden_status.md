# Pocket Garden Development Status – 2025‑05‑16

## ✅ Implemented Features *(MUST core)*

| # | Feature Block | File / Type | Main Properties & Methods | Behavior / Notes |
|---|---------------|-------------|---------------------------|------------------|
| 1 | **App Entry** | `PocketGardenApp.swift` | `@StateObject gardenVM` → `.environmentObject`<br>`onAppear { load() }` / `onReceive willTerminate { save() }` | DI & persistence bootstrap |
| 2 | **Task Data Model** | `Task.swift` | `struct Task` (Identifiable/Codable)<br>`struct GardenState` + `addExp(_:)` | Holds title / category / isDone / dates & EXP↔level math, 開始日時・終了日時・締切日 |
| 3 | **State Management (VM)** | `GardenViewModel.swift` | `@Published tasks, gardens, currentCategory`<br>`addTask`, `toggleDone`, `delete`<br>`startFocus`, `pauseFocus`, `skipPhase`<br>`load`, `save` | Singleton ObservableObject; 25→5 loop & EXP bump verified |
| 4 | **Home Screen** | `HomeView.swift` | `@Namespace ns` → `LeafView`<br>Task `List` CRUD / Focus nav<br>完了済みタスク非表示<br>全タスク一括達成ボタン | Leaf animation visible, AddTaskSheet included |
| 5 | **Quick Add Sheet** | `AddTaskSheet` | `TextField` & `vm.addTask`<br>カテゴリ選択<br>開始・終了・締切日設定 | Empty‑string disable logic |
| 6 | **Focus Screen** | `FocusView.swift` + sub‑views | `CircleTimer`, `FocusBackground`<br>アイコンボタン<br>セッション数表示 | Timer UI, gradient, skip flow done |
| 7 | **Leaf Drawing & Sway** | `LeafView.swift` | `Canvas` paths + `matchedGeometryEffect` | Namespace mandatory; sway loop works |
| 8 | **Stats Heat‑map** | `StatisticsView.swift` | `RectangleMark` + `foregroundStyle(by:)`<br>カレンダー表示<br>日別詳細シート<br>月選択機能 | カレンダーUI実装、詳細表示あり |
| 9 | **Completed Tasks View** | `CompletedTasksView.swift` | 達成タスク一覧<br>日付選択<br>日付ナビゲーション | 特定日の達成タスク確認 |
|10 | **Unit Tests** | `PocketGardenTests.swift` | `testAddExpIncrementsLevelAt25`, `testToggleDoneAddsExp` | All green |
|11 | **Build Settings** | Scheme: PocketGarden (Debug) | Target iOS 17 / iPhone 15 Pro sim | Build & run OK |

---

## 🔜 Planned Features & Required Functions

### 1. StatisticsView Enhancements *(SHOULD‑S1)*

| Addition | Where | Functions / Props | Notes |
|----------|-------|-------------------|-------|
| ~~Heat‑map color scale tuning~~ ✅ | `StatisticsView` | `.colorScale([...])` | Minutes‑based gradient |
| ~~Day detail sheet on tap~~ ✅ | `StatisticsView` | `.sheet(item:$selected){ DayDetailView }` | Shows task list |

### 2. Multiple Garden Slots *(SHOULD‑S2)*

| Step | File | Needed Elements | Detail |
|------|------|-----------------|--------|
| 1 | `GardenViewModel` | `@Published categories`, `addCategory(_:)` | init new GardenState |
| 2 | `HomeView` | `TabView(.page)` wrapper | Page per category |
| 3 | `HomeCore` (new View) | category param | Task list + LeafView |
| 4 | UI | "＋Garden" button | Alert text input |

### 3. Theme Switcher *(COULD‑C1)*

| Where | Addition | Mechanism |
|-------|----------|-----------|
| Assets | Color sets | Light/Dark swatches |
| `GardenViewModel` | `@Published theme` enum | save/load |
| `SettingsView` | Picker | |
| Views | Replace hard colors | `Color("LeafGreen")` |

### 4. Sound Toggle *(COULD‑C2)*

| Point | File / Change | Function |
|-------|---------------|----------|
| Sounds assets | `success.caf`, `tick.caf` | |
| `GardenViewModel` | `soundOn`, `play(_:)` | AVAudioPlayer |
| Hooks | toggleDone etc. | |

### 5. Level‑Max Firework *(COULD‑C3)*

| Where | Addition | Idea |
|-------|----------|------|
| `LeafView` overlay | `ParticleView` | Canvas / TimelineView |

---

## 📌 Function / Method Inventory (with plans)

| File | Symbol | Purpose |
|------|--------|---------|
| `PocketGardenApp` | – | Scene & DI |
| `Task.swift` | `Task.init`, `GardenState.addExp` | Entities |
| `GardenViewModel` | `addTask`, `toggleDone`, `delete`, `completeTask`, `startFocus`, `pauseFocus`, `skipPhase`, `tick`, `endPhase`, `load`, `save`, `aggregatedStudyMinutes`, **planned** `addCategory`, `play` | Core logic |
| `HomeView` | `AddTaskSheet.dismiss`, Leaf integration | UI |
| `LeafView` | `leafRects`, `animate` | Drawing |
| `FocusView` | `progress`, `sessionCount` | Timer |
| `StatisticsView` | カレンダー表示, 日別詳細 | Stats |
| `CompletedTasksView` | 完了タスク一覧, 日付選択機能 | 履歴表示 |
| `ParticleView` (planned) | timeline | Firework |

---

## 🏃 Sprint Schedule (W4–W5)

| Day | Goal | Tasks |
|-----|------|-------|
| W4‑D3 | ~~Finalize Leaf rotation, assets~~ ✅ | verify Canvas transforms |
| W4‑D4 | ~~Focus screen polish~~ ✅ | Pause resume bug, warning haptic |
| W4‑D5 | ~~Heat‑map finish~~ ✅ | color scale, DayDetailView |
| W5‑D1 | ~~Multi‑Garden phase‑1~~ ✅ | addCategory, TabView |
| W5‑D2 | ~~Garden switch UX~~ ✅ | segmented/page tuning |
| W5‑D3 | UI Polish | スワイプアクション調整, アニメーション追加 |

---

## ❓ Open Questions / Checks

* **Negative EXP guard:** not yet
* **Haptic multi‑fire:** needs debounce
* **Accessibility labels:** untouched
* **セッション数表示:** 実装済み ✅
* **カレンダー表示:** 実装済み ✅
* **日別詳細表示:** 実装済み ✅
* **カテゴリ選択:** 実装済み ✅
* **完了タスク一覧:** 実装済み ✅
