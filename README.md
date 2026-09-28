# 📝 Task Tracker

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![Material 3](https://img.shields.io/badge/Material--3-757575?style=for-the-badge&logo=materialdesign&logoColor=white)](https://m3.material.io/)


A clean, modern, zero-cloud **Task and Productivity Tracker app** built with Flutter, Dart 3, and Material Design 3. All your data stays locally on your device with zero setup overhead and instant persistence.

---

## ✨ Features

- 🎯 **Full Task Management (CRUD)**: Create, view, edit, mark complete, and delete tasks effortlessly.
- 🏷️ **Categorization & Priorities**: Organize tasks by categories (`Work`, `Study`, `Personal`, `Health`) and priority levels (`Low`, `Medium`, `High`).
- 📅 **Due Dates & Overdue Indicator**: Set due dates for tasks and track overdue status at a glance.
- 🔍 **Real-Time Search & Filters**: Search titles and notes instantly. Filter by completion status (`All`, `Active`, `Done`) and category.
- 🔀 **Smart Sorting**: Sort tasks dynamically by **Due Date**, **Priority**, or **Newest Created**.
- 📊 **Productivity Statistics Dashboard**:
  - Interactive circular completion rate gauge.
  - Quick stat counters (Total, Active, Done, Overdue).
  - 7-Day completion history bar chart with smooth animations.
  - Per-category progress breakdown.
- 🌓 **Persistent Light & Dark Theme**: Toggle between Light and Dark mode, saved across sessions.
- 🔄 **Swipe to Delete & Instant Undo**: Swipe tasks to remove them with an instant undo SnackBar option.
- 📴 **100% Offline-First**: Local storage via `shared_preferences` JSON serialization.

---

## 📸 Overview & Layout

```
Task Tracker App Structure
├── 🏠 Tasks Screen
│   ├── 🔍 Search Bar & Category Filter Chips
│   ├── 🔀 Filter & Sort Option Bars
│   └── 📋 Interactive Task List (Swipeable tiles, completion toggle, priority badges)
├── 📊 Stats Dashboard
│   ├── ⭕ Completion Ring Progress Indicator
│   ├── 📈 7-Day Completion Activity Bar Chart
│   └── 🏷️ Category Progress Breakdown Bars
└── ➕ Task Form Screen
    ├── 📝 Title & Notes input
    ├── 🏷️ Category & Priority Selection
    └── 📅 Custom Date Picker for Due Dates
```

---

## 🛠 Tech Stack & Architecture

- **Framework**: Flutter (Dart 3, null safety)
- **Design System**: Material Design 3 (`ColorScheme.fromSeed(seedColor: Colors.indigo)`)
- **State Management**: `Provider` (`ChangeNotifier`)
- **Persistence**: `shared_preferences` (JSON stringification)
- **Zero Heavy External Dependencies**: Custom animated charts built with standard Flutter widgets (`CustomPaint`, `AnimatedContainer`).

---

## 🗂 Project Structure

```
lib/
├── main.dart                 # App entry point, MaterialApp, Provider setup & theme configuration
├── models/
│   └── task.dart             # Task data model, Priority enum, JSON serialization & sentinel copyWith
├── providers/
│   └── task_provider.dart    # ChangeNotifier: Task list management, filter/sort logic, stats calculations & persistence
├── screens/
│   ├── home_screen.dart      # Main bottom navbar scaffold, Tasks list view & filter UI
│   ├── stats_screen.dart     # Analytics tab with circular gauge, 7-day chart & category breakdown
│   └── task_form_screen.dart # Form screen for adding and editing tasks with validation
├── utils/
│   └── format.dart           # Custom hand-rolled date formatting & labels (no external intl dependency)
└── widgets/
    └── task_tile.dart        # Reusable dismissible task card widget with haptic feedback & semantic labels

test/
├── task_provider_test.dart   # Unit tests for provider state, CRUD, sorting, and stats calculation
├── task_form_test.dart       # Widget tests for task creation, editing, deletion, and undo
├── filter_ui_test.dart       # Widget tests for searching, category filtering, and status tabs
└── smoke_test.dart           # Smoke tests verifying initial app initialization and task adding workflow
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.0.0 or higher)
- [Dart SDK](https://dart.dev/get-dart) (version 3.0.0 or higher)
- VS Code or Android Studio with Flutter plugin installed
- An Android Emulator, iOS Simulator, or Chrome browser for web testing

---

### 💻 Installation & Setup

1. **Clone the repository** (or navigate to project folder):
   ```bash
   git clone https://github.com/yourusername/task_tracker.git
   cd task_tracker
   ```

2. **Fetch Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the Application**:
   ```bash
   flutter run
   ```

---

## 🧪 Running Tests & Code Quality

Run unit and widget test suite:
```bash
flutter test
```

Run linter checks:
```bash
flutter analyze
```

Build a production release package:
```bash
flutter build apk --release
```

---

## ⚠️ Troubleshooting

### Error: `flutter : The term 'flutter' is not recognized...`

If you encounter this command error in PowerShell/Terminal:

#### Solution for Windows:
1. Locate where Flutter is installed on your computer (e.g. `C:\src\flutter\bin` or `C:\flutter\bin`).
2. Press `Win + R`, type `sysdm.cpl`, and hit **Enter**.
3. Go to **Advanced** tab -> click **Environment Variables**.
4. Under **User variables** or **System variables**, select `Path` and click **Edit**.
5. Click **New** and paste the full path to your Flutter `bin` directory (e.g. `C:\src\flutter\bin`).
6. Click **OK** on all dialogs, close your terminal/IDE, reopen it, and run `flutter --version` to verify.

---

