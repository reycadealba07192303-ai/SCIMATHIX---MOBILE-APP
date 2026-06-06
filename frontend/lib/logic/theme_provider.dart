import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scimathix/core/theme/app_theme.dart';

/// Global theme-mode provider with persistence via shared_preferences.
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(() => ThemeModeNotifier());

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'dark_mode_enabled';

  @override
  ThemeMode build() {
    // AppTheme.isDarkMode is already initialized synchronously in main.dart
    return AppTheme.isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  bool get isDark => state == ThemeMode.dark;

  Future<void> toggle(bool enabled) async {
    AppTheme.isDarkMode = enabled;
    state = enabled ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, enabled);
  }
}
