# Pekis 🐧

![Platform](https://img.shields.io/badge/Platform-iOS-black)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-blue)
![Status](https://img.shields.io/badge/Status-Active_Development-green)

**Pekis** is a dedicated iOS application designed to bridge the gap for couples in long-distance relationships. Built with **SwiftUI** and a privacy-first architecture, it provides a shared digital space for connection, play, and intimacy without relying on third-party servers.

> **Technical Overview:** This project implements a scalable, production-ready iOS architecture (MVVM), utilizes Apple's latest concurrency models (`async/await`), and enforces strict user privacy via a serverless CloudKit synchronization layer.

---

## 🎯 Project Goal

Long-distance relationships are hard. Texting isn't always enough. Pekis aims to provide meaningful interactions through structured activities rather than just passive messaging.

**Core Philosophy:**
*   **Intentionality:** Every feature is designed to spark a specific type of connection (fun, deep, or spontaneous).
*   **Privacy:** Your relationship data belongs to you, not a server.
*   **Native Experience:** A buttery smooth, 100% SwiftUI interface that feels at home on iOS.

---

## ✨ Features

*   **📸 Moment Share:** A private, widget-friendly photo sharing feed to show what you're doing *right now*.
*   **💌 Love Notes:** Send digital sticky notes that persist on your partner's dashboard.
*   **🎲 Date Roulette:** Can't decide what to do for your virtual date? Let the app decide.
*   **🗣️ Topic Generator:** Deep conversation starters to move beyond "How was your day?".
*   **🧩 Word Search:** A real-time multiplayer game to play together (powered by custom matchmaking).
*   **⚖️ This or That:** A fun compatibility game to learn more about each other's preferences.

---

## 📸 Screenshots

| Dashboard | Moment Share | Word Search |
|:---:|:---:|:---:|
| *![Dashboard](Assets.xcassets/DashboardCouple.imageset/Dashboard.png)* | *![Moment Share](Assets.xcassets/AppIcon.appiconset/Icon.png)* | *![Word Search](Assets.xcassets/AppIcon.appiconset/Icon.png)* |
| *Your shared home* | *Share your world* | *Play together* |

*(Note: Screenshots are placeholders. Please run the app to see the UI in action!)*

---

## 🔒 Privacy First Architecture

Pekis is built with a **"Local-First, Cloud-Sync"** philosophy.

*   **No Proprietary Backend:** We do not maintain a central database of user messages or photos.
*   **CloudKit:** All data synchronization happens via Apple's **CloudKit**. This means your data is stored in your private iCloud container, encrypted by Apple.
*   **Direct Connection:** Real-time features (like games) use peer-to-peer connectivity or private CloudKit shares.

---

## 🛠 How to Build

### Prerequisites
*   Xcode 15.0+
*   iOS 17.0+ Simulator or Device

### Installation
1.  **Clone the repository:**
    ```bash
    git clone https://github.com/martinnss/Pekis.git
    cd Pekis
    ```

2.  **Open the project:**
    Double-click `Pekis.xcodeproj` to open in Xcode.

3.  **Configure Signing:**
    *   Select the `Pekis` target.
    *   Go to the **Signing & Capabilities** tab.
    *   Select your own **Team**.
    *   *Note: You may need to change the Bundle Identifier to something unique (e.g., `com.yourname.Pekis`) to build on a physical device.*

4.  **Build and Run:**
    Press `Cmd + R` to build and run on your selected simulator.

### Configuration (Optional)
*   **Linting:** This project uses `SwiftLint` to enforce code style. If you don't have it installed, the build script may warn you. Install it via Homebrew: `brew install swiftlint`.

---

## 🏗 Architecture

The app follows a strict **MVVM (Model-View-ViewModel)** pattern to ensure testability and separation of concerns.

*   **Models:** Immutable structs (`Codable`, `Identifiable`) representing data.
*   **ViewModels:** `MainActor` isolated classes handling business logic and state (`@Published`).
*   **Views:** Purely declarative SwiftUI views.
*   **Services:** Protocol-oriented service layer for dependency injection (e.g., `MatchmakingServiceProtocol`).

### Directory Structure
```
Pekis/
├── App/              # App entry point and configuration
├── Core/             # Shared services, extensions, and utilities
├── Features/         # Feature-based modules (Home, Games, etc.)
│   ├── Models/
│   ├── ViewModels/
│   └── Views/
└── Shared/           # Reusable UI components
```

---

## 🤝 Contributing

We welcome contributions! Whether you're fixing a bug, adding a new "Date Idea," or translating the app.

1.  Fork the Project.
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`).
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`).
4.  Push to the Branch (`git push origin feature/AmazingFeature`).
5.  Open a Pull Request.

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and development process.

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---

*Built with 💜 by Martin for LDR couples everywhere.*
