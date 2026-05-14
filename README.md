# 💧 Hydrolog

**Hydrolog** is a minimalist, open-source hydration tracking application built with **Flutter**. It is designed to help users maintain a healthy lifestyle by effortlessly tracking their daily water intake, visualizing their progress with stunning animations, and providing detailed historical insights.

---

## ✨ Key Features

- **Fluid Bottle Animation:** A beautifully designed, custom-painted water bottle that dynamically fills up with a bouncing fluid animation as you log your water.
- **Quick & Custom Logging:** Add water with one-tap buttons (250ml/500ml) or enter a specific custom amount (e.g., 350ml).
- **Hourly Consumption Chart:** A built-in bar chart on the dashboard visualizing exactly when and how much water you drank throughout the day.
- **Smart Notifications:** Set up custom daily reminders. Choose your active hours (e.g., 09:00 - 22:00) and how often you want to be reminded. The app uses local push notifications to gently nudge you without requiring an internet connection.
- **Advanced History & Statistics:** 
  - **Calendar View:** A color-coded calendar to monitor your daily habits (🟢 Goal Met, 🔴 Goal Missed).
  - **Streak Tracker:** Keep your momentum going by tracking consecutive days you've hit your goal.
  - **Insights:** Automatically calculates your 7-day average, 30-day average, and all-time total water consumed.
- **Profile Customization:** Personalize your experience by setting your name, weight, and a custom daily water goal.
- **Persistent Data:** Your progress is saved locally using `shared_preferences`, ensuring absolute privacy and speed.

---

## 🛠️ Tech Stack

- **Framework:** [Flutter](https://flutter.dev)
- **Language:** [Dart](https://dart.dev)
- **Local Storage:** `shared_preferences` (Key-value based persistent storage)
- **UI Components:** 
  - `table_calendar` for the habit-tracking visualizer.
  - `fl_chart` for the hourly data visualization.
- **Notifications:** `flutter_local_notifications` & `timezone` for highly accurate background alarms.
- **Design:** Custom Canvas/Path drawing for the bottle fluid, combined with Material 3 (M3) architecture.

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
   git clone https://github.com/berkeroner/hydrolog-app.git
   ```

2. **Navigate into the project folder:**
   ```bash
   cd hydrolog-app
   ```

3. **Install dependencies:**
   ```bash
   flutter pub get
   ```

4. **Run the application:**
   ```bash
   flutter run
   ```

## 📦 How to Release (APK)
To build a production-ready APK file:
```bash
flutter build apk --release
```
*The output file will be generated at `build/app/outputs/flutter-apk/app-release.apk`. It is highly recommended to upload this file to the "Releases" section of your GitHub repository rather than committing it to the source code directly.*

## 📄 License
This project is licensed under the MIT License.