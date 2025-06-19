# Pocket Garden 🌱

> *25 min Focus → 5 min Break → Instant Growth!* – a minimal habit‑forming companion for students, made entirely with **SwiftUI Canvas**.

![Demo Video Placeholder](docs/demo.gif)

---

## ✨ Features (MVP)

|  🌿  |  Description                                                                |
| ---- | --------------------------------------------------------------------------- |
|  1   | **Task List CRUD** – swipe to add / edit / delete                           |
|  2   | **Focus Timer (25⟶5 loop)** – circular progress ring + monospaced countdown |
|  3   | **Dynamic Plant Growth** – vector leaves generated with `Canvas` & `Path`   |
|  4   | **Fluid Animations + Haptics** – spring scale‑up & leaf sway                |
|  5   | **Offline Persistence** – `@AppStorage` + JSON backup                       |

### SHOULD (to be shipped Week 5)

* 📊 Day‑by‑day heat‑map of total focus minutes
* 🌱 Multiple garden slots – one per task category

### COULD (stretch goals)

* 🎨 Theme switcher (Light/Dark & Forest/Desert palettes)
* 🔕 Mute toggle for sound effects
* 🎆 Level‑Max firework particle burst

---

## 🏗 Tech Stack

* **Swift 5.10** + **SwiftUI (iOS 17+)**
* `Canvas`, `TimelineView`, `GeometryEffect`, `CHHapticEngine`
* `Swift Charts` (heat‑map)
* GitHub Actions – build & lint on every PR

---

## 📅 Roadmap

|  Week  |  Milestone      |  Key Tasks                                      |
| ------ | --------------- | ----------------------------------------------- |
|  1     | Project init    | Repo setup · LeafView prototype · Home skeleton |
|  2     | CRUD done       | Task model · List actions · Persistence         |
|  3     | Timer loop      | Ring UI · 25→5 auto cycle                       |
|  4     | Polished growth | Animations · Haptics · Exp logic                |
|  5     | Should features | Heat‑map · TabView gardens                      |
|  6     | Ship & shoot    | Final polish · 30 s demo recording              |

---

## 🛠 Getting Started

```bash
# 1. Clone
$ git clone https://github.com/yourname/PocketGarden.git
$ cd PocketGarden

# 2. Open in Xcode 15+
$ open PocketGarden.xcodeproj

# 3. Run on iOS 17 simulator or device
```

> **Note:** The project targets **iOS 17** to leverage the latest SwiftUI APIs.

---

## 🤝 Contributing

PRs & issues are welcome. Please follow the conventional commits style and run SwiftLint before pushing.

---

## 📜 License

Pocket Garden is released under the **MIT License** – see `LICENSE` for details.
