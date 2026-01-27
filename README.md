
# Press Me App 🎯

A real-time synchronization demo. Press a button on a **Flutter** mobile app and watch the counter update instantly on a **Python (PyQt5)** desktop app, powered by **Firebase**.

## ✨ Key Features

* **Cross-Platform:** Seamless communication between Mobile (Android/iOS) and Desktop (Windows/macOS/Linux).
* **Real-Time:** Sub-second latency using Firebase Realtime Database listeners.
* **Threaded Desktop UI:** Python app uses QThreads to ensure the GUI never freezes while listening for data.

---

## 🛠️ Tech Stack

| Component | Technology |
| --- | --- |
| **Mobile** | Flutter & Dart |
| **Desktop** | Python 3.14+ & PyQt5 |
| **Backend** | Firebase Realtime Database |

---

## 🚀 Quick Start

### 1. Firebase Configuration

1. Generate a **Service Account JSON** from the Firebase Console (Settings > Service Accounts).
2. Rename it to `press-me-app-desktop-firebase-key.json`.
3. Place it in the `python_app_desktop/` folder.
4. Ensure your Database Rules are set to:
```json
{ "rules": { ".read": true, ".write": true } }

```



### 2. Mobile Setup (Flutter)

```bash
cd flutter_app_phone
flutter pub get
flutter run

```

### 3. Desktop Setup (Python)

```bash
cd python_app_desktop
pip install -r requirements.txt
python main.py

```

---

## 📁 Project Structure

* `flutter_app_phone/`: Mobile source code and Firebase configuration.
* `python_app_desktop/`: PyQt5 application and Firebase Admin SDK logic.
* `.gitignore`: Pre-configured to protect your Firebase keys and environment files.

---

## 🔐 Security Note

**Never commit your JSON keys.** The `.gitignore` in this repo is configured to block:

* `*.json` (Service account keys)
* `google-services.json`
* `GoogleService-Info.plist`

---

**Author:** [awittygentleman](https://www.google.com/search?q=https://github.com/awittygentleman)
