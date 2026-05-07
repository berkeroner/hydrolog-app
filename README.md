# 💧 Hydrolog

**Hydrolog** is a minimalist, open-source hydration tracking application built with **Flutter**. It is designed to help users maintain a healthy lifestyle by effortlessly tracking their daily water intake and providing visual feedback on their consistency.

---

## ✨ Key Features

- **Quick Logging:** Add water intake with one-tap buttons (250ml/500ml).
- **Progress Tracking:** Real-time circular progress indicator showing how close you are to your daily goal.
- **Visual History (Calendar):** A color-coded calendar view to monitor your habits:
  - 🟢 **Green:** Daily goal reached.
  - 🔴 **Red:** Goal missed.
- **Profile Customization:** Personalize your experience by setting your name and a custom daily water goal.
- **Persistent Data:** Your progress is saved locally, so you never lose your data even after closing the app.

## 🛠️ Tech Stack

- **Framework:** [Flutter](https://flutter.dev)
- **Language:** [Dart](https://dart.dev)
- **Local Storage:** `shared_preferences` (Key-value based persistent storage)
- **UI Components:** `table_calendar` for the habit-tracking visualizer.
- **Design:** Material 3 (M3) Design System.

---

## 🚀 Getting Started

Follow these instructions to get a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/)
- An Android/iOS Emulator or a physical device.

### Installation

1. **Clone the repository:**
   ```bash
   git clone [https://github.com/berkeroner/hydrolog-app.git](https://github.com/berkeroner/hydrolog-app.git)

2. **Navigate into the project folder:**
   ```bash
   cd hydrolog-app

3. **Install dependencies:**
   ```bash
   flutter pub get

4. **Run the application:**
   ```bash
   flutter run

## 🏗️ Project Architecture (MVP)
- Hydrolog follows a clean and iterative development approach. As an MVP (Minimum Viable Product), it focuses on solving the core problem of hydration tracking with maximum efficiency.

- **Data Persistence**: Uses `shared_preferences` for lightweight, fast, and secure local storage.

- **State Management**: Implements `StatefulWidgets` for simple yet reactive UI updates.

- **Modular Design**: Separate screens for `Dashboard`, `History (Calendar)`, and `Profile` for better maintainability.

## 📄 License
This project is licensed under the MIT License.