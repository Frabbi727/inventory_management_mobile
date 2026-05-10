import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';

import 'app.dart';
import 'core/notifications/notification_service.dart';
import 'core/offline/sync_manager.dart';
import 'features/auth/presentation/bindings/home_binding.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Notification Service
  final notificationService = NotificationService();
  await notificationService.init();
  Get.put(notificationService, permanent: true);


  // Manually register all dependencies
  _initDependencies();

  // Initialize and start the SyncManager
  final syncManager = Get.put(SyncManager(), permanent: true);
  syncManager.init();


  runApp(const SalesApp());
}

void _initDependencies() {
  // This is a good place to ensure all your GetX dependencies are registered.
  // Calling one of the main bindings should trigger the chain of registrations.
  HomeBinding().dependencies();
}