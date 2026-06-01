import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/student.dart';
import '../../data/models/competition_level.dart';
import '../../services/supabase_service.dart';

class BackupService {
  final SupabaseService _service = SupabaseService();

  Future<File> createBackup() async {
    final students = await _service.getAllStudents();

    final backupData = {
      'version': '1.0',
      'created_at': DateTime.now().toIso8601String(),
      'app_name': 'مسابقة القرآن',
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
    final backupFile = await createBackup();
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'حفظ النسخة الاحتياطية',
      fileName: 'musapaka_backup_${DateTime.now().millisecondsSinceEpoch}.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null) {
      final savedFile = File(result);
      await savedFile.writeAsString(await backupFile.readAsString(), encoding: utf8);
      return savedFile;
    }
    return null;
  }

  Future<Map<String, dynamic>?> pickBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'اختر ملف النسخة الاحتياطية',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.isEmpty) return null;

    final path = result.files.single.path;
    if (path == null) return null;
    final file = File(path);
    final content = await file.readAsString(encoding: utf8);
    return jsonDecode(content) as Map<String, dynamic>;
  }

  Future<int> restoreFromFile(Map<String, dynamic> backupData) async {
    final studentsJson = backupData['students'] as List<dynamic>?;
    if (studentsJson == null || studentsJson.isEmpty) return 0;

    final students = studentsJson
        .map((json) => Student.fromJson(json as Map<String, dynamic>))
        .toList();

    int restoredCount = 0;
    for (final student in students) {
      try {
        await _service.createStudent(student);
        restoredCount++;
      } catch (_) {
        // skip existing
      }
    }
    return restoredCount;
  }
}
