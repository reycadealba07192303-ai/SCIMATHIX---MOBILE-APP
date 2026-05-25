import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/presentation/screens/auth/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:scimathix/presentation/root_wrapper.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully");
  } catch (e) {
    print("Firebase initialization error: $e");
  }

  runApp(
    const ProviderScope(
      child: SciMathnixApp(),
    ),
  );
}

class SciMathnixApp extends StatelessWidget {
  const SciMathnixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SCIMATHNIX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/root': (context) => const RootWrapper(),
      },
    );
  }
}

