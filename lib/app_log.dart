import 'package:flutter/material.dart';

enum LogLevel { info, warn, error }

class LogEntry {
  LogEntry(this.level, this.message) : time = DateTime.now();

  final LogLevel level;
  final String message;
  final DateTime time;

  String get timeText {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
  }

  @override
  String toString() =>
      '$timeText ${level.name.toUpperCase().padRight(5)} $message';
}

/// In-memory log that the on-screen log panel listens to.
class AppLog {
  AppLog._();

  static const _max = 500;
  static final entries = ValueNotifier<List<LogEntry>>(const []);

  static int get errorCount =>
      entries.value.where((e) => e.level == LogLevel.error).length;

  static void info(String m) => _add(LogLevel.info, m);
  static void warn(String m) => _add(LogLevel.warn, m);
  static void error(String m) => _add(LogLevel.error, m);

  static void _add(LogLevel level, String message) {
    final next = [...entries.value, LogEntry(level, message)];
    if (next.length > _max) next.removeRange(0, next.length - _max);
    entries.value = next;
    debugPrint('[HIS] $level $message');
  }

  static void clear() => entries.value = const [];

  static String asText() => entries.value.join('\n');
}

Color logColor(LogLevel level) => switch (level) {
  LogLevel.info => const Color(0xFFB8E3B5),
  LogLevel.warn => const Color(0xFFFFD27A),
  LogLevel.error => const Color(0xFFFF8A80),
};
