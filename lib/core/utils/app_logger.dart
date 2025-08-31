import 'package:flutter/foundation.dart';

class AppLogger {
  static void log(String message, {String? tag}) {
    if (kDebugMode) {
      final tagStr = tag != null ? '[$tag] ' : '';
      debugPrint('🔥 $tagStr$message');
    }
  }

  static void logAuth(String message) {
    log(message, tag: 'Auth');
  }

  static void logRepo(String message) {
    log(message, tag: 'Repo');
  }

  static void logBloc(String message) {
    log(message, tag: 'Bloc');
  }

  static void logApp(String message) {
    log(message, tag: 'App');
  }
}
