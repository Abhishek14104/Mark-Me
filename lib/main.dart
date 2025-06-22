import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mark_me/app/views/home_view.dart';
import 'package:mark_me/app/views/login_view.dart';
import 'package:workmanager/workmanager.dart';

import 'firebase_options.dart';
import 'app/controllers/auth_controller.dart';
import 'app/routes/app_pages.dart';
import 'app/services/background_service.dart';
import 'app/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  Get.lazyPut(() => AuthController());
  await NotificationService.init();

  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );

  Workmanager().registerPeriodicTask(
    "attendanceCheckTask",
    attendanceTask,
    frequency: const Duration(minutes: 15),
    initialDelay: const Duration(minutes: 5),
  );

  runApp(const MarkMeApp());
}

class MarkMeApp extends StatelessWidget {
  const MarkMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mark Me',
      getPages: AppPages.routes,
      // checks for the user login status
      home: const RootPage(),
    );
  }
}

class RootPage extends StatelessWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      return const HomeView();
    } else {
      return const LoginView();
    }
  }
}
