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

  @override
  Widget build(BuildContext context) {
    final c = widget.primary;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
          child: Column(children: [
            Row(children: [
              Expanded(child: ElevatedButton.icon(
                onPressed: _working ? null : _create,
                icon: _working ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_alt_rounded, size: 18),
                label: const Text('إنشاء نسخة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(backgroundColor: c, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              )),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton.icon(
                onPressed: _openFolder,
                icon: const Icon(Icons.folder_open_rounded, size: 18),
                label: const Text('فتح المجلد', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.blue.shade700, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: BorderSide(color: Colors.blue.shade200)),
              )),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton.icon(
                onPressed: _restore,
                icon: const Icon(Icons.restore_rounded, size: 18),
                label: const Text('استعادة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.orange.shade800, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: BorderSide(color: Colors.orange.shade200)),
              )),
            ]),
          ]),
        ),
        const SizedBox(height: 20),
        if (_loading)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
        else if (_backups.isEmpty)
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
            child: Column(children: [
              Icon(Icons.cloud_off_rounded, size: 40, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              const               Text('لا توجد نسخ احتياطية', style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF717171))),
            ]),
          )
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
    );
  }
}
