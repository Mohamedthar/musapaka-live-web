import 'package:flutter/material.dart';
import '../../data/models/competition_level.dart';
import '../../data/models/student.dart';
import '../../services/supabase_service.dart';
import '../../services/export_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../ui/shared/widgets/export_fields.dart';
import '../../ui/shared/widgets/confirm_dialog.dart';
import 'widgets/levels_top_bar.dart';
import 'widgets/levels_stats_cards.dart';
import 'widgets/levels_filter_bar.dart';
import 'widgets/levels_table.dart';
import 'widgets/levels_side_panel.dart';
import '../dashboard/widgets/resizable_panel.dart';

class LevelsScreen extends StatefulWidget {
  final Function(String)? onLevelSelected;
  const LevelsScreen({super.key, this.onLevelSelected});
  @override
  State<LevelsScreen> createState() => LevelsScreenState();
}

class LevelsScreenState extends State<LevelsScreen> {
  final _service = SupabaseService();
  List<CompetitionLevel> _levels = [];
  List<Student> _allStudents = [];
  Map<String, int> _studentCounts = {};
  bool _isLoading = true;
  bool _studentsLoaded = false;
  String _search = '';
  String _filterStatus = 'all';
  static const _primary = Color(0xFF03121C);

  final Set<int> _selectedIds = {};
  bool _showSidePanel = false;
  CompetitionLevel? _editingLevel;
  bool _isSaving = false;
  bool _bulkDeleting = false;
  bool _bulkUpdating = false;
  double _levelsPanelWidth = 460.0;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final levels = await _service.getLevels();
      final counts = await _service.getStudentsCountPerLevel();
      if (mounted) setState(() { _levels = levels; _studentCounts = counts; _isLoading = false; });
    } catch (e) {
      if (mounted) { setState(() => _isLoading = false); _snack('خطأ: $e', Colors.red); }
    }
  }

  Future<void> _loadStudents() async {
    if (_studentsLoaded) return;
    try {
      _allStudents = await _service.getAllStudents();
      if (mounted) setState(() => _studentsLoaded = true);
    } catch (_) {}
  }

  void _snack(String msg, [Color color = Colors.green]) {
    AppTheme.showSnack(context, msg, color: color);
  }

  void onToggleAddPanel() {
    _loadStudents();
    if (_showSidePanel && _editingLevel == null) {
      setState(() => _showSidePanel = false);
    } else {
      setState(() { _editingLevel = null; _showSidePanel = true; });
      if (ResponsiveUtils.isMobile(context)) _showSidePanelBottomSheet();
    }
  }

  void _onEditLevel(CompetitionLevel l) {
    _loadStudents();
    setState(() { _editingLevel = l; _showSidePanel = true; });
    if (ResponsiveUtils.isMobile(context)) _showSidePanelBottomSheet();
  }

  Future<void> _bulkDelete() async {
    if (_selectedIds.isEmpty) return;

    final selectedLevels = _levels.where((l) => l.id != null && _selectedIds.contains(l.id)).toList();

    setState(() => _bulkDeleting = true);
    final Map<CompetitionLevel, int> linkedStudents = {};
    try {
      for (final l in selectedLevels) {
        final count = await _service.getStudentsCountByLevel(l.title);
        if (count > 0) linkedStudents[l] = count;
      }
    } finally {
      setState(() => _bulkDeleting = false);
    }

    if (linkedStudents.isNotEmpty && mounted) {
      final msg = linkedStudents.entries.map((e) => '• ${e.key.title}: ${e.value} طالب').join('\n');
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Expanded(child: Text('لا يمكن الحذف', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('هذه المستويات مرتبط بها طلاب:', style: TextStyle(fontFamily: 'Cairo', fontSize: 14)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Text(msg, style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.red)),
            ),
            const SizedBox(height: 12),
            const Text('قم بتغيير مستوى الطلاب إلى مستوى آخر ثم حاول الحذف.', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.grey)),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('فهمت', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => const ConfirmDialog(
        title: 'تأكيد الحذف الجماعي',
        message: 'هل أنت متأكد من حذف كافة المستويات المحددة؟',
        confirmText: 'حذف الكل',
        confirmColor: Colors.red,
        icon: Icons.delete_sweep_rounded,
      ),
    );

    if (confirm == true) {
      setState(() => _bulkDeleting = true);
      try {
        if (_selectedIds.isNotEmpty) {
          await _service.deleteLevelsBatch(_selectedIds.toList());
        }
        _snack('تم الحذف بنجاح');
        _selectedIds.clear();
        _load();
      } catch (e) {
        _snack('خطأ أثناء الحذف: $e', Colors.red);
      } finally {
        setState(() => _bulkDeleting = false);
      }
    }
  }

  Future<void> _bulkUpdateStatus(bool isActive) async {
    if (_selectedIds.isEmpty) return;
    setState(() => _bulkUpdating = true);
    try {
      final ids = _selectedIds.toList();
      if (ids.isNotEmpty) {
        await _service.updateLevelsBatch(ids, {'is_active': isActive});
      }
      _snack(isActive ? 'تم تنشيط المستويات بنجاح' : 'تم تعطيل المستويات بنجاح');
      _selectedIds.clear();
      _load();
    } catch (e) {
      _snack('خطأ أثناء التحديث: $e', Colors.red);
    } finally {
      setState(() => _bulkUpdating = false);
    }
  }

  Future<void> _showExportExcelDialog() async {
    String status = 'all';
    final minAgeCtrl = TextEditingController();
    final maxAgeCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(children: [
          Icon(Icons.table_chart_rounded, color: Colors.green, size: 28),
          SizedBox(width: 12),
          Text('تصدير المستويات (Excel)', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        ]),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('حدد البيانات التي ترغب في إدراجها في التقرير:', style: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 20),

            const ExportFilterLabel(label: 'حالة المستوى'),
            Container(
              height: 48, padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200)
              ),
              child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                value: status, isExpanded: true, dropdownColor: Colors.white, borderRadius: BorderRadius.circular(16),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, color: _primary, fontWeight: FontWeight.w600),
                items: const [
                  DropdownMenuItem(value: 'all', child: Row(children: [Icon(Icons.filter_list_rounded, size: 18, color: Colors.grey), SizedBox(width: 10), Text('جميع المستويات')])),
                  DropdownMenuItem(value: 'active', child: Row(children: [Icon(Icons.check_circle_rounded, size: 18, color: Colors.green), SizedBox(width: 10), Text('النشطة فقط')])),
                  DropdownMenuItem(value: 'inactive', child: Row(children: [Icon(Icons.cancel_rounded, size: 18, color: Colors.red), SizedBox(width: 10), Text('المعطلة فقط')])),
                ],
                onChanged: (v) => setS(() => status = v ?? 'all'),
              )),
            ),
            const SizedBox(height: 16),

            const ExportFilterLabel(label: 'نطاق العمر المسموح'),
            Row(children: [
              Expanded(child: ExportNumberField(controller: minAgeCtrl, hintText: 'من عمر')),
              const SizedBox(width: 12),
              Expanded(child: ExportNumberField(controller: maxAgeCtrl, hintText: 'إلى عمر')),
            ]),
          ]),
        ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _exportExcel(
                status: status,
                minAge: int.tryParse(minAgeCtrl.text),
                maxAge: int.tryParse(maxAgeCtrl.text),
              );
            },
            child: const Text('تصدير الآن', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      )),
    );
  }

  Future<void> _exportExcel({String status = 'all', int? minAge, int? maxAge}) async {
    try {
      await _loadStudents();
      final exportService = ExportService();
      final bytes = await exportService.levelsToExcel(
        levels: _levels,
        allStudents: _allStudents,
        status: status,
        minAge: minAge,
        maxAge: maxAge,
      );
      final fileName = 'Levels_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final path = await exportService.saveFile(bytes, fileName, 'xlsx');
      if (path != null && mounted) _snack('تم تصدير Excel بنجاح ✓');
    } catch (e) {
      if (mounted) _snack('خطأ في التصدير: $e', Colors.red);
    }
  }

  Future<void> _showExportPDFDialog() async {
    String status = 'all';
    final minAgeCtrl = TextEditingController();
    final maxAgeCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(children: [
          Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 28),
          SizedBox(width: 12),
          Text('تصدير المستويات (PDF)', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        ]),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('حدد البيانات التي ترغب في إدراجها في ملف التقرير:', style: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 20),

            const ExportFilterLabel(label: 'حالة المستوى'),
            Container(
              height: 48, padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200)
              ),
              child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                value: status, isExpanded: true, dropdownColor: Colors.white, borderRadius: BorderRadius.circular(16),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, color: _primary, fontWeight: FontWeight.w600),
                items: const [
                  DropdownMenuItem(value: 'all', child: Row(children: [Icon(Icons.filter_list_rounded, size: 18, color: Colors.grey), SizedBox(width: 10), Text('جميع المستويات')])),
                  DropdownMenuItem(value: 'active', child: Row(children: [Icon(Icons.check_circle_rounded, size: 18, color: Colors.green), SizedBox(width: 10), Text('النشطة فقط')])),
                  DropdownMenuItem(value: 'inactive', child: Row(children: [Icon(Icons.cancel_rounded, size: 18, color: Colors.red), SizedBox(width: 10), Text('المعطلة فقط')])),
                ],
                onChanged: (v) => setS(() => status = v ?? 'all'),
              )),
            ),
            const SizedBox(height: 16),

            const ExportFilterLabel(label: 'نطاق العمر المسموح'),
            Row(children: [
              Expanded(child: ExportNumberField(controller: minAgeCtrl, hintText: 'من عمر')),
              const SizedBox(width: 12),
              Expanded(child: ExportNumberField(controller: maxAgeCtrl, hintText: 'إلى عمر')),
            ]),
          ]),
        ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _exportPDF(
                status: status,
                minAge: int.tryParse(minAgeCtrl.text),
                maxAge: int.tryParse(maxAgeCtrl.text),
              );
            },
            child: const Text('إصدار PDF', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      )),
    );
  }

  Future<void> _exportPDF({String status = 'all', int? minAge, int? maxAge}) async {
    try {
      await _loadStudents();
      final exportService = ExportService();
      final bytes = await exportService.levelsToPDF(
        levels: _levels,
        allStudents: _allStudents,
        status: status,
        minAge: minAge,
        maxAge: maxAge,
      );
      await exportService.printPdf(bytes);
    } catch (e) {
      if (mounted) _snack('خطأ في تصدير PDF: $e', Colors.red);
    }
  }

  void _showSidePanelBottomSheet() {
    final maxH = MediaQuery.of(context).size.height * 0.9;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        clipBehavior: Clip.hardEdge,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        constraints: BoxConstraints(maxHeight: maxH),
        child: LevelsSidePanel(
          level: _editingLevel,
          onClose: () => Navigator.pop(ctx),
          onSave: (l) async {
            setState(() => _isSaving = true);
            try {
              if (_editingLevel == null) {
                await _service.createLevel(l);
              } else {
                final id = _editingLevel!.id;
                if (id == null) { _snack('خطأ: لا يمكن تحديث مستوى بدون معرف', Colors.red); return; }
                await _service.updateLevel(id, l);
              }
              _snack('تم الحفظ بنجاح');
              _load();
              if (ctx.mounted) Navigator.pop(ctx);
              setState(() => _showSidePanel = false);
            } catch (e) { _snack('خطأ: $e', Colors.red); }
            finally { if (mounted) setState(() => _isSaving = false); }
          },
          isSaving: _isSaving,
          primaryColor: _primary,
        ),
      ),
    ).then((_) {
      if (mounted) setState(() => _showSidePanel = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenType = ResponsiveUtils.fromWidth(MediaQuery.of(context).size.width);
    final isMobile = screenType == ScreenType.mobile;
    final filtered = _levels.where((l) {
      final matchesSearch = l.title.toLowerCase().contains(_search.toLowerCase()) ||
                           l.content.toLowerCase().contains(_search.toLowerCase());
      final matchesStatus = _filterStatus == 'all' ||
                            (_filterStatus == 'active' && l.isActive) ||
                            (_filterStatus == 'inactive' && !l.isActive);
      return matchesSearch && matchesStatus;
    }).toList();

    return Column(children: [
      LevelsTopBar(
        onRefresh: _load,
        onExportExcel: _showExportExcelDialog,
        onExportPDF: _showExportPDFDialog,
        showSidePanel: _showSidePanel,
        isAddingNew: _editingLevel == null,
        onToggleAddPanel: onToggleAddPanel,
        primaryColor: _primary,
      ),
      Expanded(
        child: Container(
          color: const Color(0xFFF5F5F7),
          child: Row(children: [
            Expanded(
              child: Container(
                margin: isMobile ? EdgeInsets.zero : EdgeInsets.only(
                  top: 16, bottom: 16, right: 16,
                  left: _showSidePanel ? 0 : 16,
                ),
                decoration: isMobile ? const BoxDecoration(color: Colors.transparent) : BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 4))],
                ),
                child: ClipRRect(
                  borderRadius: isMobile ? BorderRadius.zero : BorderRadius.circular(24),
                  child: Column(children: [
                    if (!_isLoading)
                      Container(
                        color: isMobile ? Colors.white : Colors.transparent,
                        child: Column(children: [
                          LevelsStatsCards(
                            totalLevels: _levels.length,
                            activeLevels: _levels.where((l) => l.isActive).length,
                            inactiveLevels: _levels.where((l) => !l.isActive).length,
                            totalStudents: _studentCounts.values.fold(0, (a, b) => a + b),
                            primaryColor: _primary,
                          ),
                          LevelsFilterBar(
                            currentFilterStatus: _filterStatus,
                            onStatusChanged: (v) => setState(() => _filterStatus = v),
                            onSearchChanged: (v) => setState(() => _search = v),
                            selectedIdsCount: _selectedIds.length,
                            bulkUpdating: _bulkUpdating,
                            bulkDeleting: _bulkDeleting,
                            onBulkActivate: () => _bulkUpdateStatus(true),
                            onBulkDeactivate: () => _bulkUpdateStatus(false),
                            onBulkDelete: _bulkDelete,
                            filteredCount: filtered.length,
                            primaryColor: _primary,
                          ),
                        ]),
                      ),
                    Expanded(
                      child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : LevelsTable(
                            levels: filtered,
                            allStudents: _allStudents,
                            selectedIds: _selectedIds,
                            onSelectionChanged: (id, selected) => setState(() {
                              if (selected) {
                                _selectedIds.add(id);
                              } else {
                                _selectedIds.remove(id);
                              }
                            }),
                            onEditLevel: (l) => l.id != null ? _onEditLevel(l) : null,
                            primaryColor: _primary,
                            screenType: screenType,
                          ),
                    ),
                  ]),
                ),
              ),
            ),
            if (!ResponsiveUtils.isMobile(context) && _showSidePanel)
              ResizablePanel(
                initialWidth: _levelsPanelWidth,
                minWidth: 300,
                maxWidth: 600,
                onWidthChanged: (w) => _levelsPanelWidth = w,
                child: LevelsSidePanel(
                  level: _editingLevel,
                  onClose: () => setState(() => _showSidePanel = false),
                  onSave: (l) async {
                    setState(() => _isSaving = true);
                    try {
                      if (_editingLevel == null) {
                        await _service.createLevel(l);
                      } else {
                        await _service.updateLevel(_editingLevel!.id!, l);
                      }
                      _snack('تم الحفظ بنجاح');
                      _load();
                      setState(() => _showSidePanel = false);
                    } catch (e) { _snack('خطأ: $e', Colors.red); }
                    finally { setState(() => _isSaving = false); }
                  },
                  isSaving: _isSaving,
                  primaryColor: _primary,
                ),
              ),
          ]),
        ),
      ),
    ]);
  }
}
