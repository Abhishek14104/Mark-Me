# Mark Me - Location-Based Attendance Tracker

Mark Me is a Flutter + Kotlin hybrid attendance app that automatically marks class attendance based on your location and weekly schedule. It’s built for students who want accurate, low-effort tracking without manual check-ins.

---

## Features

- Schedule weekly classes with day, time, and location
- Automatic attendance marking at class time based on real-time location
- Manual override with custom reasons (e.g., "Teacher absent")
- Attendance history per subject (present/absent stats)
- Location selection via OpenStreetMap modal picker
- Class reminder notifications (20 minutes before)
- Firebase Authentication (Email/Password login)

---

## Tech Stack

| Layer        | Tool/Library                          |
|--------------|----------------------------------------|
| UI & Logic   | Flutter + GetX                        |
| Backend      | Firebase Auth + Firestore             |
| Location     | Geolocator (Flutter) + FusedLocation (Kotlin) |
| Background   | Kotlin native: AlarmManager, BroadcastReceiver, ForegroundService |
| Reminders    | Kotlin native: NotificationManager     |
| Location UI  | flutter_map + OpenStreetMap            |

---

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/mark_me.git
cd mark_me
````

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Firebase Setup (Required)

* Go to [Firebase Console](https://console.firebase.google.com/)
* Create a new project
* Add an Android app using your package name (e.g., `com.example.mark_me`)
* Download `google-services.json` and place it in:

```
android/app/google-services.json
```

* Generate `firebase_options.dart` using the Firebase CLI:

```bash
flutterfire configure
```

### 4. Permissions & Device Setup

Ensure the app has the following runtime permissions:

* Location (`ACCESS_FINE_LOCATION`)
* Notification (on Android 13+)
* Schedule exact alarms (`SCHEDULE_EXACT_ALARM`) — prompted via native Kotlin

Important: Exact alarm permission must be manually approved from system settings on Android 12+. The app will automatically open the settings page if permission is not granted.

---

### 5. Run the App

Make sure your device/emulator is connected and location is enabled:

```bash
flutter run
```

---

## Permissions Used

| Permission                         | Why It's Needed                                      |
| ---------------------------------- | ---------------------------------------------------- |
| `ACCESS_FINE_LOCATION`             | To detect proximity to the class location            |
| `POST_NOTIFICATIONS` (Android 13+) | To show reminder and attendance result notifications |
| `SCHEDULE_EXACT_ALARM`             | To trigger alarms at the exact class time            |

