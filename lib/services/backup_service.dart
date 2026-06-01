import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/student.dart';
import '../data/models/competition_level.dart';
import '../services/supabase_service.dart';
import '../core/error/error_handler.dart';
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
    final content = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final students = content['students'] as List? ?? [];
    final levels = content['levels'] as List? ?? [];
    return BackupInfo(
      path: file.path,
      sizeBytes: size,
      createdAt: DateTime.tryParse(content['created_at']?.toString() ?? '') ?? file.lastModifiedSync(),
      studentCount: students.length,
      levelCount: levels.length,
    );
  }
}

class BackupService {
  final SupabaseService _service = SupabaseService();
  static const String _autoBackupKey = 'last_auto_backup';
  static const Duration _autoBackupInterval = Duration(hours: 24);

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}_${d.hour.toString().padLeft(2, '0')}${d.minute.toString().padLeft(2, '0')}';
  }

  Future<File> createBackup({bool includeSettings = true}) async {
    AppLogger.info('Starting backup creation', tag: 'backup');

    final results = await Future.wait([
      _service.getAllStudents(),
      _service.getLevels(),
    ]);

    final students = results[0] as List<Student>;
    final levels = results[1] as List<CompetitionLevel>;

    Map<String, dynamic>? settings;
    if (includeSettings) {
      try {
        settings = await _service.getSettings();
      } catch (_) {}
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
    final dir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${dir.path}/musapaka_backups');
    if (!await backupDir.exists()) await backupDir.create(recursive: true);

    final filename = 'musapaka_backup_${_formatDate(DateTime.now())}.json';
    final file = File('${backupDir.path}/$filename');
    await file.writeAsString(json, encoding: utf8);

    AppLogger.info('Backup created: $filename (${(file.lengthSync() / 1024).toStringAsFixed(1)} KB)', tag: 'backup');
    return file;
  }

  Future<File?> saveToCustomLocation() async {
    try {
      final file = await createBackup();
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'حفظ النسخة الاحتياطية',
        fileName: file.uri.pathSegments.last,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (savePath != null) {
        final saved = File(savePath);
        await saved.writeAsBytes(await file.readAsBytes(), flush: true);
        return saved;
      }
      return file;
    } catch (e) {
      debugPrint('Save dialog failed, saving locally: $e');
      return await createBackup();
    }
  }

  Future<Map<String, dynamic>?> pickBackupFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'اختر ملف النسخة الاحتياطية',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return null;
      final path = result.files.single.path;
      if (path == null) return null;
      final content = await File(path).readAsString(encoding: utf8);
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Failed to pick backup file', tag: 'backup', error: e);
      return null;
    }
  }

  Future<int> restoreFromFile(Map<String, dynamic> backupData) async {
    AppLogger.info('Starting restore', tag: 'backup');
    final studentsJson = backupData['students'] as List<dynamic>? ?? [];
    final levelsJson = backupData['levels'] as List<dynamic>? ?? [];
    final settings = backupData['settings'] as Map<String, dynamic>?;

    int restored = 0;

    for (final l in levelsJson) {
      try {
        final level = CompetitionLevel.fromJson(l as Map<String, dynamic>);
        await _service.createLevel(level);
        restored++;
      } catch (_) {}
    }

    for (final s in studentsJson) {
      try {
        final student = Student.fromJson(s as Map<String, dynamic>);
        await _service.createStudent(student);
        restored++;
      } catch (_) {}
    }

    if (settings != null) {
      try {
        await _service.updateSettings(settings);
      } catch (_) {}
    }

    return restored;
  }

  Future<List<BackupInfo>> listExistingBackups() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${dir.path}/musapaka_backups');
      if (!await backupDir.exists()) return [];

      final files = backupDir.listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList();
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      return files.map((f) => BackupInfo.fromFile(f)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> deleteBackup(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<DateTime?> getLastBackupDate() async {
    final backups = await listExistingBackups();
    if (backups.isEmpty) return null;
    return backups.first.createdAt;
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
      try {
        return await createBackup();
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
