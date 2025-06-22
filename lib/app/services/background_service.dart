import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:mark_me/firebase_options.dart';
import 'package:intl/intl.dart';

const String attendanceTask = "verifyAttendanceTask";

@pragma('vm:entry-point')
Future<void> callbackDispatcher() async {
  Workmanager().executeTask((task, inputData) async {
    print("[Attendance] Background task started");

    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid == null) {
        print("[Attendance] No user logged in");
        return Future.value(true);
      }

      final scheduleSnapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("schedules")
          .get();

      // If no schedules exist, cancel background task
      if (scheduleSnapshot.docs.isEmpty) {
        await Workmanager().cancelByUniqueName("attendanceCheckTask");
        print("[WorkManager] No schedules found. Background task cancelled.");
        return Future.value(true);
      }

      final now = DateTime.now();
      final currentWeekday = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][now.weekday - 1];
      final todayStr = now.toIso8601String().substring(0, 10);

      for (final doc in scheduleSnapshot.docs) {
        final data = doc.data();
        final schedule = data["schedule"];
        final course = data["course"];

        if (schedule == null || course == null) {
          print("[Attendance] Skipping incomplete data in ${doc.id}");
          continue;
        }

        if (schedule.containsKey(currentWeekday)) {
          final entry = schedule[currentWeekday];
          final start = entry["start"];
          final location = entry["location"];

          print("[Attendance] Found entry for $course on $currentWeekday: start=$start");

          try {
            final parsedTime = DateFormat.jm().parse(start);
            final scheduledTime = TimeOfDay.fromDateTime(parsedTime);

            final classTime = DateTime(
              now.year,
              now.month,
              now.day,
              scheduledTime.hour,
              scheduledTime.minute,
            );

            final diff = now.difference(classTime).inMinutes;
            print("[Attendance] Time diff for $course: $diff mins");

            if (diff >= 0 && diff <= 10) {
              print("[Attendance] Time window matched. Getting location...");

              final position = await Geolocator.getCurrentPosition();

              print("[Attendance] Current location: (${position.latitude}, ${position.longitude})");
              print("[Attendance] Scheduled location: (${location["lat"]}, ${location["lng"]})");

              final distance = Geolocator.distanceBetween(
                position.latitude,
                position.longitude,
                location["lat"],
                location["lng"],
              );

              final status = distance <= 100 ? "Present" : "Absent";
              print("[Attendance] Distance = ${distance.toStringAsFixed(2)} m => Status: $status");

              final attendanceRef = FirebaseFirestore.instance
                  .collection("users")
                  .doc(uid)
                  .collection("schedules")
                  .doc(doc.id)
                  .collection("attendance")
                  .doc(todayStr);

              await attendanceRef.set({
                "status": status,
                "timestamp": FieldValue.serverTimestamp(),
              });

              print("[Attendance] Firestore updated successfully");

              await AwesomeNotifications().createNotification(
                content: NotificationContent(
                  id: now.millisecondsSinceEpoch % 100000,
                  channelKey: "basic_channel",
                  title: "$course attendance recorded",
                  body: "You were marked $status",
                ),
              );
              print("[Attendance] Notification sent for $course");
            } else {
              print("[Attendance] Skipping $course — outside time window");
            }
          } catch (e) {
            print("[Attendance] Error parsing time or checking location for $course: $e");
          }
        } else {
          print("[Attendance] No class for $course on $currentWeekday");
        }
      }
    } catch (e) {
      print("[Attendance] Fatal error in background task: $e");
    }

    return Future.value(true);
  });
}
