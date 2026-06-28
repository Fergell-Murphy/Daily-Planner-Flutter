# Daily Planner (Flutter)

A fully offline daily task planner converted from the React Native Expo app. Tasks are stored locally in SQLite with optional start-time notifications.

## Features

- **Today** — Greeting, task list with live progress, search, and quick add
- **Progress** — 7-day date picker, history view, analytics (streak, weekly average)
- **Settings** — Profile name, notification toggle, category display
- **Tasks** — Create, edit, delete, complete toggle, per-task alarms, categories
- **Onboarding** — Name collection on first launch

## Tech Stack

- Flutter 3.x / Dart 3.x
- **Riverpod** — State management
- **GoRouter** — Navigation (tabs + modal edit screen)
- **sqflite** — SQLite persistence (same schema as React Native app)
- **flutter_local_notifications** — Task start alarms

## Project Structure

```
lib/
├── core/           # Theme, constants, utilities
├── data/           # Models, database
├── services/       # Notifications
├── presentation/   # Screens, widgets, providers, router
├── app.dart
└── main.dart
```

## Getting Started

```bash
cd Daily-Planner-Flutter
flutter pub get
flutter run
```

### iOS

```bash
flutter run -d ios
```

### Android

```bash
flutter run -d android
```

## Business Rules (parity with React Native)

- Times stored as **minutes from midnight** (int)
- Dates stored as **`YYYY-MM-DD`** strings
- Completion toggle is **binary** (0 / 100); scheduled progress is display-only
- Streak requires **≥75%** completion on days with tasks
- Notifications fire at **task start time**
# Daily-Planner-Flutter
