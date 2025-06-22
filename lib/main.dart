import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:mark_me/app/services/notification_service.dart';

import 'firebase_options.dart';
import 'app/controllers/auth_controller.dart';
import 'app/routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize GetX AuthController
  Get.lazyPut(() => AuthController());

  // Initialize Awesome Notifications
  // AwesomeNotifications().initialize(
  //   null,
  //   [
  //     NotificationChannel(
  //       channelKey: 'basic_channel',
  //       channelName: 'Class Reminders',
  //       channelDescription: 'Notification for class reminders',
  //       defaultColor: Colors.teal,
  //       importance: NotificationImportance.High,
  //       channelShowBadge: true,
  //     )
  //   ],
  //   debug: true,
  // );
  await NotificationService.init(); // BEFORE runApp()

  runApp(const MarkMeApp());
}

class MarkMeApp extends StatelessWidget {
  const MarkMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mark Me',
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
    );
  }
}
