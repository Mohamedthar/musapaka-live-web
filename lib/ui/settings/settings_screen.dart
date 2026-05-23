import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/exam_schedule_slot.dart';
import '../../services/supabase_service.dart';
import 'models/day_block.dart';
import 'widgets/section_card.dart';
import 'widgets/form_fields.dart';

class SettingsScreen extends StatefulWidget {
  final Color? primaryColor;
  final String initialSection;
  const SettingsScreen({super.key, this.primaryColor, this.initialSection = 'dates'});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SupabaseService _service = SupabaseService();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _successMsg;

  bool _isRegistrationOpen = false;
  bool _isCeremonyQueryOpen = false;
  bool _isResultQueryOpen = false;
  DateTime? _registrationStart;
  DateTime? _registrationEnd;
  DateTime? _examPeriodStart;
  DateTime? _examPeriodEnd;
  List<DayBlock> _days = [];
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _totalPrizesCtrl = TextEditingController();
  int _committeesCount = 3;

  late String _activeSection;

  Color get _primary => widget.primaryColor ?? AppTheme.primaryColor;

  @override
  void initState() {
    super.initState();
    _activeSection = widget.initialSection;
    _load();
  }

  @override
  void didUpdateWidget(covariant SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSection != widget.initialSection) {
      setState(() => _activeSection = widget.initialSection);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _totalPrizesCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; _successMsg = null; });
    try {
      final row = await _service.getSettings();
      if (!mounted) return;
      if (row != null) _apply(row);
    } catch (e) {
      if (mounted) setState(() => _error = 'تعذر تحميل الإعدادات: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _apply(Map<String, dynamic> row) {
    _isRegistrationOpen = row['is_registration_open'] ?? false;
    _isCeremonyQueryOpen = row['is_ceremony_query_open'] ?? false;
    _isResultQueryOpen = row['is_result_query_open'] ?? false;
    _registrationStart = ExamScheduleSlot.parseDate(row['registration_start_date']);
    _registrationEnd = ExamScheduleSlot.parseDate(row['registration_end_date']);
    _examPeriodStart = ExamScheduleSlot.parseDate(row['exam_period_start']);
    _examPeriodEnd = ExamScheduleSlot.parseDate(row['exam_period_end']);
    _days = _group(ExamScheduleSlot.listFromJson(row['exam_schedule']));
    _committeesCount = (row['committees_count'] as num?)?.toInt() ?? 3;
    _titleCtrl.text = row['title'] ?? 'مسابقة القرآن الكريم';
    _descriptionCtrl.text = row['description'] ?? '';
    _totalPrizesCtrl.text = row['total_prizes'] ?? '50,000+';
  }

  List<DayBlock> _group(List<ExamScheduleSlot> slots) {
    final grouped = <String, List<ExamScheduleSlot>>{};
    for (final slot in slots) {
      if (slot.date == null) continue;
      final key = intl.DateFormat('yyyy-MM-dd').format(slot.date!);
      grouped.putIfAbsent(key, () => []).add(slot);
    }
    final keys = grouped.keys.toList()..sort();
    return keys.map((key) {
      final list = grouped[key]!..sort((a, b) => a.startHour.compareTo(b.startHour));
      return DayBlock(date: list.first.date, periods: list);
    }).toList();
  }

  List<ExamScheduleSlot> _flatten() {
    final out = <ExamScheduleSlot>[];
    for (final day in _days) {
      if (day.date == null) continue;
      for (final period in day.periods) {
        out.add(period.copyWith(date: day.date));
      }
    }
    return out;
  }

  bool get _hasIncompleteDays => _days.any((d) => d.date == null);
  bool get _hasOverlaps {
    final slots = _flatten();
    for (var i = 0; i < slots.length; i++) {
      for (var j = i + 1; j < slots.length; j++) {
        if (slots[i].overlaps(slots[j])) return true;
      }
    }
    return false;
  }

  Future<DateTime?> _pickDate(DateTime? initial) => showDatePicker(
    context: context,
    initialDate: initial ?? DateTime.now(),
    firstDate: DateTime(2024),
    lastDate: DateTime(2030),
    builder: (ctx, child) => Theme(
      data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.light(primary: _primary)),
      child: child!,
    ),
  );

  Future<void> _save() async {
    final validationError = _validateBeforeSave();
    if (validationError != null) {
      setState(() { _error = validationError; _successMsg = null; });
      return;
    }

    setState(() { _saving = true; _error = null; _successMsg = null; });
    try {
      await _service.updateSettings({
        'is_registration_open': _isRegistrationOpen,
        'is_ceremony_query_open': _isCeremonyQueryOpen,
        'is_result_query_open': _isResultQueryOpen,
        'registration_start_date': _registrationStart?.toIso8601String(),
        'registration_end_date': _registrationEnd?.toIso8601String(),
        'exam_period_start': _examPeriodStart?.toIso8601String(),
        'exam_period_end': _examPeriodEnd?.toIso8601String(),
        'exam_schedule': _flatten().map((s) => s.toJson()).toList(),
        'title': _titleCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim(),
        'total_prizes': _totalPrizesCtrl.text.trim(),
        'committees_count': _committeesCount,
      });

      if (!mounted) return;
      await _load();
      setState(() => _successMsg = 'تم حفظ إعدادات النظام بنجاح ✓');
    } catch (e) {
      if (mounted) setState(() => _error = 'تعذر الحفظ: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _validateBeforeSave() {
    if (_registrationStart != null && _registrationEnd != null && _registrationEnd!.isBefore(_registrationStart!)) return 'نهاية التقديم تسبق البداية.';
    if (_examPeriodStart != null && _examPeriodEnd != null && _examPeriodEnd!.isBefore(_examPeriodStart!)) return 'نهاية الاختبارات تسبق البداية.';
    if (_hasIncompleteDays) return 'يوجد أيام بدون تاريخ، يُرجى تحديدها.';
    if (_hasOverlaps) return 'يوجد تداخل بين فترات بعض اللجان.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final screenType = ResponsiveUtils.fromWidth(MediaQuery.of(context).size.width);
    final isMobile = screenType == ScreenType.mobile;

    return Column(
      children: [
        _buildTopBar(isMobile),
        Expanded(
          child: Container(
            color: const Color(0xFFF5F5F7),
            child: _loading
              ? Center(child: CircularProgressIndicator(color: _primary))
              : Directionality(
                  textDirection: TextDirection.rtl,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 16 : 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_error != null) _buildAlert(_error!, true),
                        if (_successMsg != null) _buildAlert(_successMsg!, false),
                        _buildActiveContent(isMobile),
                      ],
                    ),
                  ),
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(bool isMobile) {
    final sectionLabel = _activeSection == 'dates'
        ? 'المواعيد واللجان'
        : 'جدول الفترات';
    final sectionIcon = _activeSection == 'dates'
        ? Icons.calendar_today_rounded
        : Icons.view_timeline_rounded;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1)),
      ),
      child: Row(
        children: [
          // Section icon badge
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(sectionIcon, size: 18, color: _primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  sectionLabel,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF03121C),
                  ),
                ),
                if (!isMobile)
                  Text(
                    _activeSection == 'dates'
                        ? 'إدارة تواريخ التسجيل والاختبار وضبط لجان التحكيم'
                        : 'جدولة فترات لجان الاختبار اليومية وتحديد سعة كل فترة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),
          // Refresh button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _saving ? null : _load,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Icon(
                  Icons.refresh_rounded,
                  size: 19,
                  color: _saving ? Colors.grey.shade300 : const Color(0xFF03121C),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Save button
          ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded, size: 16, color: Colors.white),
            label: Text(
              _saving ? 'جاري الحفظ...' : 'حفظ',
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _saving ? Colors.grey.shade400 : Colors.green.shade600,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveContent(bool isMobile) {
    switch (_activeSection) {
      case 'dates':
        return _buildRegistrationDatesSection();
      case 'schedule':
        return _buildSchedule(isMobile);
      default:
        return _buildRegistrationDatesSection();
    }
  }

  String _getDatePeriodStatus(DateTime? start, DateTime? end) {
    if (start == null || end == null) return 'غير محدد';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    
    if (today.isBefore(startDate)) {
      return 'لم يبدأ بعد';
    } else if (today.isAfter(endDate)) {
      return 'منتهي';
    } else {
      return 'نشط حالياً';
    }
  }

  Color _getDatePeriodColor(DateTime? start, DateTime? end) {
    if (start == null || end == null) return Colors.grey;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    
    if (today.isBefore(startDate)) {
      return Colors.blue.shade600;
    } else if (today.isAfter(endDate)) {
      return Colors.red.shade600;
    } else {
      return Colors.green.shade600;
    }
  }

  Widget _buildSubHeader(String title, IconData icon, Color accentColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: accentColor),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.grey.shade100,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelinePeriodCard({
    required String title,
    required String status,
    required Color statusColor,
    required DateTime? start,
    required DateTime? end,
    required VoidCallback onStartTap,
    required VoidCallback onEndTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SettingsFormFields.enhancedDateField(
                  label: 'تاريخ البدء',
                  selectedDate: start,
                  onTap: onStartTap,
                  primaryColor: _primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SettingsFormFields.enhancedDateField(
                  label: 'تاريخ الانتهاء',
                  selectedDate: end,
                  onTap: onEndTap,
                  primaryColor: _primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommitteesVisual() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_committeesCount, (index) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _primary.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.gavel_rounded, size: 14, color: _primary),
              const SizedBox(width: 6),
              Text(
                'لجنة ${index + 1}',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _primary,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildRegistrationDatesSection() {
    final statusReg = _getDatePeriodStatus(_registrationStart, _registrationEnd);
    final colorReg = _getDatePeriodColor(_registrationStart, _registrationEnd);
    
    final statusExam = _getDatePeriodStatus(_examPeriodStart, _examPeriodEnd);
    final colorExam = _getDatePeriodColor(_examPeriodStart, _examPeriodEnd);

    return SectionCard(
      title: 'مواعيد التقديم ولجان التحكيم',
      description: 'إدارة تواريخ تقديم الطلاب، وفترات الاختبارات، ونشاط بوابة التسجيل مع لجان التقييم',
      icon: Icons.calendar_today_rounded,
      primaryColor: _primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sub-Card 1: بوابة الخدمات الإلكترونية (Portal & Electronic Services status)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.015),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSubHeader('حالة الخدمات الإلكترونية', Icons.electrical_services_rounded, Colors.teal.shade600),
                const SizedBox(height: 16),
                SettingsFormFields.enhancedToggleField(
                  label: 'بوابة تسجيل الطلاب الإلكترونية',
                  description: 'عند التفعيل، يمكن للطلاب ملء استمارات التقديم عبر الإنترنت والتسجيل فوراً.',
                  value: _isRegistrationOpen,
                  onChanged: (v) => setState(() => _isRegistrationOpen = v),
                  primaryColor: _primary,
                ),
                const SizedBox(height: 14),
                SettingsFormFields.enhancedToggleField(
                  label: 'بوابة الاستعلام عن حضور الحفل الختامي',
                  description: 'تسمح للمتسابقين بالاستعلام عن أحقيتهم وتفاصيل حضورهم للحفل الختامي.',
                  value: _isCeremonyQueryOpen,
                  onChanged: (v) => setState(() => _isCeremonyQueryOpen = v),
                  primaryColor: Colors.purple,
                ),
                const SizedBox(height: 14),
                SettingsFormFields.enhancedToggleField(
                  label: 'بوابة الاستعلام عن النتائج النهائية والدرجات',
                  description: 'تسمح للطلاب بمعرفة الدرجات والنتائج والتكريمات فور إعلانها رسمياً.',
                  value: _isResultQueryOpen,
                  onChanged: (v) => setState(() => _isResultQueryOpen = v),
                  primaryColor: Colors.amber.shade800,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Sub-Card 2: المواعيد والتواريخ الهامة (Important Dates)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.015),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSubHeader('الفترات والتواريخ الزمنية للمسابقة', Icons.date_range_rounded, Colors.blue.shade600),
                const SizedBox(height: 16),
                
                // Timeline style preview card for Registration
                _buildTimelinePeriodCard(
                  title: 'فترة تقديم وتسجيل الطلاب',
                  status: statusReg,
                  statusColor: colorReg,
                  start: _registrationStart,
                  end: _registrationEnd,
                  onStartTap: () async {
                    final d = await _pickDate(_registrationStart);
                    if (d != null) setState(() => _registrationStart = d);
                  },
                  onEndTap: () async {
                    final d = await _pickDate(_registrationEnd);
                    if (d != null) setState(() => _registrationEnd = d);
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Timeline style preview card for Exams
                _buildTimelinePeriodCard(
                  title: 'فترة إجراء الاختبارات والتقييم الفعلي',
                  status: statusExam,
                  statusColor: colorExam,
                  start: _examPeriodStart,
                  end: _examPeriodEnd,
                  onStartTap: () async {
                    final d = await _pickDate(_examPeriodStart);
                    if (d != null) setState(() => _examPeriodStart = d);
                  },
                  onEndTap: () async {
                    final d = await _pickDate(_examPeriodEnd);
                    if (d != null) setState(() => _examPeriodEnd = d);
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Sub-Card 3: لجان التحكيم (Judging Committees Configuration)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.015),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSubHeader('تهيئة لجان التقييم والتحكيم', Icons.gavel_rounded, Colors.orange.shade600),
                const SizedBox(height: 16),
                SettingsFormFields.enhancedStepperField(
                  value: _committeesCount,
                  onChanged: (v) => setState(() => _committeesCount = v),
                  primaryColor: _primary,
                  label: 'عدد لجان التحكيم الفعالة',
                  description: 'تحديد عدد اللجان المنفصلة التي تجري الاختبارات في نفس الوقت بشكل متوازي.',
                  minValue: 1,
                  maxValue: 12,
                ),
                const SizedBox(height: 16),
                Text(
                  'مخطط توزيع اللجان التفاعلي:',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 10),
                _buildCommitteesVisual(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedule(bool isMobile) {
    return SectionCard(
      title: 'جدول اللجان والفترات المتاحة للاختبار',
      description: 'إضافة الأيام المخصصة للاختبار وتحديد الفترات الزمنية وسعة كل فترة',
      icon: Icons.view_timeline_rounded,
      primaryColor: _primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'أيام وفترات الاختبار المجدولة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'قم بإضافة أيام الاختبار وتفاصيل الفترات اليومية والسعة الاستيعابية لكل فترة.',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11.5,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => setState(() => _days.add(DayBlock())),
                icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                label: const Text(
                  'إضافة يوم جديد',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_days.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 64),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Icon(Icons.date_range_rounded, size: 40, color: Colors.grey.shade300),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'لا توجد أي فترات أو أيام اختبار مجدولة حالياً',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'اضغط على زر "إضافة يوم جديد" لبدء جدولة أوقات الاختبارات.',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._days.asMap().entries.map((entry) => _buildDayCard(entry.key, entry.value, isMobile)),
        ],
      ),
    );
  }

  Widget _buildDayCard(int dayIndex, DayBlock day, bool isMobile) {
    final dayHasError = day.date == null;
    final formattedDate = day.date == null 
        ? 'اضغط هنا لتحديد تاريخ هذا اليوم' 
        : intl.DateFormat('EEEE، d MMMM yyyy', 'ar').format(day.date!);
        
    // Calculate total capacity for this day
    int dayTotalCapacity = 0;
    for (var slot in day.periods) {
      dayTotalCapacity += slot.estimatedStudentCapacity;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dayHasError ? Colors.orange.shade300 : Colors.grey.shade200, 
          width: dayHasError ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Day Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: dayHasError ? Colors.orange.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                // Date picker button
                InkWell(
                  onTap: () async {
                    final d = await _pickDate(day.date);
                    if (d != null) {
                      setState(() => day.date = d);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: dayHasError ? Colors.orange.withValues(alpha: 0.08) : _primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: dayHasError ? Colors.orange.shade200 : _primary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_month_rounded, 
                          size: 16, 
                          color: dayHasError ? Colors.orange.shade800 : _primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: dayHasError ? Colors.orange.shade800 : _primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Total capacity info
                if (day.date != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.15)),
                    ),
                    child: Text(
                      'سعة اليوم: $dayTotalCapacity طالب/لجنة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                const Spacer(),
                // Add Period inside header
                IconButton(
                  icon: Icon(Icons.add_circle_outline_rounded, color: _primary, size: 22),
                  tooltip: 'إضافة فترة زمنية لهذا اليوم',
                  onPressed: () => setState(() => day.periods.add(DayBlock.defaultSlot())),
                ),
                // Delete day button
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 22),
                  tooltip: 'حذف هذا اليوم بالكامل',
                  onPressed: () => setState(() => _days.removeAt(dayIndex)),
                ),
              ],
            ),
          ),
          
          // Periods List
          Padding(
            padding: const EdgeInsets.all(16),
            child: day.periods.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'لا توجد فترات مضافة لهذا اليوم. اضغط على أيقونة الإضافة أعلاه لبدء الجدولة.',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12.5,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: List.generate(day.periods.length, (periodIndex) {
                      final slot = day.periods[periodIndex];
                      
                      // Check overlap inside this day
                      bool slotHasOverlap = false;
                      for (var i = 0; i < day.periods.length; i++) {
                        if (i != periodIndex && slot.startHour < day.periods[i].endHour && day.periods[i].startHour < slot.endHour) {
                          slotHasOverlap = true;
                          break;
                        }
                      }

                      return _buildPeriodRow(day, slot, periodIndex, slotHasOverlap, isMobile);
                    }),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodRow(DayBlock day, ExamScheduleSlot slot, int periodIndex, bool hasOverlap, bool isMobile) {
    final estimatedCap = slot.estimatedStudentCapacity;
    final duration = slot.durationHours;

    if (isMobile) {
      // Mobile Layout: elements stacked for high-fidelity responsive design
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hasOverlap ? Colors.red.withValues(alpha: 0.02) : const Color(0xFFFAFBFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasOverlap ? Colors.red.shade200 : Colors.grey.shade200,
            width: hasOverlap ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasOverlap)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red),
                    const SizedBox(width: 6),
                    Text(
                      'تداخل في أوقات فترات هذا اليوم!',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'من الساعة',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      _CompactDropdown(
                        value: slot.startHour,
                        items: List.generate(15, (i) => i + 8),
                        onChanged: (v) => setState(() { 
                          slot.startHour = v; 
                          slot.clampInclusiveRange(); 
                        }),
                        primaryColor: _primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'إلى الساعة',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      _CompactDropdown(
                        value: slot.endHour,
                        items: List.generate(24 - slot.startHour, (i) => i + slot.startHour + 1),
                        onChanged: (v) => setState(() {
                          slot.endHour = v;
                        }),
                        primaryColor: _primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Text(
                        'سعة/ساعة:',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 11.5, color: Color(0xFF334155), fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: slot.studentsPerHour > 1 
                                  ? () => setState(() => slot.studentsPerHour--) 
                                  : null,
                              borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                child: Icon(Icons.remove_rounded, size: 14, color: slot.studentsPerHour > 1 ? _primary : Colors.grey.shade300),
                              ),
                            ),
                            Container(
                              width: 28,
                              alignment: Alignment.center,
                              child: Text(
                                '${slot.studentsPerHour}',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w900,
                                  color: _primary,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => setState(() => slot.studentsPerHour++),
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                child: Icon(Icons.add_rounded, size: 14, color: _primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'المدة: $duration ساعة',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: _primary, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'سعة الفترة: $estimatedCap طالب',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: _primary, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                  onPressed: () => setState(() => day.periods.removeAt(periodIndex)),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Desktop/Tablet Layout: streamlined horizontal row layout
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: hasOverlap ? Colors.red.withValues(alpha: 0.02) : const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasOverlap ? Colors.red.shade200 : Colors.grey.shade100,
          width: hasOverlap ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Time Pickers
          const Icon(Icons.access_time_rounded, size: 16, color: Colors.grey),
          const SizedBox(width: 10),
          const Text(
            'من',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 110,
            child: _CompactDropdown(
              value: slot.startHour,
              items: List.generate(15, (i) => i + 8),
              onChanged: (v) => setState(() { 
                slot.startHour = v; 
                slot.clampInclusiveRange(); 
              }),
              primaryColor: _primary,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'إلى',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 110,
            child: _CompactDropdown(
              value: slot.endHour,
              items: List.generate(24 - slot.startHour, (i) => i + slot.startHour + 1),
              onChanged: (v) => setState(() {
                slot.endHour = v;
              }),
              primaryColor: _primary,
            ),
          ),
          const SizedBox(width: 16),
          // Divider
          Container(height: 24, width: 1, color: Colors.grey.shade200),
          const SizedBox(width: 16),
          
          // Capacity Stepper
          const Text(
            'السعة لكل ساعة:',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: slot.studentsPerHour > 1 
                      ? () => setState(() => slot.studentsPerHour--) 
                      : null,
                  borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.remove_rounded, size: 14, color: slot.studentsPerHour > 1 ? _primary : Colors.grey.shade300),
                  ),
                ),
                Container(
                  width: 32,
                  alignment: Alignment.center,
                  child: Text(
                    '${slot.studentsPerHour}',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: _primary,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => slot.studentsPerHour++),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.add_rounded, size: 14, color: _primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'طلاب',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 11.5, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          Container(height: 24, width: 1, color: Colors.grey.shade200),
          const SizedBox(width: 16),
          
          // Calculated info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'المدة: $duration ساعات  |  الإجمالي: $estimatedCap طالب',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: _primary,
              ),
            ),
          ),
          
          if (hasOverlap) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 12, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(
                    'تداخل!',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const Spacer(),
          
          // Actions
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
            tooltip: 'حذف الفترة',
            onPressed: () => setState(() => day.periods.removeAt(periodIndex)),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildAlert(String message, bool isError) {
    final bgColor = isError ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4);
    final borderColor = isError ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0);
    final iconColor = isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A);
    final textColor = isError ? const Color(0xFF7F1D1D) : const Color(0xFF14532D);
    final icon = isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Cairo',
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}



class _CompactDropdown extends StatelessWidget {
  final int value;
  final List<int> items;
  final Function(int) onChanged;
  final Color primaryColor;

  const _CompactDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.primaryColor,
  });

  String _formatTime(int hour) {
    final h = hour > 12 ? hour - 12 : (hour == 0 || hour == 24 ? 12 : hour);
    final amPm = (hour >= 12 && hour < 24) ? 'م' : 'ص';
    return '${h.toString().padLeft(2, '0')}:00 $amPm';
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Colors.grey),
      style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF03121C)),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: primaryColor, width: 2)),
      ),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(_formatTime(i)))).toList(),
      onChanged: (v) { if (v != null) onChanged(v); },
    );
  }
}
