import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// A simple logger that only outputs in debug mode.
/// In release builds, all log calls are no-ops.
class AppLogger {
  AppLogger._();

  /// Log an informational message (debug only).
  static void info(String message) {
    if (kDebugMode) {
      developer.log(message, name: 'SCIMATHIX');
    }
  }

  /// Log a warning message (debug only).
  static void warning(String message) {
    if (kDebugMode) {
      developer.log('⚠️ $message', name: 'SCIMATHIX');
    }
  }

  /// Log an error with optional exception details (debug only).
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      developer.log(
        '❌ $message',
        name: 'SCIMATHIX',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
