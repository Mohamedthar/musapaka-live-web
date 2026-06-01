import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/backup_service.dart';

// ── Backup Tab ──
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
  BackupProgress? _progress;

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() => _loading = true);
    _backups = await _b.listExistingBackups();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _create() async {
    setState(() { _working = true; _progress = null; });
    try {
      await _b.createBackup(includeImages: true, onProgress: (p) { if (mounted) setState(() => _progress = p); });
      if (mounted) { AppTheme.showSnack(context, 'تم إنشاء النسخة مع الصور'); _load(); }
    } catch (e) { if (mounted) AppTheme.showError(context, e); }
    finally { if (mounted) setState(() { _working = false; _progress = null; }); }
  }

  Future<void> _openFolder() async {
    setState(() => _working = true);
    await _b.saveToCustomLocation();
    if (mounted) { AppTheme.showSnack(context, 'تم فتح مجلد النسخ الاحتياطي'); _load(); }
    if (mounted) setState(() => _working = false);
  }

  Future<void> _restoreFromList() async {
    await _load();
    if (_backups.isEmpty) { AppTheme.showSnack(context, 'لا توجد نسخ'); return; }
    final pick = await showDialog<BackupInfo>(context: context, builder: (_) => AlertDialog(
      backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('اختر النسخة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800)),
      content: SizedBox(width: 420, child: ListView.builder(shrinkWrap: true, itemCount: _backups.length, itemBuilder: (_, i) {
        final b = _backups[i];
        return Container(margin: const EdgeInsets.only(bottom: 6), decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)), child: ListTile(
          leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: widget.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.save_rounded, size: 18, color: widget.primary)),
          title: Text('${b.studentCount} متسابق  ·  ${b.levelCount} مستوى${b.imageCount > 0 ? '  ·  ${b.imageCount} صورة' : ''}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w700)),
          subtitle: Text('${b.sizeFormatted}  ·  ${b.createdAt.toString().substring(0, 16).replaceAll('T', ' ')}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11)),
          onTap: () => Navigator.pop(_, b),
        ));
      })),
      actions: [TextButton(onPressed: () => Navigator.pop(_), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')))],
    ));
    if (pick == null || !mounted) return;
    setState(() => _working = true);
    try {
      final data = jsonDecode(await File(pick.path).readAsString(encoding: utf8)) as Map<String, dynamic>;
      AppTheme.showSnack(context, 'جاري استعادة ${pick.studentCount} متسابق...');
      final n = await _b.restoreFromFile(data);
      if (mounted) { AppTheme.showSnack(context, 'تم استعادة $n عنصر'); widget.onRestored(); _load(); }
    } catch (e) { if (mounted) AppTheme.showError(context, e); }
    finally { if (mounted) setState(() => _working = false); }
  }

  Future<void> _delete(BackupInfo b) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('حذف النسخة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800)),
      content: Text('${b.createdAt.toString().substring(0, 16)} ؟\n${b.studentCount} متسابق  ·  ${b.sizeFormatted}', style: const TextStyle(fontFamily: 'Cairo')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(_, false), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
        ElevatedButton(onPressed: () => Navigator.pop(_, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600), child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo', color: Colors.white))),
      ],
    ));
    if (ok == true && mounted) { await _b.deleteBackup(b.path); _load(); }
  }

  String get _lastBackup {
    if (_backups.isEmpty) return 'لا يوجد';
    final diff = DateTime.now().difference(_backups.first.createdAt);
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    return 'منذ ${diff.inDays} ي';
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // ── Stats ──
        Row(children: [
          Expanded(child: _stat(Icons.save_rounded, '${_backups.length}', 'نسخة', c)),
          const SizedBox(width: 10),
          Expanded(child: _stat(Icons.access_time_rounded, _lastBackup, 'آخر نسخة', Colors.blue.shade600)),
          const SizedBox(width: 10),
          Expanded(child: _stat(Icons.storage_rounded, _totalSize, 'الحجم الكلي', Colors.teal.shade600)),
          const SizedBox(width: 10),
          Expanded(child: _stat(Icons.image_rounded, '$_totalImages', 'صورة', Colors.deepOrange.shade400)),
        ]),
        const SizedBox(height: 24),

        if (_progress != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blue.shade100)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5)),
                const SizedBox(width: 12),
                Text('جاري تحميل الصور: ${_progress!.done} / ${_progress!.total}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w700)),
              ]),
              if (_progress!.currentFile != null) Padding(padding: const EdgeInsets.only(top: 6, right: 30), child: Text(_progress!.currentFile!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey.shade600))),
              const SizedBox(height: 8),
              ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: _progress!.percent, backgroundColor: Colors.blue.shade100, color: Colors.blue.shade600, minHeight: 4)),
            ]),
          ),

        // ── Actions ──
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: c.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.cloud_sync_rounded, size: 18, color: c)),
              const SizedBox(width: 10),
              const Text('النسخ الاحتياطي', style: TextStyle(fontFamily: 'Cairo', fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF03121C))),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _btn(Icons.add_circle_outline_rounded, 'إنشاء نسخة كاملة', 'البيانات + الصور', c, _create)),
              const SizedBox(width: 10),
              Expanded(child: _btn(Icons.folder_open_rounded, 'فتح مجلد النسخ', 'استعراض الملفات', Colors.blue.shade600, _openFolder)),
              const SizedBox(width: 10),
              Expanded(child: _btn(Icons.history_rounded, 'استعادة نسخة', 'اختر من القائمة', Colors.orange.shade700, _restoreFromList)),
            ]),
          ]),
        ),
        const SizedBox(height: 24),

        // ── List ──
        if (_loading)
          const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()))
        else if (_backups.isNotEmpty) ...[
          Row(children: [
            Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: c.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.history_rounded, size: 18, color: c)),
            const SizedBox(width: 10),
            Text('النسخ: ${_backups.length}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF03121C))),
          ]),
          const SizedBox(height: 12),
          ..._backups.take(10).map((b) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 6)]),
            child: Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: c.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.description_outlined, size: 18, color: Color(0xFF03121C))),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${b.studentCount} متسابق  ·  ${b.levelCount} مستوى${b.imageCount > 0 ? '  ·  ${b.imageCount} صورة' : ''}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF03121C))),
                const SizedBox(height: 2),
                Text('${b.sizeFormatted}  ·  ${b.createdAt.toString().substring(0, 16).replaceAll('T', ' ')}', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey.shade500)),
              ])),
              Column(children: [
                IconButton(icon: const Icon(Icons.restore_rounded, size: 18, color: Color(0xFF03121C)), onPressed: () async {
                  final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                    backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Text('استعادة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800)),
                    content: Text('استعادة ${b.studentCount} متسابق من هذه النسخة؟', style: const TextStyle(fontFamily: 'Cairo')),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(_, false), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
                      ElevatedButton(onPressed: () => Navigator.pop(_, true), style: ElevatedButton.styleFrom(backgroundColor: c), child: const Text('استعادة', style: TextStyle(fontFamily: 'Cairo', color: Colors.white))),
                    ],
                  ));
                  if (ok == true && mounted) {
                    setState(() => _working = true);
                    try {
                      final data = jsonDecode(await File(b.path).readAsString(encoding: utf8)) as Map<String, dynamic>;
                      final n = await _b.restoreFromFile(data);
                      if (mounted) { AppTheme.showSnack(context, 'تم استعادة $n عنصر'); widget.onRestored(); _load(); }
                    } catch (e) { if (mounted) AppTheme.showError(context, e); }
                    finally { if (mounted) setState(() => _working = false); }
                  }
                }, splashRadius: 16, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
                IconButton(icon: Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red.shade300), onPressed: () => _delete(b), splashRadius: 16, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
              ]),
            ]),
          )),
        ],
      ]),
    );
  }

  Widget _stat(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8)]),
      child: Column(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 18, color: color)),
        const SizedBox(height: 10),
        Text(value, style: const TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF03121C))),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.grey.shade500)),
      ]),
    );
  }

  Widget _btn(IconData icon, String title, String sub, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.white, borderRadius: BorderRadius.circular(14),
      child: InkWell(onTap: _working ? null : onTap, borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200), gradient: _working ? null : LinearGradient(colors: [Colors.white, color.withValues(alpha: 0.03)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
          child: Column(children: [
            _working ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5)) : Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, size: 22, color: color)),
            const SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF03121C))),
            const SizedBox(height: 3),
            Text(sub, textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: Colors.grey.shade500, height: 1.3)),
          ]),
        ),
      ),
    );
  }
}
