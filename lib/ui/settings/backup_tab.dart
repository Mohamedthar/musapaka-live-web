import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/backup_service.dart';

class BackupTab extends StatefulWidget {
  final Color primary;
  final VoidCallback onRestored;
  const BackupTab({required this.primary, required this.onRestored});
  @override State<BackupTab> createState() => _BackupTabState();
}

class _BackupTabState extends State<BackupTab> {
  final BackupService _b = BackupService();
  List<BackupInfo> _backups = [];
  bool _loading = true;
  bool _working = false;

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    _backups = await _b.listExistingBackups();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _create() async {
    setState(() => _working = true);
    try {
      await _b.createBackup(includeImages: true);
      if (mounted) { AppTheme.showSnack(context, 'تم إنشاء النسخة الاحتياطية'); _load(); }
    } catch (e) { if (mounted) AppTheme.showError(context, e); }
    finally { if (mounted) setState(() => _working = false); }
  }

  Future<void> _openFolder() async {
    await _b.saveToCustomLocation();
    if (mounted) { AppTheme.showSnack(context, 'تم فتح مجلد النسخ'); _load(); }
  }

  Future<void> _restore() async {
    if (_backups.isEmpty) { AppTheme.showSnack(context, 'لا توجد نسخ'); return; }
    final b = _backups.first;
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('استعادة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800)),
      content: Text('استعادة ${b.studentCount} متسابق و ${b.levelCount} مستوى؟', style: const TextStyle(fontFamily: 'Cairo')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(_, false), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
        ElevatedButton(onPressed: () => Navigator.pop(_, true), style: ElevatedButton.styleFrom(backgroundColor: widget.primary), child: const Text('استعادة', style: TextStyle(fontFamily: 'Cairo', color: Colors.white))),
      ],
    ));
    if (ok != true || !mounted) return;
    setState(() => _working = true);
    try {
      final d = jsonDecode(await File(b.path).readAsString(encoding: utf8)) as Map<String, dynamic>;
      final n = await _b.restoreFromFile(d);
      if (mounted) { AppTheme.showSnack(context, 'تم استعادة $n عنصر'); widget.onRestored(); _load(); }
    } catch (e) { if (mounted) AppTheme.showError(context, e); }
    finally { if (mounted) setState(() => _working = false); }
  }

  Future<void> _delete(BackupInfo b) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('حذف', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800)),
      content: Text('${b.createdAt.toString().substring(0, 16)} ؟', style: const TextStyle(fontFamily: 'Cairo')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(_, false), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
        ElevatedButton(onPressed: () => Navigator.pop(_, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo', color: Colors.white))),
      ],
    ));
    if (ok == true && mounted) { await _b.deleteBackup(b.path); _load(); }
  }

  String get _lastBackup {
    if (_backups.isEmpty) return 'لا يوجد';
    final diff = DateTime.now().difference(_backups.first.createdAt);
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    return 'منذ ${diff.inDays} يوم';
  }
  int get _totalImages => _backups.fold(0, (s, b) => s + b.imageCount);
  String get _totalSize {
    final bytes = _backups.fold<int>(0, (s, b) => s + b.sizeBytes);
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.primary;
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
          child: Row(children: [
            _tb(Icons.add_circle_outline, 'إنشاء نسخة', const Color(0xFF03121C), _working, _create),
            const SizedBox(width: 6),
            _tb(Icons.folder_open, 'فتح المجلد', const Color(0xFF2563EB), false, _openFolder),
            const SizedBox(width: 6),
            _tb(Icons.history, 'استعادة', const Color(0xFFC2410C), false, _restore),
            const Spacer(),
            IconButton(icon: const Icon(Icons.refresh_rounded, size: 18), onPressed: _load, splashRadius: 16, color: Colors.grey.shade500),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: _stat(Icons.save_rounded, '${_backups.length}', 'نسخة', c)),
              const SizedBox(width: 10),
              Expanded(child: _stat(Icons.access_time_rounded, _lastBackup, 'آخر نسخة', Colors.blue.shade600)),
              const SizedBox(width: 10),
              Expanded(child: _stat(Icons.storage_rounded, _totalSize, 'الحجم', Colors.teal.shade600)),
              const SizedBox(width: 10),
              Expanded(child: _stat(Icons.image_rounded, '$_totalImages', 'صورة', Colors.deepOrange.shade400)),
            ]),
            const SizedBox(height: 20),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else if (_backups.isEmpty)
              Center(child: Padding(padding: const EdgeInsets.all(30), child: Text('لا توجد نسخ احتياطية', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.grey.shade500))))
            else
              ..._backups.take(10).map((b) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade100)),
                child: Row(children: [
                  Container(width: 40, height: 40, decoration: BoxDecoration(color: c.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.description_outlined, size: 18, color: Color(0xFF03121C))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${b.studentCount} متسابق  ·  ${b.levelCount} مستوى${b.imageCount > 0 ? '  ·  ${b.imageCount} صورة' : ''}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w700)),
                    Text('${b.sizeFormatted}  ·  ${b.createdAt.toString().substring(0, 16).replaceAll('T', ' ')}', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey.shade500)),
                  ])),
                  IconButton(icon: Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red.shade300), onPressed: () => _delete(b), splashRadius: 16),
                ]),
              )),
          ]),
        ),
      ]),
    );
  }

  Widget _tb(IconData icon, String label, Color color, bool disabled, VoidCallback onTap) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.15))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          disabled ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
      child: Column(children: [
        Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 16, color: color)),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF03121C))),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.grey.shade500)),
      ]),
    );
  }
}
