import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AppLogger {
  static final List<_LogEntry> _buffer = [];
  static const int _maxBufferSize = 100;
  static bool _initialized = false;
  static String? _logDir;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      _logDir = '${dir.path}/logs';
      await Directory(_logDir!).create(recursive: true);
      _initialized = true;
    } catch (_) {}
  }

  static void info(String message, {String? tag}) {
    _log('INFO', message, tag: tag);
  }

  static void warn(String message, {String? tag}) {
    _log('WARN', message, tag: tag);
  }

  static void error(String message, {String? tag, Object? error, StackTrace? stack}) {
    _log('ERROR', message, tag: tag, error: error, stack: stack);
  }

  static void _log(String level, String message, {
    String? tag,
    Object? error,
    StackTrace? stack,
  }) {
    final entry = _LogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
      error: error?.toString(),
      stack: stack?.toString(),
    );

    _buffer.add(entry);
    if (_buffer.length > _maxBufferSize) {
      _buffer.removeAt(0);
    }

    _writeToFile(entry);
  }

  static Future<void> _writeToFile(_LogEntry entry) async {
    if (!_initialized || _logDir == null) return;
    try {
      final date = '${entry.timestamp.year}-${entry.timestamp.month.toString().padLeft(2, '0')}-${entry.timestamp.day.toString().padLeft(2, '0')}';
      final file = File('$_logDir/app_$date.log');
      await file.writeAsString(
        '${_formatEntry(entry)}\n',
        mode: FileMode.append,
      );
    } catch (_) {}
  }

  static String _formatEntry(_LogEntry entry) {
    final time = '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}:${entry.timestamp.second.toString().padLeft(2, '0')}';
    final tag = entry.tag != null ? '[${entry.tag}] ' : '';
    var line = '$time ${entry.level} $tag${entry.message}';
    if (entry.error != null) line += '\n   Error: ${entry.error}';
    if (entry.stack != null) line += '\n   Stack: ${entry.stack}';
    return line;
  }

  static List<_LogEntry> getRecentLogs({int count = 50}) {
    final start = _buffer.length > count ? _buffer.length - count : 0;
    return _buffer.sublist(start);
  }
}

class _LogEntry {
  final DateTime timestamp;
  final String level;
  final String? tag;
  final String message;
  final String? error;
  final String? stack;

  _LogEntry({
    required this.timestamp,
    required this.level,
    this.tag,
    required this.message,
    this.error,
    this.stack,
  });
}
