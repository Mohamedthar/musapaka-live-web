import 'dart:io';
import 'package:flutter/foundation.dart';

class EnvConfig {
  static final Map<String, String> _values = {};

  static Future<void> load() async {
    String content;

    try {
      if (kIsWeb) {
        throw UnsupportedError('Web platform uses bundled config');
      }

      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final envPaths = [
        File('$exeDir/.env'),
        File('$exeDir/data/flutter_assets/.env'),
        File('.env'),
      ];

      File? foundFile;
      for (final f in envPaths) {
        if (await f.exists()) {
          foundFile = f;
          break;
        }
      }

      if (foundFile == null) {
        throw FileSystemException('.env file not found in any search path');
      }

      content = await foundFile.readAsString();
    } catch (e) {
      throw Exception('فشل تحميل ملف البيئة .env: $e');
    }

    for (final line in content.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final eqIndex = trimmed.indexOf('=');
      if (eqIndex == -1) continue;
      final key = trimmed.substring(0, eqIndex).trim();
      final value = trimmed.substring(eqIndex + 1).trim();
      _values[key] = value;
    }
  }

  static String get(String key) => _values[key] ?? '';
}
