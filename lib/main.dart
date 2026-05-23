import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'services/cache_service.dart';
import 'services/notification_service.dart';
import 'features/auth/login_screen.dart';

// Background FCM handler — must be top-level
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await _initializeFirebase();
}

Future<void> _initializeFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return;
  }

  final options = DefaultFirebaseOptions.currentPlatform;
  final isPlaceholder =
      options.apiKey == 'missing' ||
      options.appId == 'missing' ||
      options.projectId == 'missing';

  if (isPlaceholder) {
    await Firebase.initializeApp();
  } else {
    await Firebase.initializeApp(options: options);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase
  await _initializeFirebase();

  // Background notification handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Hive offline cache
  await Hive.initFlutter();
  await CacheService.openBoxes();

  // Notification service
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(const CampusCompanionApp());
}

class CampusCompanionApp extends StatelessWidget {
  const CampusCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}
