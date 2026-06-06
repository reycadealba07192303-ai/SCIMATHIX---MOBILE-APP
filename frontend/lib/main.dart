import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/logic/theme_provider.dart';
import 'package:scimathix/presentation/screens/auth/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:scimathix/presentation/root_wrapper.dart';
import 'firebase_options.dart';

  import 'package:shared_preferences/shared_preferences.dart';
  
  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (kDebugMode) debugPrint("Firebase initialized successfully");
    } catch (e) {
      if (kDebugMode) debugPrint("Firebase initialization error: $e");
    }
  
    // Load theme preference synchronously before the app starts to prevent flashing
    try {
      final prefs = await SharedPreferences.getInstance();
      AppTheme.isDarkMode = prefs.getBool('dark_mode_enabled') ?? false;
    } catch (e) {
      AppTheme.isDarkMode = false;
    }
  
    runApp(
    const ProviderScope(
      child: SciMathnixApp(),
    ),
  );
}

class SciMathnixApp extends ConsumerWidget {
  const SciMathnixApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'SCIMATHNIX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/root': (context) => const RootWrapper(),
      },
    );
  }
}

