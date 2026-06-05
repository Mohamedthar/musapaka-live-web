import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
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
  final int imageCount;

  BackupInfo({
    required this.path,
    required this.sizeBytes,
    required this.createdAt,
    required this.studentCount,
    required this.levelCount,
    this.imageCount = 0,
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
        imageCount: data['image_count'] as int? ?? 0,
      );
    } catch (_) {
      return BackupInfo(path: file.path, sizeBytes: size, createdAt: file.lastModifiedSync(), studentCount: 0, levelCount: 0);
    }
  }
}

class BackupProgress {
  final int total;
  final int done;
  final String? currentFile;
  const BackupProgress({required this.total, required this.done, this.currentFile});
  double get percent => total > 0 ? done / total : 0;
}

class BackupService {
  final SupabaseService _service = SupabaseService();
  static const String _autoBackupKey = 'last_auto_backup';
  static const String _backupDirPrefKey = 'backup_directory_path';
  static const Duration _autoBackupInterval = Duration(hours: 24);

  String _backupDirPath = '';

  Future<String> get _backupDir async {
    if (_backupDirPath.isNotEmpty) return _backupDirPath;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_backupDirPrefKey);
    if (saved != null && saved.isNotEmpty) {
      _backupDirPath = saved;
      final d = Directory(_backupDirPath);
      if (!await d.exists()) await d.create(recursive: true);
      return _backupDirPath;
    }
    final dir = await getApplicationDocumentsDirectory();
    _backupDirPath = '${dir.path}/musapaka_backups';
    final d = Directory(_backupDirPath);
    if (!await d.exists()) await d.create(recursive: true);
    return _backupDirPath;
  }

  Future<void> setBackupDir(String path) async {
    final d = Directory(path);
    if (!await d.exists()) await d.create(recursive: true);
    _backupDirPath = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backupDirPrefKey, path);
  }

  Future<String> getBackupDirPath() async => await _backupDir;

  Future<String> get _imagesDir async {
    final dir = '${await _backupDir}/images';
    final d = Directory(dir);
    if (!await d.exists()) await d.create(recursive: true);
    return dir;
  }

  String _sanitize(String s) {
    return s.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}_${d.hour.toString().padLeft(2, '0')}${d.minute.toString().padLeft(2, '0')}';
  }

  Future<Uint8List?> _downloadImage(String? url) async {
    if (url == null || url.isEmpty || url.contains('placehold')) return null;
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return response.bodyBytes;
      return null;
    } catch (_) { return null; }
  }

  Future<int> _downloadStudentImages(Student student, String backupFolderName) async {
    final safeName = _sanitize(student.name);
    final folderName = '${safeName}_${student.id ?? ''}';
    final dir = Directory('${await _imagesDir}/$backupFolderName/$folderName');
    if (!await dir.exists()) await dir.create(recursive: true);

    int count = 0;

    final profile = await _downloadImage(student.profileImageUrl);
    if (profile != null) {
      await File('${dir.path}/profile.jpg').writeAsBytes(profile);
      count++;
    }

    final birth = await _downloadImage(student.birthCertificateUrl);
    if (birth != null) {
      await File('${dir.path}/birth_certificate.jpg').writeAsBytes(birth);
      count++;
    }

    return count;
  }

  Future<File> createBackup({
    bool includeSettings = true,
    bool includeImages = true,
    void Function(BackupProgress)? onProgress,
  }) async {
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

    int totalImages = 0;
    final backupFolderName = _formatDate(DateTime.now());

    if (includeImages) {
      final studentsWithImages = students.where((s) =>
        (s.profileImageUrl != null && s.profileImageUrl!.isNotEmpty) ||
        (s.birthCertificateUrl != null && s.birthCertificateUrl!.isNotEmpty)
      ).toList();

      for (int i = 0; i < studentsWithImages.length; i++) {
        onProgress?.call(BackupProgress(total: studentsWithImages.length, done: i, currentFile: studentsWithImages[i].name));
        totalImages += await _downloadStudentImages(studentsWithImages[i], backupFolderName);
      }
      onProgress?.call(BackupProgress(total: studentsWithImages.length, done: studentsWithImages.length));
    }

    final backupData = {
      'version': '3.0',
      'created_at': DateTime.now().toIso8601String(),
      'total_students': students.length,
      'total_levels': levels.length,
      'image_count': totalImages,
      'images_folder': backupFolderName,
      'students': students.map((s) => s.toJson()).toList(),
      'levels': levels.map((l) => l.toJson()).toList(),
      if (settings != null) 'settings': settings,
    };

    final json = const JsonEncoder.withIndent('  ').convert(backupData);
    final dir = await _backupDir;
    final filename = 'musapaka_backup_$backupFolderName.json';
    final file = File('$dir/$filename');
    await file.writeAsString(json, encoding: utf8);
    AppLogger.info('Backup saved: $filename ($totalImages images)', tag: 'backup');
    return file;
  }

  Future<File?> saveToCustomLocation() async {
    final file = await createBackup(includeImages: false);
    try {
      await Process.run('explorer.exe', [await _backupDir]);
    } catch (_) {}
    return file;
  }

  Future<Map<String, dynamic>?> pickBackupFile() async {
    final backups = await listExistingBackups();
    if (backups.isEmpty) return null;
    try {
      await Process.run('explorer.exe', [await _backupDir]);
    } catch (_) {}
    return null;
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
    try {
      final file = File(path);
      final info = BackupInfo.fromFile(file);
      final backupData = jsonDecode(await file.readAsString(encoding: utf8)) as Map<String, dynamic>;
      await file.delete();
      if (info.imageCount > 0) {
        final folder = backupData['images_folder'] as String?;
        if (folder != null) {
          final imgDir = Directory('${await _imagesDir}/$folder');
          if (await imgDir.exists()) await imgDir.delete(recursive: true);
        }
      }
      return true;
    } catch (_) { return false; }
  }

  Future<int> getTotalImageSize() async {
    try {
      final d = Directory(await _imagesDir);
      if (!await d.exists()) return 0;
      int total = 0;
      for (final entity in d.listSync(recursive: true)) {
        if (entity is File) total += entity.lengthSync();
      }
      return total;
    } catch (_) { return 0; }
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
      try { return await createBackup(includeImages: true); } catch (_) { return null; }
    }
    return null;
  }
}
