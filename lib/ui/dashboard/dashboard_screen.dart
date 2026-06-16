import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

import '../../data/models/student.dart';
import '../../data/models/competition_level.dart';
import '../../services/supabase_service.dart';
import '../../services/cloudinary_service.dart';
import '../../services/export_service.dart';
import '../../services/print_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/text_controller_ext.dart';
import '../levels/levels_screen.dart';
import '../auth/splash_screen.dart';
import '../settings/settings_screen.dart';
import '../statistics/statistics_screen.dart';
import '../shared/widgets/export_fields.dart';
import '../shared/widgets/pagination_controls.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/error_state.dart';
import '../shared/widgets/connectivity_banner.dart';
import 'widgets/stats_cards.dart';
import 'widgets/filter_bar.dart';
import 'widgets/student_table.dart';
import 'widgets/detail_panel.dart';
import 'widgets/edit_panel.dart';
import 'widgets/sidebar.dart';
import 'widgets/top_bar.dart';
import 'widgets/add_student_panel.dart';
import 'widgets/resizable_panel.dart';

import '../../core/utils/image_utils.dart';
import '../../core/utils/app_logger.dart';

final _compressForEdit = compressImage;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Color get _primary => AppTheme.primaryColor;

  final GlobalKey<LevelsScreenState> _levelsKey = GlobalKey<LevelsScreenState>();
  final SupabaseService _service = SupabaseService();
  List<Student> _students = [];
  bool _isLoading = true;
  String? _error;
  Student? _selected;
  bool _updating = false;
  bool _showAddPanel = false;
  bool _showEditPanel = false;
  Student? _editingStudent;
  final _scoreCtrl = TextEditingController();
  final _rewayaScoreCtrl = TextEditingController();
  final _tajweedScoreCtrl = TextEditingController();
  final _voiceScoreCtrl = TextEditingController();
  final _meaningScoreCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  final Set<int> _revealedIds = {};
  DashboardView _currentView = DashboardView.dashboard;
  List<CompetitionLevel> _levels = [];
  String? _levelFilterTitle;
  int? _minAgeFilter;
  int? _maxAgeFilter;
  String? _genderFilter;
  double? _minScoreFilter;
  double? _maxScoreFilter;
  DateTime? _dateFilterStart;
  DateTime? _dateFilterEnd;
  // Pagination
  int _currentPage = 1;
  int _pageSize = 25;
  // Bulk Actions & Sorting State
  final Set<int> _selectedIds = {};
  int? _sortColumnIndex;
  bool _sortAscending = true;
  bool _sidebarCollapsed = false;
  double _sidePanelWidth = 520.0;
  String _settingsSection = 'dates';
  Uint8List? _editProfileBytes;
  Uint8List? _editBirthCertBytes;
  Uint8List? _originalProfileBytes;
  Uint8List? _originalBirthCertBytes;
  late TextEditingController _editNameCtrl;
  late TextEditingController _editPhoneCtrl;
  late TextEditingController _editNationalIdCtrl;
  late TextEditingController _editAgeCtrl;
  late TextEditingController _editMemorizerNameCtrl;
  late TextEditingController _editMemorizerPhoneCtrl;
  late TextEditingController _editMemorizerAddressCtrl;
  late TextEditingController _editLocationCtrl;
  late TextEditingController _editBirthDateCtrl;
  Timer? _editNameDebounce;
  bool _isEditNameDuplicate = false;
  bool _isEditNameChecking = false;
  bool _isEditIdChecking = false;
  bool _isEditIdDuplicate = false;
  bool _isEditSaving = false;
  String? _editGender;
  String? _editSelectedLevel;
  String? _editSelectedRewaya;
  String? _editBranchName;
  int? _editMemorizationAmount;
  DateTime? _editBirthDate;
  String _exportFolderPath = '';

  @override
  void initState() { 
    super.initState(); 
    _editNameCtrl = TextEditingController();
    _editPhoneCtrl = TextEditingController();
    _editNationalIdCtrl = TextEditingController();
    _editAgeCtrl = TextEditingController();
    _editMemorizerNameCtrl = TextEditingController();
    _editMemorizerPhoneCtrl = TextEditingController();
    _editMemorizerAddressCtrl = TextEditingController();
    _editLocationCtrl = TextEditingController();
    _editBirthDateCtrl = TextEditingController();
    _editNationalIdCtrl.addListener(_onNationalIdChanged);
    _editNameCtrl.addListener(_onEditNameChanged);
    _load();
    _loadExportFolder();
  }

  Future<void> _loadExportFolder() async {
    final path = await ExportService.getExportDir();
    if (path != null && mounted) setState(() => _exportFolderPath = path);
  }

  Future<void> _pickExportFolder() async {
    try {
      final path = await FilePicker.getDirectoryPath(
        dialogTitle: 'اختر مجلد حفظ التصدير',
        lockParentWindow: true,
      );
      if (mounted && path != null && path.isNotEmpty) {
        await ExportService.setExportDir(path);
        setState(() => _exportFolderPath = path);
        AppTheme.showSnack(context, 'تم تغيير مجلد الحفظ');
      }
    } catch (e) {
      if (mounted) AppTheme.showSnack(context, 'تعذر فتح نافذة اختيار المجلد', color: Colors.orange);
    }
  }

  void _onEditNameChanged() {
    if (_editNameDebounce?.isActive ?? false) _editNameDebounce?.cancel();
    
    final name = _editNameCtrl.text.trim();
    if (name.length < 3 || _editingStudent == null) {
      if (_isEditNameDuplicate) setState(() => _isEditNameDuplicate = false);
      return;
    }

    // Only check if name actually changed from original
    if (name == _editingStudent!.name) {
      if (_isEditNameDuplicate) setState(() => _isEditNameDuplicate = false);
      return;
    }

    _editNameDebounce = Timer(const Duration(milliseconds: 700), () async {
      if (!mounted) return;
      setState(() => _isEditNameChecking = true);
      
      try {
        // Exclude current student ID from check
        final exists = await _service.checkNameExists(name, excludeId: _editingStudent!.id);
        if (mounted) {
          setState(() {
            _isEditNameDuplicate = exists;
            _isEditNameChecking = false;
          });
          if (exists) {
            AppTheme.showSnack(context, 'تنبيه: هذا الاسم مسجل مسبقاً لمتسابق آخر!', color: AppTheme.warningColor);
          }
        }
      } catch (e) {
        if (mounted) setState(() => _isEditNameChecking = false);
      }
    });
  }

  void _onNationalIdChanged() {
    final id = _editNationalIdCtrl.text.trim();
    if (id.length == 14) {
      // 1. Extract Gender (13th digit)
      final int? digit13 = int.tryParse(id[12]);
      if (digit13 != null) {
        final bool isMale = digit13 % 2 != 0;
        final String detectedGender = isMale ? 'ذكر' : 'أنثى';
        if (_editGender != detectedGender) {
          setState(() => _editGender = detectedGender);
        }
      }

      // 2. Extract Birth Date & Age (Digits 1-7)
      final int? centuryDigit = int.tryParse(id[0]);
      final int? yearPart = int.tryParse(id.substring(1, 3));
      final int? monthPart = int.tryParse(id.substring(3, 5));
      final int? dayPart = int.tryParse(id.substring(5, 7));

      if (centuryDigit != null && yearPart != null && monthPart != null && dayPart != null) {
        final int year = (centuryDigit == 2 ? 1900 : 2000) + yearPart;
        try {
          final DateTime birthDate = DateTime(year, monthPart, dayPart);
          if (_editBirthDate != birthDate) {
            setState(() {
              _editBirthDate = birthDate;
              _editBirthDateCtrl.setText("${birthDate.year}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}");
            });
          }

          final DateTime now = DateTime.now();
          int age = now.year - birthDate.year;
          if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
            age--;
          }
          if (age >= 0 && age < 100) {
            final String ageStr = age.toString();
            if (_editAgeCtrl.text != ageStr) {
              _editAgeCtrl.setText(ageStr);
            }
          }
        } catch (e, stackTrace) {
          AppLogger.error('Failed to parse national ID date', error: e, stack: stackTrace);
        }
      }
      
      // 3. Real-time Duplicate ID Check
      _checkEditDuplicateId(id);
    } else {
      if (_isEditIdDuplicate) setState(() => _isEditIdDuplicate = false);
      if (id != (_editingStudent?.nationalId ?? '')) {
        if (_editGender != null || _editBirthDate != null || _editBirthDateCtrl.text.isNotEmpty || _editAgeCtrl.text.isNotEmpty) {
          setState(() {
            _editGender = null;
            _editBirthDate = null;
            _editBirthDateCtrl.setText('');
            _editAgeCtrl.setText('');
          });
        }
      }
    }
  }

  Future<void> _checkEditDuplicateId(String id) async {
    if (_editingStudent == null) return;
    // Only check if ID actually changed from original
    if (id == _editingStudent!.nationalId) {
      if (_isEditIdDuplicate) setState(() => _isEditIdDuplicate = false);
      return;
    }

    setState(() => _isEditIdChecking = true);
    try {
      final exists = await _service.checkNationalIdExists(id, excludeId: _editingStudent!.id);
      if (mounted) {
        setState(() {
          _isEditIdDuplicate = exists;
          _isEditIdChecking = false;
        });
        if (exists) {
          AppTheme.showSnack(context, 'تنبيه: هذا الرقم القومي مسجل لمتسابق آخر!', color: AppTheme.warningColor);
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to check duplicate national ID in edit', error: e, stack: stackTrace);
      if (mounted) setState(() => _isEditIdChecking = false);
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      // جلب الطلاب والمستويات
      final results = await Future.wait([
        _service.getAllStudents(), 
        _service.getLevels()
      ]);
      
      if (!mounted) return;
      setState(() {
        _students = results[0] as List<Student>;
        _levels = results[1] as List<CompetitionLevel>;
        _selectedIds.clear();
        if (_selected != null) {
          final updated = _students.firstWhere(
            (s) => s.id == _selected!.id,
            orElse: () => _selected!,
          );
          _selected = updated;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'فشل تحميل البيانات'; });
      AppTheme.showError(context, e, contextLabel: 'تحميل البيانات');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Student> get _filtered {
    final list = _students.where((s) {
      final matchesLevel = _levelFilterTitle == null || s.level == _levelFilterTitle;
      final matchesGender = _genderFilter == null || s.gender == _genderFilter;
      final matchesAge = (_minAgeFilter == null || s.age >= _minAgeFilter!) &&
                         (_maxAgeFilter == null || s.age <= _maxAgeFilter!);
      final matchesScore = (_minScoreFilter == null || (s.score ?? 0) >= _minScoreFilter!) &&
                           (_maxScoreFilter == null || (s.score ?? 0) <= _maxScoreFilter!);
      final matchesSearch = s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (s.phone.contains(_searchQuery)) ||
          (s.nationalId?.contains(_searchQuery) ?? false) ||
          (s.memorizerName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (s.location?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      final matchesStart = _dateFilterStart == null || (s.createdAt != null && s.createdAt!.isAfter(_dateFilterStart!.subtract(const Duration(seconds: 1))));
      final matchesEnd = _dateFilterEnd == null || (s.createdAt != null && s.createdAt!.isBefore(_dateFilterEnd!.add(const Duration(days: 1))));
      final matchesDate = matchesStart && matchesEnd;
      return matchesLevel && matchesGender && matchesAge && matchesScore && matchesSearch && matchesDate;
    }).toList();

    if (_sortColumnIndex != null) {
      list.sort((a, b) {
        int cmp = 0;
        switch (_sortColumnIndex) {
          case 0:
            cmp = a.name.compareTo(b.name);
            break;
          case 3:
            int orderA = _levels.indexWhere((l) => l.title == a.level);
            int orderB = _levels.indexWhere((l) => l.title == b.level);
            if (orderA == -1) orderA = 999;
            if (orderB == -1) orderB = 999;
            cmp = orderA.compareTo(orderB);
            if (cmp == 0) {
              cmp = a.name.compareTo(b.name);
            }
            break;
          case 4:
            cmp = a.age.compareTo(b.age);
            if (cmp == 0) {
              cmp = a.name.compareTo(b.name);
            }
            break;
          case 5:
            final scoreA = a.totalScore ?? a.score;
            final scoreB = b.totalScore ?? b.score;
            if (scoreA == null && scoreB != null) {
              cmp = _sortAscending ? 1 : -1;
            } else if (scoreA != null && scoreB == null) {
              cmp = _sortAscending ? -1 : 1;
            } else if (scoreA == null && scoreB == null) {
              cmp = 0;
            } else {
              cmp = scoreA!.compareTo(scoreB!);
            }
            if (cmp == 0) {
              cmp = a.name.compareTo(b.name);
            }
            break;
        }
        return _sortAscending ? cmp : -cmp;
      });
    }
    return list;
  }

  List<Student> get _pagedFiltered {
    if (_filtered.length <= _pageSize) return _filtered;
    final start = (_currentPage - 1) * _pageSize;
    final end = start + _pageSize;
    if (start >= _filtered.length) {
      _currentPage = 1;
      return _filtered.take(_pageSize).toList();
    }
    return _filtered.sublist(start, end.clamp(0, _filtered.length));
  }

  int get _totalPages {
    if (_filtered.isEmpty) return 1;
    return (_filtered.length / _pageSize).ceil();
  }

  void _resetPagination() {
    _currentPage = 1;
  }



  void _selectStudent(Student s) {
    setState(() {
      _selected = s;
      _scoreCtrl.setText(s.score != null ? AppTheme.formatScore(s.score!) : '');
      _rewayaScoreCtrl.setText(s.rewayaScore != null ? AppTheme.formatScore(s.rewayaScore!) : '');
      _tajweedScoreCtrl.setText(s.tajweedScore != null ? AppTheme.formatScore(s.tajweedScore!) : '');
      _voiceScoreCtrl.setText(s.voiceScore != null ? AppTheme.formatScore(s.voiceScore!) : '');
      _meaningScoreCtrl.setText(s.meaningScore != null ? AppTheme.formatScore(s.meaningScore!) : '');
      _showEditPanel = false;
      _showAddPanel = false;
    });
    if (ResponsiveUtils.isMobile(context)) _showDetailBottomSheet(s);
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    String confirmLabel = 'تأكيد',
    int? count,
    Color? confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 40, offset: const Offset(0, 12)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 32),
              ),
              const SizedBox(height: 20),
              Text(title, textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)),
              ),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: Colors.grey.shade600, height: 1.6),
              ),
              if (count != null && count > 1) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red.shade600),
                    const SizedBox(width: 6),
                    Text('سيتم حذف $count متسابق', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                  ]),
                ),
              ],
              const SizedBox(height: 28),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF555555))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: confirmColor ?? iconColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(confirmLabel, style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
    return result == true;
  }

  Future<bool> _showDeleteConfirmDialog({
    required String title,
    required String message,
    String confirmLabel = 'حذف نهائياً',
    int? count,
  }) async {
    return _showConfirmDialog(
      title: title,
      message: message,
      icon: Icons.delete_outline_rounded,
      iconBgColor: Colors.red.shade50,
      iconColor: Colors.red.shade600,
      confirmLabel: confirmLabel,
      count: count,
      confirmColor: Colors.red.shade600,
    );
  }

  Future<bool> _showDiscardConfirmDialog({
    required String title,
    required String message,
    String confirmLabel = 'نعم، خروج',
  }) async {
    return _showConfirmDialog(
      title: title,
      message: message,
      icon: Icons.warning_amber_rounded,
      iconBgColor: Colors.orange.shade50,
      iconColor: Colors.orange.shade600,
      confirmLabel: confirmLabel,
    );
  }

  Future<void> _deleteStudent(int id) async {
    final confirm = await _showDeleteConfirmDialog(
      title: 'تأكيد حذف المتسابق',
      message: 'هل أنت متأكد من حذف هذا المتسابق نهائياً؟\nلا يمكن التراجع عن هذا الإجراء.',
    );
    if (confirm) {
      try {
        await _service.deleteStudent(id);
        if (!mounted) return;
        setState(() {
          _students.removeWhere((s) => s.id == id);
          if (_selected?.id == id) _selected = null;
        });
        AppTheme.showSnack(context, 'تم حذف المتسابق بنجاح', color: Colors.red.shade700);
      } catch (e) {
        if (mounted) AppTheme.showError(context, e);
      }
    }
  }

  Future<void> _saveScore() async {
    if (_selected == null) return;
    final scoreStr = _scoreCtrl.text.trim();
    if (scoreStr.isEmpty) {
      if (mounted) {
        AppTheme.showSnack(
          context,
          'يرجى إدخال درجة الحفظ أولاً لتقييم المتسابق',
          color: AppTheme.errorColor,
        );
      }
      return;
    }
    
    final score = double.tryParse(scoreStr);
    if (score == null) {
      if (mounted) {
        AppTheme.showSnack(
          context,
          'يرجى إدخال درجة صالحة (رقم فقط)',
          color: AppTheme.errorColor,
        );
      }
      return;
    }
    
    // التحقق من الدرجة مقابل totalPoints للمستوى
    final matchedLevel = CompetitionLevel.findByTitle(_levels, _selected!.level);
    final maxPoints = matchedLevel?.totalPoints ?? 100;
    if (score < 0 || score > maxPoints) {
      if (mounted) {
        AppTheme.showSnack(
          context,
          'الدرجة يجب أن تكون بين 0 و $maxPoints',
          color: AppTheme.errorColor,
        );
      }
      return;
    }



    // Validate rewaya score if applicable
    double? rewayaScore;
    if (matchedLevel?.hasRewaya == true) {
      final rawStr = _rewayaScoreCtrl.text.trim();
      if (rawStr.isNotEmpty) {
        final raw = double.tryParse(rawStr);
        if (raw == null || raw < 0 || raw > (matchedLevel!.rewayaMaxScore)) {
          if (mounted) {
            AppTheme.showSnack(context,
              'درجة الرواية يجب أن تكون بين 0 و ${matchedLevel!.rewayaMaxScore}',
              color: AppTheme.errorColor);
          }
          return;
        }
        rewayaScore = raw;
      } else {
        rewayaScore = null;
      }
    } else {
      rewayaScore = null;
    }

    // Validate tajweed score if applicable
    double? tajweedScore;
    if (matchedLevel?.hasTajweed == true) {
      final rawStr = _tajweedScoreCtrl.text.trim();
      if (rawStr.isNotEmpty) {
        final raw = double.tryParse(rawStr);
        if (raw == null || raw < 0 || raw > (matchedLevel!.tajweedMaxScore)) {
          if (mounted) {
            AppTheme.showSnack(context,
              'درجة التجويد يجب أن تكون بين 0 و ${matchedLevel!.tajweedMaxScore}',
              color: AppTheme.errorColor);
          }
          return;
        }
        tajweedScore = raw;
      } else {
        tajweedScore = null;
      }
    } else {
      tajweedScore = null;
    }

    // Validate voice score if applicable
    double? voiceScore;
    if (matchedLevel?.hasVoice == true) {
      final rawStr = _voiceScoreCtrl.text.trim();
      if (rawStr.isNotEmpty) {
        final raw = double.tryParse(rawStr);
        if (raw == null || raw < 0 || raw > (matchedLevel!.voiceMaxScore)) {
          if (mounted) {
            AppTheme.showSnack(context,
              'درجة حلاوة الصوت والتأثير يجب أن تكون بين 0 و ${matchedLevel!.voiceMaxScore}',
              color: AppTheme.errorColor);
          }
          return;
        }
        voiceScore = raw;
      } else {
        voiceScore = null;
      }
    } else {
      voiceScore = null;
    }

    // Validate meaning score if applicable
    double? meaningScore;
    if (matchedLevel?.hasMeaning == true) {
      final rawStr = _meaningScoreCtrl.text.trim();
      if (rawStr.isNotEmpty) {
        final raw = double.tryParse(rawStr);
        if (raw == null || raw < 0 || raw > (matchedLevel!.meaningMaxScore)) {
          if (mounted) {
            AppTheme.showSnack(context,
              'درجة فهم المعاني يجب أن تكون بين 0 و ${matchedLevel!.meaningMaxScore}',
              color: AppTheme.errorColor);
          }
          return;
        }
        meaningScore = raw;
      } else {
        meaningScore = null;
      }
    } else {
      meaningScore = null;
    }

    setState(() => _updating = true);
    try {
      final sid = _selected!.id;
      if (sid == null) return;
      final updated = await _service.updateStudent(
        sid,
        _selected!.copyWith(
          score: score,
          rewayaScore: rewayaScore,
          tajweedScore: tajweedScore,
          voiceScore: voiceScore,
          meaningScore: meaningScore,
        ),
      );
      setState(() {
        _selected = updated;
        final i = _students.indexWhere((s) => s.id == updated.id);
        if (i != -1) _students[i] = updated;
      });
      if (mounted) AppTheme.showSnack(context, 'تم حفظ التقييم');
    } catch (e) {
      if (mounted) AppTheme.showError(context, e);
    } finally { setState(() => _updating = false); }
  }

  Future<void> _bulkDeleteSelected() async {
    if (_selectedIds.isEmpty) return;
    
    final confirm = await _showDeleteConfirmDialog(
      title: 'حذف المتسابقين المحددين',
      message: 'هل أنت متأكد؟ لا يمكن التراجع عن هذا الإجراء.',
      confirmLabel: 'حذف الكل',
      count: _selectedIds.length,
    );
    if (!confirm) return;
    
    try {
      final idsToDelete = List<int>.from(_selectedIds);
      if (idsToDelete.isNotEmpty) {
        await _service.deleteStudentsBatch(idsToDelete);
      }
      setState(() {
        _students.removeWhere((s) => idsToDelete.contains(s.id));
        _selectedIds.clear();
        _selected = null;
      });
      if (mounted) AppTheme.showSnack(context, 'تم حذف المتسابقين بنجاح', color: Colors.red.shade700);
    } catch (e) {
      if (mounted) AppTheme.showError(context, e, contextLabel: 'حذف المتسابقين');
    } finally {
    }
  }

  Future<void> _exportExcel({String? level, double? minScore, double? maxScore}) async {
    try {
      if (_exportFolderPath.isEmpty) {
        await _pickExportFolder();
        if (_exportFolderPath.isEmpty) return;
      }
      final exportService = ExportService();
      final selectedLevelObj = level != null
          ? CompetitionLevel.findByTitle(_levels, level)
          : null;
      final bytes = await exportService.studentsToExcel(
        students: _students,
        levels: _levels,
        levelTitle: level,
        selectedLevel: selectedLevelObj,
        minScore: minScore,
        maxScore: maxScore,
      );
      final fileName = 'Contestants_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final savePath = await exportService.saveFile(bytes, fileName, 'xlsx', directory: _exportFolderPath);
      if (savePath != null && mounted) {
        AppTheme.showSnack(context, 'تم تصدير التقرير بنجاح ✓');
        if (_exportFolderPath.isNotEmpty) Process.run('explorer.exe', [_exportFolderPath]);
      }
    } catch (e) {
      if (mounted) AppTheme.showError(context, e, contextLabel: 'تصدير التقرير');
    }
  }



  Future<void> _showExportDialog({required bool isExcel}) async {
    String? exportLevel = _levelFilterTitle;
    final minScoreCtrl = TextEditingController(text: _minScoreFilter?.toString() ?? '');
    final maxScoreCtrl = TextEditingController(text: _maxScoreFilter?.toString() ?? '');
    final icon = isExcel ? Icons.table_chart_rounded : Icons.picture_as_pdf_rounded;
    final iconColor = isExcel ? Colors.green : Colors.red;
    final title = isExcel ? 'خيارات تصدير Excel' : 'خيارات تصدير PDF';
    final description = isExcel 
        ? 'قم بتحديد المستوى ونطاق الدرجات لتصدير التقرير:'
        : 'حدد البيانات التي ترغب في إدراجها في ملف التقرير:';
    final btnColor = isExcel ? Colors.green.shade700 : Colors.red.shade700;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setExportState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ]),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(description, style: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: Colors.grey.shade600)),
              const SizedBox(height: 20),
              
              const ExportFilterLabel(label: 'المستوى'),
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50, 
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: exportLevel,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: _primary, fontWeight: FontWeight.w600),
                    items: [
                      DropdownMenuItem(
                        value: null, 
                        child: Row(children: [
                          Icon(Icons.layers_rounded, size: 18, color: Colors.grey.shade400),
                          const SizedBox(width: 10),
                          Text('جميع المستويات', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey.shade600)),
                        ])),
                      ..._levels.map((l) => DropdownMenuItem(
                        value: l.title, 
                        child: Row(children: [
                          const Icon(Icons.layers_outlined, size: 18, color: Colors.blue),
                          const SizedBox(width: 10),
                          Text(l.title),
                        ]))),
                    ],
                    onChanged: (v) => setExportState(() => exportLevel = v),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const ExportFilterLabel(label: 'نطاق الدرجات'),
              Row(children: [
                Expanded(child: ExportNumberField(controller: minScoreCtrl, hintText: 'من')),
                const SizedBox(width: 12),
                Expanded(child: ExportNumberField(controller: maxScoreCtrl, hintText: 'إلى')),
              ]),
              const SizedBox(height: 16),
              ExportFolderRow(
                path: _exportFolderPath,
                onChangeTap: () async {
                  await _pickExportFolder();
                  setExportState(() {});
                },
              ),
            ]),
          ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (isExcel) {
                  _exportExcel(level: exportLevel, minScore: double.tryParse(minScoreCtrl.text), maxScore: double.tryParse(maxScoreCtrl.text));
                } else {
                  _exportPDF(level: exportLevel, minScore: double.tryParse(minScoreCtrl.text), maxScore: double.tryParse(maxScoreCtrl.text));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: btnColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('تصدير الآن', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _exportPDF({String? level, double? minScore, double? maxScore}) async {
    try {
      final exportService = ExportService();
      final bytes = await exportService.studentsToPDF(
        students: _students,
        levels: _levels,
        level: level,
        minScore: minScore,
        maxScore: maxScore,
      );
      await exportService.printPdf(bytes);
    } catch (e) {
      if (mounted) AppTheme.showError(context, e, contextLabel: 'تصدير PDF');
    }
  }

  Future<void> _printStudentCard(Student s) async {
    try {
      if (_exportFolderPath.isEmpty) {
        await _pickExportFolder();
        if (_exportFolderPath.isEmpty) return;
      }
      AppTheme.showSnack(context, 'جاري حفظ استمارة المتسابق...', color: _primary);
      final printService = PrintService();
      final path = await printService.saveStudentCardsToDownloads([s], _levels, customDir: _exportFolderPath);
      if (mounted) {
        AppTheme.showSnack(context, 'تم الحفظ في: $path');
        if (_exportFolderPath.isNotEmpty) Process.run('explorer.exe', [_exportFolderPath]);
      }
    } catch (e) {
      if (mounted) AppTheme.showError(context, e, contextLabel: 'حفظ التقرير');
    }
  }

  Future<void> _bulkPrintSelected() async {
    if (_selectedIds.isEmpty) return;
    
    try {
      if (_exportFolderPath.isEmpty) {
        await _pickExportFolder();
        if (_exportFolderPath.isEmpty) return;
      }
      AppTheme.showSnack(context, 'جاري تحضير وحفظ ${_selectedIds.length} استمارة...', color: _primary);
      
      final List<Student> selectedStudents = _students.where((s) => _selectedIds.contains(s.id)).toList();
      final printService = PrintService();
      final path = await printService.saveStudentCardsToDownloads(selectedStudents, _levels, customDir: _exportFolderPath);
      
      if (mounted) {
        AppTheme.showSnack(context, 'تم حفظ جميع الاستمارات في: $path');
        if (_exportFolderPath.isNotEmpty) Process.run('explorer.exe', [_exportFolderPath]);
      }
    } catch (e) {
      if (mounted) AppTheme.showError(context, e, contextLabel: 'حفظ الاستمارات');
    }
  }

  void _onEditStudent(Student s) {
    setState(() {
      _editingStudent = s;
      _editNameCtrl.setText(s.name);
      _editPhoneCtrl.setText(s.phone);
      _editNationalIdCtrl.setText(s.nationalId ?? '');
      _editAgeCtrl.setText(s.age.toString());
      _editMemorizerNameCtrl.setText(s.memorizerName ?? '');
      _editMemorizerPhoneCtrl.setText(s.memorizerPhone ?? '');
      _editMemorizerAddressCtrl.setText(s.memorizerAddress ?? '');
      _editLocationCtrl.setText(s.location ?? '');
      _editBirthDate = s.birthDate;
      _editBirthDateCtrl.setText(s.birthDate != null 
          ? "${s.birthDate!.year}-${s.birthDate!.month.toString().padLeft(2, '0')}-${s.birthDate!.day.toString().padLeft(2, '0')}" 
          : '');
      _editGender = s.gender ?? 'ذكر';
      _editSelectedLevel = s.level;
      _editSelectedRewaya = s.selectedRewaya;
      _editBranchName = s.branchName;
      _editMemorizationAmount = s.memorizationAmount;
      _editProfileBytes = null;
      _editBirthCertBytes = null;
      _originalProfileBytes = null;
      _originalBirthCertBytes = null;
      _showEditPanel = true;
      _showAddPanel = false;
    });
    _fetchOriginalImageBytes(s);
    if (ResponsiveUtils.isMobile(context)) _showEditBottomSheet();
  }

  Future<void> _fetchOriginalImageBytes(Student s) async {
    if (Validator.isValidImageUrl(s.profileImageUrl)) {
      try {
        final res = await http.get(Uri.parse(s.profileImageUrl!)).timeout(const Duration(seconds: 15));
        if (res.statusCode == 200 && mounted) {
          setState(() {
            _originalProfileBytes = res.bodyBytes;
            _editProfileBytes = res.bodyBytes;
          });
        }
      } catch (e) {
        AppLogger.info('Error fetching original profile bytes: $e');
      }
    }
    if (Validator.isValidImageUrl(s.birthCertificateUrl)) {
      try {
        final res = await http.get(Uri.parse(s.birthCertificateUrl!)).timeout(const Duration(seconds: 15));
        if (res.statusCode == 200 && mounted) {
          setState(() {
            _originalBirthCertBytes = res.bodyBytes;
            _editBirthCertBytes = res.bodyBytes;
          });
        }
      } catch (e) {
        AppLogger.info('Error fetching original birth cert bytes: $e');
      }
    }
  }

  Future<void> _pickEditImage(bool isProfile) async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.image, withData: true, allowMultiple: false);
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.bytes == null) return;
      
      final compressed = kIsWeb
          ? _compressForEdit(file.bytes!)
          : await compute<Uint8List, Uint8List>(_compressForEdit, file.bytes!);
      setState(() {
        if (isProfile) {
          _editProfileBytes = compressed;
        } else {
          _editBirthCertBytes = compressed;
        }
      });
    } catch (e) {
      AppLogger.info('Error picking image: $e');
    }
  }

  bool _isEditDirty() {
    if (_editingStudent == null) return false;
    final s = _editingStudent!;
    return _editNameCtrl.text.trim() != s.name ||
           _editPhoneCtrl.text.trim() != s.phone ||
           _editNationalIdCtrl.text.trim() != (s.nationalId ?? '') ||
           _editAgeCtrl.text.trim() != s.age.toString() ||
           _editMemorizerNameCtrl.text.trim() != (s.memorizerName ?? '') ||
           _editMemorizerPhoneCtrl.text.trim() != (s.memorizerPhone ?? '') ||
           _editMemorizerAddressCtrl.text.trim() != (s.memorizerAddress ?? '') ||
           _editLocationCtrl.text.trim() != (s.location ?? '') ||
           _editGender != (s.gender ?? 'ذكر') ||
           _editSelectedLevel != s.level ||
           _editSelectedRewaya != s.selectedRewaya ||
           _editBranchName != s.branchName ||
           _editMemorizationAmount != s.memorizationAmount ||
           _editBirthDate != s.birthDate ||
           !listEquals(_editProfileBytes, _originalProfileBytes) ||
           !listEquals(_editBirthCertBytes, _originalBirthCertBytes);
  }

  Future<void> _handleCloseEditPanel({required VoidCallback onClose}) async {
    if (_isEditDirty()) {
      final confirm = await _showDiscardConfirmDialog(
        title: 'تغييرات غير محفوظة',
        message: 'هل أنت متأكد من الخروج؟ سيتم فقدان جميع التعديلات التي قمت بها.',
        confirmLabel: 'نعم، خروج',
      );
      if (!confirm) return;
    }
    onClose();
  }

  Future<void> _saveEdit() async {
    if (_editingStudent == null) return;
    
    // 1. Basic field validation
    if (_editNameCtrl.text.trim().isEmpty || 
        _editPhoneCtrl.text.trim().isEmpty || 
        _editAgeCtrl.text.trim().isEmpty || 
        _editMemorizerNameCtrl.text.trim().isEmpty || 
        _editLocationCtrl.text.trim().isEmpty) {
      AppTheme.showSnack(context, 'يرجى ملء جميع الحقول المطلوبة', color: Colors.red);
      return;
    }

    if (_editGender == null) {
      AppTheme.showSnack(context, 'يرجى تحديد النوع (ذكر أو أنثى)', color: Colors.red);
      return;
    }

    // 2. National ID + Gender cross-validation (BEFORE any async work)
    final String nationalId = _editNationalIdCtrl.text.trim();
    if (nationalId.isNotEmpty) {
      if (nationalId.length != 14) {
        AppTheme.showSnack(context, 'الرقم القومي يجب أن يكون 14 رقماً', color: Colors.red);
        return;
      }
      final int? digit13 = int.tryParse(nationalId[12]);
      if (digit13 != null && _editGender != null) {
        final bool idSaysMale = digit13 % 2 != 0;
        final bool selectedMale = _editGender == 'ذكر';
        if (idSaysMale != selectedMale) {
          final String correctGender = idSaysMale ? 'ذكر' : 'أنثى';
          AppTheme.showSnack(
            context,
            '⚠️ خطأ في النوع: الرقم القومي يُشير إلى أن المتسابق "$correctGender"، لكن النوع المحدد هو "$_editGender"',
            color: Colors.orange.shade800,
          );
          return;
        }
      }
    }
    
    if (_editPhoneCtrl.text.trim().isNotEmpty && 
        _editMemorizerPhoneCtrl.text.trim().isNotEmpty && 
        _editPhoneCtrl.text.trim() == _editMemorizerPhoneCtrl.text.trim()) {
      AppTheme.showSnack(context, 'رقم هاتف الطالب / ولي الأمر يجب أن يكون مختلفاً عن رقم هاتف المحفظ', color: Colors.red);
      return;
    }

    // Validate selected level matches student age
    final editAge = int.tryParse(_editAgeCtrl.text.trim());
    if (editAge != null && _editSelectedLevel != null) {
      final selLevel = CompetitionLevel.findByTitle(_levels, _editSelectedLevel);
      if (selLevel != null && !selLevel.ageMatches(editAge)) {
        AppTheme.showSnack(
          context,
          'العمر ($editAge سنة) غير مناسب لمستوى "${_editSelectedLevel}" — ${selLevel.ageDescription}',
          color: Colors.red,
        );
        return;
      }
    }

    setState(() => _isEditSaving = true);
    try {
      final cloudinary = CloudinaryService();
      String? newProfileUrl = _editingStudent!.profileImageUrl;
      String? newBirthCertUrl = _editingStudent!.birthCertificateUrl;

      if (_editProfileBytes != null) {
        newProfileUrl = await cloudinary.uploadImage(_editProfileBytes!, 'profile_${_editingStudent!.id}.jpg');
      }
      if (_editBirthCertBytes != null) {
        newBirthCertUrl = await cloudinary.uploadImage(_editBirthCertBytes!, 'birth_${_editingStudent!.id}.jpg');
      }

      final editingId = _editingStudent!.id;
      if (editingId == null) return;
      final updated = await _service.updateStudent(editingId, _editingStudent!.copyWith(
        name: _editNameCtrl.text.trim(),
        phone: _editPhoneCtrl.text.trim(),
        nationalId: nationalId.isEmpty ? null : nationalId,
        gender: _editGender,
        memorizerName: _editMemorizerNameCtrl.text.trim().isEmpty ? null : _editMemorizerNameCtrl.text.trim(),
        memorizerPhone: _editMemorizerPhoneCtrl.text.trim().isEmpty ? null : _editMemorizerPhoneCtrl.text.trim(),
        memorizerAddress: _editMemorizerAddressCtrl.text.trim().isEmpty ? null : _editMemorizerAddressCtrl.text.trim(),
        location: _editLocationCtrl.text.trim().isEmpty ? null : _editLocationCtrl.text.trim(),
        birthDate: _editBirthDate,
        age: int.tryParse(_editAgeCtrl.text.trim()) ?? _editingStudent!.age,
        level: _editSelectedLevel ?? _editingStudent!.level,
        selectedRewaya: _editSelectedRewaya,
        branchName: _editBranchName,
        memorizationAmount: _editMemorizationAmount,
        profileImageUrl: newProfileUrl,
        birthCertificateUrl: newBirthCertUrl,
      ));

      setState(() {
        final i = _students.indexWhere((st) => st.id == updated.id);
        if (i != -1) _students[i] = updated;
        if (_selected?.id == updated.id) _selected = updated;
        _showEditPanel = false;
        _editingStudent = null;
      });
      
      if (mounted) AppTheme.showSnack(context, 'تم تحديث البيانات بنجاح');
    } catch (e) {
      if (mounted) AppTheme.showError(context, e);
    } finally {
      if (mounted) setState(() => _isEditSaving = false);
    }
  }

  void _showDetailBottomSheet(Student student) {
    final maxH = MediaQuery.of(context).size.height * 0.9;
    final matchedLevel = CompetitionLevel.findByTitle(_levels, student.level);
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
        child: StudentDetailPanel(
          student: student,
          primaryColor: AppTheme.primaryColor,
          scoreController: _scoreCtrl,
          rewayaScoreController: _rewayaScoreCtrl,
          tajweedScoreController: _tajweedScoreCtrl,
          voiceScoreController: _voiceScoreCtrl,
          meaningScoreController: _meaningScoreCtrl,
          level: matchedLevel,
          isUpdating: _updating,
          onClose: () => Navigator.pop(ctx),
          onSaveScore: () async {
            await _saveScore();
            if (ctx.mounted) Navigator.pop(ctx);
          },
          onEdit: () {
            Navigator.pop(ctx);
            _onEditStudent(student);
          },
          onPrint: _printStudentCard,
          onDelete: (id) async {
            Navigator.pop(ctx);
            await _deleteStudent(id);
          },
        ),
      ),
    ).then((_) {
      if (mounted) setState(() => _selected = null);
    });
  }

  void _showEditBottomSheet() {
    if (_editingStudent == null) return;
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
        child: StudentEditPanel(
          student: _editingStudent!,
          primaryColor: AppTheme.primaryColor,
          nameController: _editNameCtrl,
          phoneController: _editPhoneCtrl,
          nationalIdController: _editNationalIdCtrl,
          ageController: _editAgeCtrl,
          memorizerNameController: _editMemorizerNameCtrl,
          memorizerPhoneController: _editMemorizerPhoneCtrl,
          memorizerAddressController: _editMemorizerAddressCtrl,
          locationController: _editLocationCtrl,
          birthDateController: _editBirthDateCtrl,
          gender: _editGender,
          onGenderChanged: (v) => setState(() => _editGender = v),
          currentLevel: _editSelectedLevel,
          levels: _levels,
          onLevelChanged: (val) => setState(() {
            _editSelectedLevel = val;
            final matched = CompetitionLevel.findByTitle(_levels, val);
            if (matched?.hasRewaya != true) {
              _editSelectedRewaya = null;
            } else if (_editSelectedRewaya == null && matched?.availableRewayas.isNotEmpty == true) {
              _editSelectedRewaya = matched!.availableRewayas.first;
            }
            // Reset branch when level changes
            if (matched?.branches.isEmpty != false) _editBranchName = null;
            _editMemorizationAmount = matched?.requireCustomAmount == true ? null : _editMemorizationAmount;
          }),
          selectedRewaya: _editSelectedRewaya,
          onRewayaChanged: (val) => setState(() => _editSelectedRewaya = val),
          selectedBranchName: _editBranchName,
          onBranchChanged: (val) => setState(() => _editBranchName = val),
          memorizationAmount: _editMemorizationAmount,
          onMemorizationAmountChanged: (val) => setState(() => _editMemorizationAmount = val),
          profileBytes: _editProfileBytes,
          birthCertBytes: _editBirthCertBytes,
          profileUrl: _editingStudent!.profileImageUrl,
          birthCertUrl: _editingStudent!.birthCertificateUrl,
          onPickProfile: () => _pickEditImage(true),
          onPickBirthCert: () => _pickEditImage(false),
          isSaving: _isEditSaving,
          isNameChecking: _isEditNameChecking,
          isNameDuplicate: _isEditNameDuplicate,
          isIdChecking: _isEditIdChecking,
          isIdDuplicate: _isEditIdDuplicate,
          onSave: () async {
            await _saveEdit();
            if (ctx.mounted) Navigator.pop(ctx);
          },
          onClose: () => _handleCloseEditPanel(onClose: () => Navigator.pop(ctx)),
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _showEditPanel = false;
          _editingStudent = null;
          _editProfileBytes = null;
          _editBirthCertBytes = null;
        });
      }
    });
  }

  void _onToggleAddStudentPanel() {
    final isWide = MediaQuery.of(context).size.width >= 1100;
    setState(() {
      _showAddPanel = !_showAddPanel;
      if (_showAddPanel) {
        _selected = null;
        _showEditPanel = false;
      }
    });
    if (!isWide && _showAddPanel) _showAddBottomSheet();
  }

  void _showAddBottomSheet() {
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
        child: AddStudentPanel(
          primaryColor: AppTheme.primaryColor,
          onClose: () => Navigator.pop(ctx),
          onSuccess: () {
            Navigator.pop(ctx);
            _load();
          },
        ),
      ),
    ).then((_) {
      if (mounted) setState(() => _showAddPanel = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenType = ResponsiveUtils.fromWidth(MediaQuery.of(context).size.width);
    final isWide = screenType == ScreenType.desktop;
    
    final totalCount = _filtered.length;
    
    final memorizersCount = _filtered.map((s) => s.memorizerName).where((m) => m != null && m.trim().isNotEmpty).toSet().length;
    final males = _filtered.where((s) => s.gender == 'ذكر').length;
    final females = _filtered.where((s) => s.gender == 'أنثى').length;
    final levelCounts = <String, int>{};
    for (final s in _filtered) {
      levelCounts[s.level] = (levelCounts[s.level] ?? 0) + 1;
    }

    final Widget levelsView = LevelsScreen(
      key: _levelsKey,
      onLevelSelected: (title) {
        setState(() {
          _currentView = DashboardView.dashboard;
          _levelFilterTitle = title;
        });
      },
    );

    final Widget dashboardContent = Column(children: [
      DashboardTopBar(
        isWide: isWide,
        onRefresh: _load,
        onExportExcel: () => _showExportDialog(isExcel: true),
        onExportPDF: () => _showExportDialog(isExcel: false),
        showAddPanel: _showAddPanel,
        onToggleAddPanel: _onToggleAddStudentPanel,
        primaryColor: _primary,
        exportFolderPath: _exportFolderPath,
        onChangeExportFolder: _pickExportFolder,
      ),
      Expanded(child: Row(children: [
        Expanded(
          child: Container(
            margin: isWide ? EdgeInsets.only(
              top: 16, bottom: 16, right: 16,
              left: (_showAddPanel || _selected != null || _showEditPanel) ? 0 : 16,
            ) : EdgeInsets.zero,
            decoration: isWide ? BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 4)),
              ],
            ) : const BoxDecoration(color: Colors.transparent),
            child: ClipRRect(
              borderRadius: isWide ? BorderRadius.circular(24) : BorderRadius.zero,
              child: Column(children: [
                if (!_isLoading && _error == null) ...[
                  Container(
                    color: !isWide ? Colors.white : Colors.transparent,
                    child: Column(children: [
                      DashboardStatsCards(stats: [
                        StatEntry(title: 'الإجمالي', value: '$totalCount', icon: Icons.group_rounded, color: Colors.blue),
                        StatEntry(title: 'الذكور', value: '$males', icon: Icons.male_rounded, color: Colors.green),
                        StatEntry(title: 'الإناث', value: '$females', icon: Icons.female_rounded, color: Colors.orange),
                        if (memorizersCount > 0)
                          StatEntry(title: 'المُحفِّظين', value: '$memorizersCount', icon: Icons.person_pin_circle_rounded, color: Colors.purple),
                      ]),
                      DashboardFilterBar(
                        currentLevelTitle: _levelFilterTitle,
                        levels: _levels,
                        onLevelChanged: (val) => setState(() => _levelFilterTitle = val),
                        currentGender: _genderFilter,
                        onGenderChanged: (val) => setState(() => _genderFilter = val),
                        minAge: _minAgeFilter,
                        maxAge: _maxAgeFilter,
                        onMinAgeChanged: (val) => setState(() => _minAgeFilter = val),
                        onMaxAgeChanged: (val) => setState(() => _maxAgeFilter = val),
                        minScore: _minScoreFilter,
                        maxScore: _maxScoreFilter,
                        onMinScoreChanged: (val) => setState(() => _minScoreFilter = val),
                        onMaxScoreChanged: (val) => setState(() => _maxScoreFilter = val),
                        searchController: _searchCtrl,
                        onSearchChanged: (val) => setState(() => _searchQuery = val),
                        selectedIdsCount: _selectedIds.length,
                        onBulkDelete: _bulkDeleteSelected,
                        onBulkPrint: _bulkPrintSelected,
                        filteredCount: _filtered.length,
                        primaryColor: _primary,
                        filterDateStart: _dateFilterStart,
                        filterDateEnd: _dateFilterEnd,
                        onFilterDateRangeChanged: (start, end) => setState(() {
                          _dateFilterStart = start;
                          _dateFilterEnd = end;
                        }),
                      ),
                    ]),
                  ),
                ],
                Expanded(
                  child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                    : _error != null
                      ? ErrorState(
                          message: 'حدث خطأ أثناء تحميل البيانات',
                          details: _error,
                          onRetry: _load,
                        )
                      : _filtered.isEmpty
                        ? EmptyState(
                            icon: Icons.group_outlined,
                            title: 'لا يوجد متسابقون',
                            subtitle: 'لم يتم إضافة أي متسابق بعد',
                            actionLabel: 'إضافة متسابق',
                            onAction: () => setState(() => _showAddPanel = true),
                          )
                        : Column(children: [
                            Expanded(
                              child: StudentTable(
                                students: _pagedFiltered,
                                levels: _levels,
                                selectedIds: _selectedIds,
                                onSelectionChanged: (id, selected) => setState(() {
                                  if (selected) { _selectedIds.add(id); } else { _selectedIds.remove(id); }
                                }),
                                onSelectAll: () => setState(() {
                                  if (_selectedIds.length == _pagedFiltered.length) { _selectedIds.clear(); }
                                  else { _selectedIds.addAll(_pagedFiltered.map((s) => s.id).where((id) => id != null).cast<int>()); }
                                }),
                                onStudentTap: _selectStudent,
                                sortColumnIndex: _sortColumnIndex,
                                sortAscending: _sortAscending,
                                onSort: (index) => setState(() {
                                  if (_sortColumnIndex == index) { _sortAscending = !_sortAscending; }
                                  else { _sortColumnIndex = index; _sortAscending = true; }
                                  _resetPagination();
                                }),
                                primaryColor: _primary,
                                revealedIds: _revealedIds,
                                onToggleReveal: (id) => setState(() {
                                  if (_revealedIds.contains(id)) { _revealedIds.remove(id); }
                                  else { _revealedIds.add(id); }
                                }),
                                onEdit: _onEditStudent,
                                onPrint: _printStudentCard,
                                onDelete: (s) => _deleteStudent(s.id!),
                                onAddScore: (s, score) async {
                                  if (s.id == null) return;
                                  try {
                                    final updated = await _service.updateStudent(s.id!, s.copyWith(score: score));
                                    setState(() {
                                      final i = _students.indexWhere((st) => st.id == updated.id);
                                      if (i != -1) _students[i] = updated;
                                      if (_selected?.id == updated.id) _selected = updated;
                                    });
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    AppTheme.showSnack(context, 'خطأ في حفظ الدرجة', color: AppTheme.errorColor);
                                  }
                                },
                                screenType: screenType,
                              ),
                            ),
                            PaginationControls(
                              currentPage: _currentPage,
                              totalPages: _totalPages,
                              totalItems: _filtered.length,
                              itemsPerPage: _pageSize,
                              onPageChanged: (page) => setState(() => _currentPage = page),
                              pageSizeOptions: const [25, 50, 100],
                              onPageSizeChanged: (size) => setState(() {
                                _pageSize = size;
                                _resetPagination();
                              }),
                            ),
                          ]),
                ),
              ]),
            ),
          ),
        ),
        if (isWide) ...[
          if (_showEditPanel && _editingStudent != null)
            ResizablePanel(
              initialWidth: _sidePanelWidth,
              minWidth: 300,
              maxWidth: 680,
              onWidthChanged: (w) => _sidePanelWidth = w,
              child: StudentEditPanel(
                student: _editingStudent!,
                primaryColor: AppTheme.primaryColor,
                nameController: _editNameCtrl,
                phoneController: _editPhoneCtrl,
                nationalIdController: _editNationalIdCtrl,
                ageController: _editAgeCtrl,
                memorizerNameController: _editMemorizerNameCtrl,
                memorizerPhoneController: _editMemorizerPhoneCtrl,
                memorizerAddressController: _editMemorizerAddressCtrl,
                locationController: _editLocationCtrl,
                birthDateController: _editBirthDateCtrl,
                gender: _editGender,
                onGenderChanged: (v) => setState(() => _editGender = v),
                currentLevel: _editSelectedLevel,
                levels: _levels,
                onLevelChanged: (val) => setState(() {
                  _editSelectedLevel = val;
                  final matched = CompetitionLevel.findByTitle(_levels, val);
                  if (matched?.hasRewaya != true) {
                    _editSelectedRewaya = null;
                  } else if (_editSelectedRewaya == null && matched?.availableRewayas.isNotEmpty == true) {
                    _editSelectedRewaya = matched!.availableRewayas.first;
                  }
                  // Reset branch when level changes
                  if (matched?.branches.isEmpty != false) _editBranchName = null;
                  _editMemorizationAmount = matched?.requireCustomAmount == true ? null : _editMemorizationAmount;
                }),
                selectedRewaya: _editSelectedRewaya,
                onRewayaChanged: (val) => setState(() => _editSelectedRewaya = val),
                selectedBranchName: _editBranchName,
                onBranchChanged: (val) => setState(() => _editBranchName = val),
                memorizationAmount: _editMemorizationAmount,
                onMemorizationAmountChanged: (val) => setState(() => _editMemorizationAmount = val),
                profileBytes: _editProfileBytes,
                birthCertBytes: _editBirthCertBytes,
                profileUrl: _editingStudent!.profileImageUrl,
                birthCertUrl: _editingStudent!.birthCertificateUrl,
                onPickProfile: () => _pickEditImage(true),
                onPickBirthCert: () => _pickEditImage(false),
                isSaving: _isEditSaving,
                isNameChecking: _isEditNameChecking,
                isNameDuplicate: _isEditNameDuplicate,
                isIdChecking: _isEditIdChecking,
                isIdDuplicate: _isEditIdDuplicate,
                 
                onSave: _saveEdit,
                onClose: () => _handleCloseEditPanel(onClose: () => setState(() { _showEditPanel = false; _editingStudent = null; })),
                width: double.infinity,
              ),
            )
          else if (_showAddPanel)
            ResizablePanel(
              initialWidth: _sidePanelWidth,
              minWidth: 300,
              maxWidth: 680,
              onWidthChanged: (w) => _sidePanelWidth = w,
              child: AddStudentPanel(
                primaryColor: AppTheme.primaryColor,
                onClose: () => setState(() => _showAddPanel = false),
                onSuccess: _load,
              ),
            )
          else if (_selected != null) ...[
            (() {
              final matchedLevel = CompetitionLevel.findByTitle(_levels, _selected!.level);
              return ResizablePanel(
                initialWidth: _sidePanelWidth,
                minWidth: 300,
                maxWidth: 680,
                onWidthChanged: (w) => _sidePanelWidth = w,
                child: StudentDetailPanel(
                  student: _selected!,
                  primaryColor: AppTheme.primaryColor,
                  scoreController: _scoreCtrl,
                  rewayaScoreController: _rewayaScoreCtrl,
                  tajweedScoreController: _tajweedScoreCtrl,
                  voiceScoreController: _voiceScoreCtrl,
                  meaningScoreController: _meaningScoreCtrl,
                  level: matchedLevel,
                  isUpdating: _updating,
                  onClose: () => setState(() => _selected = null),
                  onSaveScore: _saveScore,
                  onEdit: () => _onEditStudent(_selected!),
                  onPrint: _printStudentCard,
                  onDelete: _deleteStudent,
                ),
              );
            })(),
          ],        ],
      ])),
    ]);

    Widget getActiveView() {
      switch (_currentView) {
        case DashboardView.dashboard: return dashboardContent;
        case DashboardView.levels: return levelsView;
        case DashboardView.settings: return SettingsScreen(primaryColor: _primary, initialSection: _settingsSection);
        case DashboardView.statistics: return const StatisticsScreen();
      }
    }

    return ConnectivityBanner(
      child: Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: isWide
        ? Row(children: [
            DashboardSidebar(
              currentView: _currentView,
              onViewChanged: (view) => setState(() { _currentView = view; }),
              onLogout: _logout,
              primaryColor: _primary,
              collapsed: _sidebarCollapsed,
              onToggleCollapse: () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
              settingsSection: _settingsSection,
              onSettingsSectionChanged: (section) => setState(() {
                _settingsSection = section;
                _currentView = DashboardView.settings;
              }),
            ),
            Expanded(
              child: getActiveView(),
            ),
          ])
        : SafeArea(child: getActiveView()),
      bottomNavigationBar: !isWide
        ? Container(
            height: 70 + MediaQuery.of(context).padding.bottom,
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, -4)),
              ],
            ),
            child: Row(
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.grid_view_rounded,
                  label: 'لوحة التحكم',
                  isSelected: _currentView == DashboardView.dashboard,
                  onTap: () => setState(() => _currentView = DashboardView.dashboard),
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.analytics_rounded,
                  label: 'الإحصائيات',
                  isSelected: _currentView == DashboardView.statistics,
                  onTap: () => setState(() => _currentView = DashboardView.statistics),
                ),
                _buildAddButton(),
                _buildNavItem(
                  index: 2,
                  icon: Icons.account_tree_rounded,
                  label: 'المستويات',
                  isSelected: _currentView == DashboardView.levels,
                  onTap: () => setState(() => _currentView = DashboardView.levels),
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.settings_rounded,
                  label: 'الإعدادات',
                  isSelected: _currentView == DashboardView.settings,
                  onTap: () => setState(() => _currentView = DashboardView.settings),
                ),
              ],
            ),
          )
        : null,
      floatingActionButton: null,
    ),
    );
  }

  Widget _buildAddButton() {
    return Expanded(
      child: Center(
        child: InkWell(
          onTap: () {
            if (_currentView == DashboardView.dashboard) {
              _onToggleAddStudentPanel();
            } else if (_currentView == DashboardView.levels) {
              _levelsKey.currentState?.onToggleAddPanel();
            }
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF03121C),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF03121C).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? _primary.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? _primary : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? _primary : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isSelected ? 4 : 0,
              height: 4,
              decoration: BoxDecoration(
                color: _primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()), (r) => false);
    }
  }
}
