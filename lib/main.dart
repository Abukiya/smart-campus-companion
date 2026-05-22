import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Hive (offline cache)
  await Hive.initFlutter();

  runApp(const CampusCompanionApp());
}

class CampusCompanionApp extends StatelessWidget {
  const CampusCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1D9E75),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school, size: 64, color: Color(0xFF1D9E75)),
              SizedBox(height: 16),
              Text(
                'Campus Companion',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF085041),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Firebase connected ✓',
                style: TextStyle(color: Colors.green),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Backwards-compatible alias expected by tests
class MyApp extends CampusCompanionApp {
  const MyApp({super.key});
}