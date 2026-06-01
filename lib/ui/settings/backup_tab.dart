import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/backup_service.dart';

class BackupTab extends StatefulWidget {
  final Color primary;
  final VoidCallback onRestored;
  const BackupTab({super.key, required this.primary, required this.onRestored});
  @override BackupTabState createState() => BackupTabState();
}

class BackupTabState extends State<BackupTab> {
  final BackupService _b = BackupService();
  List<BackupInfo> _backups = [];
  bool _loading = true;
  bool _working = false;

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    _backups = await _b.listExistingBackups();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> createBackup() async {
    setState(() => _working = true);
    try {
      await _b.createBackup(includeImages: true);
      if (mounted) { AppTheme.showSnack(context, 'تم إنشاء النسخة الاحتياطية'); _load(); }
    } catch (e) { if (mounted) AppTheme.showError(context, e); }
    finally { if (mounted) setState(() => _working = false); }
  }

  Future<void> openFolder() async {
    await _b.saveToCustomLocation();
    if (mounted) { AppTheme.showSnack(context, 'تم فتح مجلد النسخ'); _load(); }
  }

  Future<void> restoreBackup() async {
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
    final items = [
      _StatItem(Icons.save_rounded, '', 'نسخة', const Color(0xFF735C00)),
      _StatItem(Icons.access_time_rounded, _lastBackup, 'آخر نسخة', const Color(0xFF2563EB)),
      _StatItem(Icons.storage_rounded, _totalSize, 'الحجم', const Color(0xFF0D9488)),
      _StatItem(Icons.image_rounded, '$_totalImages', 'صورة', Colors.deepOrange.shade400),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(builder: (ctx, constraints) {
          final cols = constraints.maxWidth > 700 ? items.length : 2;
          final w = (constraints.maxWidth - (cols - 1) * 10) / cols;
          return Wrap(spacing: 10, runSpacing: 10, children: items.map((s) => SizedBox(
            width: w,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: s.color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: s.color.withValues(alpha: 0.1)),
                boxShadow: [BoxShadow(color: s.color.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(color: s.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(s.icon, color: s.color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(s.label, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                Text(s.value,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF03121C))),
              ]),
            ),
          )).toList());
        }),
        const SizedBox(height: 20),
        if (_loading)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
        else if (_backups.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Text('لا توجد نسخ احتياطية', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.grey.shade500)),
            ),
          )
        else
          ..._backups.take(10).map((b) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade100)),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: c.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.description_outlined, size: 18, color: Color(0xFF03121C)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    '${b.studentCount} متسابق  ·  ${b.levelCount} مستوى${b.imageCount > 0 ? '  ·  ${b.imageCount} صورة' : ''}',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${b.sizeFormatted}  ·  ${b.createdAt.toString().substring(0, 16).replaceAll('T', ' ')}',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey.shade500),
                  ),
                ]),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red.shade300),
                onPressed: () => _delete(b),
                splashRadius: 16,
              ),
            ]),
          )),
      ],
    );
  }
}

class _StatItem {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatItem(this.icon, this.value, this.label, this.color);
}
