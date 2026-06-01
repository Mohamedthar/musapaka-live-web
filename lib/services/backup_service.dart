import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/student.dart';
import '../data/models/competition_level.dart';
import '../services/supabase_service.dart';
import '../core/utils/app_logger.dart';

class BackupInfo {
  final String path;
  final int sizeBytes;
  final DateTime createdAt;
  final int studentCount;
  final int levelCount;

  BackupInfo({
    required this.path,
    required this.sizeBytes,
    required this.createdAt,
    required this.studentCount,
    required this.levelCount,
  });

  String get sizeFormatted {
    if (sizeBytes < 1024) return '$sizeBytes بايت';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} كيلوبايت';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} ميجابايت';
  }

  factory BackupInfo.fromFile(File file) {
    final size = file.lengthSync();
    String content;
    try {
      content = file.readAsStringSync();
    } catch (_) {
      return BackupInfo(path: file.path, sizeBytes: size, createdAt: file.lastModifiedSync(), studentCount: 0, levelCount: 0);
    }
    try {
      final data = jsonDecode(content) as Map<String, dynamic>;
      final students = data['students'] as List? ?? [];
      final levels = data['levels'] as List? ?? [];
      return BackupInfo(
        path: file.path,
        sizeBytes: size,
        createdAt: DateTime.tryParse(data['created_at']?.toString() ?? '') ?? file.lastModifiedSync(),
        studentCount: students.length,
        levelCount: levels.length,
      );
    } catch (_) {
      return BackupInfo(path: file.path, sizeBytes: size, createdAt: file.lastModifiedSync(), studentCount: 0, levelCount: 0);
    }
  }
}

class BackupService {
  final SupabaseService _service = SupabaseService();
  static const String _autoBackupKey = 'last_auto_backup';
  static const Duration _autoBackupInterval = Duration(hours: 24);

  String _backupDirPath = '';

  Future<String> get _backupDir async {
    if (_backupDirPath.isNotEmpty) return _backupDirPath;
    final dir = await getApplicationDocumentsDirectory();
    _backupDirPath = '${dir.path}/musapaka_backups';
    final d = Directory(_backupDirPath);
    if (!await d.exists()) await d.create(recursive: true);
    return _backupDirPath;
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}_${d.hour.toString().padLeft(2, '0')}${d.minute.toString().padLeft(2, '0')}';
  }

  Future<File> createBackup({bool includeSettings = true}) async {
    AppLogger.info('Starting backup', tag: 'backup');

    final results = await Future.wait([
      _service.getAllStudents(),
      _service.getLevels(),
    ]);

    final students = results[0] as List<Student>;
    final levels = results[1] as List<CompetitionLevel>;

    Map<String, dynamic>? settings;
    if (includeSettings) {
      try { settings = await _service.getSettings(); } catch (_) {}
    }

    final backupData = {
      'version': '2.0',
      'created_at': DateTime.now().toIso8601String(),
      'total_students': students.length,
      'total_levels': levels.length,
      'students': students.map((s) => s.toJson()).toList(),
      'levels': levels.map((l) => l.toJson()).toList(),
      if (settings != null) 'settings': settings,
    };

    final json = const JsonEncoder.withIndent('  ').convert(backupData);
    final dir = await _backupDir;
    final filename = 'musapaka_backup_${_formatDate(DateTime.now())}.json';
    final file = File('$dir/$filename');
    await file.writeAsString(json, encoding: utf8);
    AppLogger.info('Backup saved: $filename', tag: 'backup');
    return file;
  }

  Future<File?> saveToCustomLocation() async {
    return await createBackup();
  }

  Future<Map<String, dynamic>?> pickBackupFile() async {
    try {
      final backups = await listExistingBackups();
      if (backups.isEmpty) return null;
      return jsonDecode(await File(backups.first.path).readAsString(encoding: utf8)) as Map<String, dynamic>;
    } catch (_) { return null; }
  }

  Future<int> restoreFromFile(Map<String, dynamic> backupData) async {
    AppLogger.info('Restoring backup', tag: 'backup');
    final studentsJson = backupData['students'] as List<dynamic>? ?? [];
    final levelsJson = backupData['levels'] as List<dynamic>? ?? [];
    final settings = backupData['settings'] as Map<String, dynamic>?;
    int restored = 0;

    for (final l in levelsJson) {
      try { await _service.createLevel(CompetitionLevel.fromJson(l as Map<String, dynamic>)); restored++; } catch (_) {}
    }
    for (final s in studentsJson) {
      try { await _service.createStudent(Student.fromJson(s as Map<String, dynamic>)); restored++; } catch (_) {}
    }
    if (settings != null) {
      try { await _service.updateSettings(settings); } catch (_) {}
    }
    return restored;
  }

  Future<List<BackupInfo>> listExistingBackups() async {
    try {
      final d = Directory(await _backupDir);
      if (!await d.exists()) return [];
      final files = d.listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList();
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      return files.map((f) => BackupInfo.fromFile(f)).toList();
    } catch (_) { return []; }
  }

  Future<bool> deleteBackup(String path) async {
    try { await File(path).delete(); return true; } catch (_) { return false; }
  }

  Future<DateTime?> getLastBackupDate() async {
    final backups = await listExistingBackups();
    return backups.isEmpty ? null : backups.first.createdAt;
  }

  Future<bool> shouldAutoBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString(_autoBackupKey);
    if (last == null) return true;
    final lastDate = DateTime.tryParse(last);
    if (lastDate == null) return true;
    return DateTime.now().difference(lastDate) > _autoBackupInterval;
  }

  Future<File?> autoBackupIfNeeded() async {
    if (await shouldAutoBackup()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_autoBackupKey, DateTime.now().toIso8601String());
      try { return await createBackup(); } catch (_) { return null; }
    }
    return null;
  }
}
