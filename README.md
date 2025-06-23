# Mark Me - Location Based Attendance Tracker

Mark Me is a Flutter-based attendance tracker that automatically marks class attendance based on your location and schedule. It is designed for students who want minimal manual input with accurate tracking.

---

## Features

- Weekly class scheduling with day, time, and location
- Automatic attendance marking based on real-time location
- Manual override with custom reasons (e.g., "Teacher absent")
- Attendance history per class with present/absent stats
- Location selection via OpenStreetMap modal picker
- Firebase authentication (email & password login)

---

## Tech Stack

- **Flutter** - UI and app logic
- **Firebase Auth + Firestore** - User login and schedule storage
- **GetX** - State management and routing
- **Geolocator** - Location access and distance checking
- **Workmanager** - Background service to mark attendance
- **Awesome Notifications** - Class reminders
- **OpenStreetMap (flutter_map)** - Location picker UI

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

This project uses Firebase Auth and Firestore, so you must set up your own Firebase project.

#### Steps:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project
3. Add an Android app (use your own package name or keep `com.example.mark_me`)
4. Download the `google-services.json` file and place it in:

```
android/app/google-services.json
```

6. Replace the existing `firebase_options.dart` file by generating one using the Firebase CLI:

```bash
flutterfire configure
```

> This step ensures your app is connected to your own Firebase backend.

---

### 4. Run the App

Make sure you have a device or emulator running:

```bash
flutter run
```

---

## Notes

* The app schedules background checks every 15 minutes to verify attendance.
* No Google Maps API key is required — location picker uses OpenStreetMap.
* Class reminders and attendance marking work offline (notifications and location).
* You must grant location permission and enable location services for the app to function correctly.

