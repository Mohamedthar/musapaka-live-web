import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../../data/models/student.dart';
import '../../services/supabase_service.dart';

class BackupService {
  final SupabaseService _service = SupabaseService();

  Future<File> createBackup() async {
    final students = await _service.getAllStudents();
    final backupData = {
      'version': '1.0',
      'created_at': DateTime.now().toIso8601String(),
      'students': students.map((s) => s.toJson()).toList(),
    };
    final json = const JsonEncoder.withIndent('  ').convert(backupData);
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/musapaka_backup_$timestamp.json');
    await file.writeAsString(json, encoding: utf8);
    return file;
  }

  Future<File?> exportBackupToFile() async {
    try { return await createBackup(); } catch (_) { return null; }
  }

  Future<Map<String, dynamic>?> pickBackupFile() async {
    return null;
  }

  Future<int> restoreFromFile(Map<String, dynamic> backupData) async {
    final studentsJson = backupData['students'] as List<dynamic>?;
    if (studentsJson == null || studentsJson.isEmpty) return 0;
    final students = studentsJson.map((j) => Student.fromJson(j as Map<String, dynamic>)).toList();
    int count = 0;
    for (final s in students) {
      try { await _service.createStudent(s); count++; } catch (_) {}
    }
    return count;
  }
}
