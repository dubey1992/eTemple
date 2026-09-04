import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Minimal structured logger.
///
/// Kept intentionally small: it exists so diagnostics are consistent and so no
/// `print` calls end up in the release bundle. Nothing logged here is shown to
/// a visitor, and nothing sensitive (passwords, tokens, cookies) may be passed
/// to it.
class AppLogger {
  const AppLogger({this.enabled = kDebugMode, this.name = 'rkt'});

  final bool enabled;
  final String name;

  void debug(String message, [Map<String, Object?>? context]) {
    if (!enabled) return;
    _emit('DEBUG', message, context);
  }

  void info(String message, [Map<String, Object?>? context]) {
    if (!enabled) return;
    _emit('INFO', message, context);
  }

  /// Errors are always recorded, including in release builds, because they are
  /// what a committee member will be asked about when reporting a problem.
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: name,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void _emit(String level, String message, Map<String, Object?>? context) {
    final suffix = (context == null || context.isEmpty) ? '' : ' $context';
    developer.log('[$level] $message$suffix', name: name);
  }
}
