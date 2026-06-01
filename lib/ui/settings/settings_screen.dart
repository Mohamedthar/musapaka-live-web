import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/exam_schedule_slot.dart';
import '../../services/supabase_service.dart';
import '../../services/backup_service.dart';
import '../../ui/dashboard/widgets/stats_cards.dart';
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
  final Set<int> _expandedDays = {};
  final Set<int> _expandedFaqs = {};

  // FAQ state
  List<Map<String, dynamic>> _faqs = [];

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
    setState(() { _loading = true; });
    try {
      final row = await _service.getSettings();
      if (!mounted) return;
      if (row != null) _apply(row);
    } catch (e) {
      if (mounted) AppTheme.showSnack(context, 'تعذر تحميل الإعدادات: $e', color: AppTheme.errorColor);
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

    // FAQs
    final rawFaqs = row['faqs'];
    if (rawFaqs is List) {
      _faqs = rawFaqs.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } else {
      _faqs = [];
    }
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
      if (mounted) AppTheme.showSnack(context, validationError, color: AppTheme.warningColor);
      return;
    }

    setState(() { _saving = true; });
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
        'faqs': _faqs,
      });

      if (!mounted) return;
      await _load();
      if (mounted) AppTheme.showSnack(context, 'تم حفظ إعدادات النظام بنجاح ✓');
    } catch (e) {
      if (mounted) AppTheme.showSnack(context, 'تعذر الحفظ: $e', color: AppTheme.errorColor);
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
                    padding: EdgeInsets.fromLTRB(isMobile ? 16 : 20, isMobile ? 16 : 12, isMobile ? 16 : 20, isMobile ? 16 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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

  // ────────────────────────────────────────────────────────────
  // Top Bar
  // ────────────────────────────────────────────────────────────
  Widget _buildTopBar(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(Icons.settings_rounded, size: 20, color: _primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('إعدادات النظام', style: TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF03121C))),
                if (!isMobile) Text('التحكم الكامل في إعدادات المسابقة والجدولة', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _saving ? null : _load,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
                child: Icon(Icons.refresh_rounded, size: 19, color: _saving ? Colors.grey.shade300 : _primary),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save_rounded, size: 16, color: Colors.white),
            label: Text(_saving ? 'جاري الحفظ...' : 'حفظ', style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            style: ElevatedButton.styleFrom(backgroundColor: _saving ? Colors.grey.shade400 : _primary, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // Navigation
  // ────────────────────────────────────────────────────────────
  Widget _buildActiveContent(bool isMobile) {
    switch (_activeSection) {
      case 'dates':
        return KeyedSubtree(key: const ValueKey('dates'), child: _buildRegistrationDatesSection());
      case 'schedule':
        return KeyedSubtree(key: const ValueKey('schedule'), child: _buildSchedule(isMobile));
      case 'faqs':
        return KeyedSubtree(key: const ValueKey('faqs'), child: _buildFaqsSection());
      case 'backup':
        return KeyedSubtree(key: const ValueKey('backup'), child: _buildBackupSection());
      default:
        return KeyedSubtree(key: const ValueKey('dates'), child: _buildRegistrationDatesSection());
    }
  }

  // ────────────────────────────────────────────────────────────
  // Helpers
  // ────────────────────────────────────────────────────────────
  String _getDatePeriodStatus(DateTime? start, DateTime? end) {
    if (start == null || end == null) return 'غير محدد';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    if (today.isBefore(startDate)) return 'لم يبدأ بعد';
    if (today.isAfter(endDate)) return 'منتهي';
    return 'نشط حالياً';
  }

  Color _getDatePeriodColor(DateTime? start, DateTime? end) {
    if (start == null || end == null) return Colors.grey;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    if (today.isBefore(startDate)) return Colors.blue.shade600;
    if (today.isAfter(endDate)) return Colors.red.shade600;
    return Colors.green.shade600;
  }

  Widget _buildSubHeader(String title, IconData icon, Color accentColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: accentColor),
        ),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontFamily: 'Cairo', fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF03121C))),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 1, color: Colors.grey.shade100)),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────
  // Timeline Period Card
  // ────────────────────────────────────────────────────────────
  Widget _buildTimelinePeriodCard({
    required String title,
    required String status,
    required Color statusColor,
    required DateTime? start,
    required DateTime? end,
    required VoidCallback onStartTap,
    required VoidCallback onEndTap,
    bool compact = false,
  }) {
    final p = compact ? 12.0 : 16.0;
    final fs = compact ? 12.0 : 13.0;
    return Container(
      padding: EdgeInsets.all(p),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontFamily: 'Cairo', fontSize: fs, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
              Container(
                padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 2 : 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor.withValues(alpha: 0.2))),
                child: Text(status, style: TextStyle(fontFamily: 'Cairo', fontSize: compact ? 10 : 11, fontWeight: FontWeight.w800, color: statusColor)),
              ),
            ],
          ),
          SizedBox(height: compact ? 10 : 16),
          Row(
            children: [
              Expanded(child: SettingsFormFields.enhancedDateField(label: 'تاريخ البدء', selectedDate: start, onTap: onStartTap, primaryColor: _primary)),
              SizedBox(width: compact ? 8 : 12),
              Expanded(child: SettingsFormFields.enhancedDateField(label: 'تاريخ الانتهاء', selectedDate: end, onTap: onEndTap, primaryColor: _primary)),
            ],
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // Registration Dates Section
  // ────────────────────────────────────────────────────────────
  Widget _buildRegistrationDatesSection() {
    final statusReg = _getDatePeriodStatus(_registrationStart, _registrationEnd);
    final colorReg = _getDatePeriodColor(_registrationStart, _registrationEnd);
    final statusExam = _getDatePeriodStatus(_examPeriodStart, _examPeriodEnd);
    final colorExam = _getDatePeriodColor(_examPeriodStart, _examPeriodEnd);
    final isWide = MediaQuery.of(context).size.width >= 900;

    final togglesColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSubHeader('حالة الخدمات الإلكترونية', Icons.electrical_services_rounded, Colors.teal.shade600),
        const SizedBox(height: 14),
        SettingsFormFields.enhancedToggleField(label: 'بوابة تسجيل الطلاب الإلكترونية', description: 'عند التفعيل، يمكن للطلاب ملء استمارات التقديم عبر الإنترنت والتسجيل فوراً.', value: _isRegistrationOpen, onChanged: (v) => setState(() => _isRegistrationOpen = v), primaryColor: _primary),
        const SizedBox(height: 12),
        SettingsFormFields.enhancedToggleField(label: 'بوابة الاستعلام عن حضور الحفل الختامي', description: 'تسمح للمتسابقين بالاستعلام عن أحقيتهم وتفاصيل حضورهم للحفل الختامي.', value: _isCeremonyQueryOpen, onChanged: (v) => setState(() => _isCeremonyQueryOpen = v), primaryColor: Colors.purple),
        const SizedBox(height: 12),
        SettingsFormFields.enhancedToggleField(label: 'بوابة الاستعلام عن النتائج النهائية والدرجات', description: 'تسمح للطلاب بمعرفة الدرجات والنتائج والتكريمات فور إعلانها رسمياً.', value: _isResultQueryOpen, onChanged: (v) => setState(() => _isResultQueryOpen = v), primaryColor: Colors.amber.shade800),
      ],
    );

    final datesColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSubHeader('الفترات والتواريخ الزمنية للمسابقة', Icons.date_range_rounded, Colors.blue.shade600),
        const SizedBox(height: 12),
        _buildTimelinePeriodCard(title: 'فترة تقديم وتسجيل الطلاب', status: statusReg, statusColor: colorReg, start: _registrationStart, end: _registrationEnd, compact: isWide,
          onStartTap: () async { final d = await _pickDate(_registrationStart); if (d != null) setState(() => _registrationStart = d); },
          onEndTap: () async { final d = await _pickDate(_registrationEnd); if (d != null) setState(() => _registrationEnd = d); },
        ),
        const SizedBox(height: 10),
        Center(child: Container(width: 8, height: 8, decoration: BoxDecoration(color: colorExam.withValues(alpha: 0.2), shape: BoxShape.circle, border: Border.all(color: colorExam.withValues(alpha: 0.4), width: 1.5)))),
        const SizedBox(height: 10),
        _buildTimelinePeriodCard(title: 'فترة إجراء الاختبارات والتقييم', status: statusExam, statusColor: colorExam, start: _examPeriodStart, end: _examPeriodEnd, compact: isWide,
          onStartTap: () async { final d = await _pickDate(_examPeriodStart); if (d != null) setState(() => _examPeriodStart = d); },
          onEndTap: () async { final d = await _pickDate(_examPeriodEnd); if (d != null) setState(() => _examPeriodEnd = d); },
        ),
      ],
    );

    return SectionCard(
      title: 'قسم المواعيد وحالة الخدمات',
      description: 'إدارة تواريخ تقديم الطلاب وفترات الاختبارات وحالة الخدمات الإلكترونية للمسابقة',
      icon: Icons.calendar_today_rounded,
      primaryColor: _primary,
      child: isWide
          ? IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 5, child: togglesColumn),
                  const SizedBox(width: 28),
                  Container(width: 1, color: Colors.grey.shade100),
                  const SizedBox(width: 28),
                  Expanded(flex: 4, child: datesColumn),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                togglesColumn,
                const SizedBox(height: 24),
                Divider(color: Colors.grey.shade100, height: 1),
                const SizedBox(height: 24),
                datesColumn,
              ],
            ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // Schedule Section
  // ────────────────────────────────────────────────────────────
  Widget _buildSchedule(bool isMobile) {
    final totalDays = _days.where((d) => d.date != null).length;
    final totalPeriods = _days.fold<int>(0, (sum, d) => sum + d.periods.length);
    final totalCapacity = _days.fold<int>(0, (sum, d) { for (var slot in d.periods) { sum += slot.estimatedStudentCapacity; } return sum; });
    final avgPerDay = totalDays > 0 ? (totalCapacity ~/ totalDays) : 0;

    final stats = [
      StatEntry(title: 'أيام الاختبار', value: '$totalDays', icon: Icons.calendar_month_rounded, color: Colors.blue.shade600),
      StatEntry(title: 'إجمالي الفترات', value: '$totalPeriods', icon: Icons.view_timeline_rounded, color: Colors.teal.shade600),
      StatEntry(title: 'السعة الكلية', value: '$totalCapacity طالب', icon: Icons.people_rounded, color: _primary),
      StatEntry(title: 'متوسط اليوم', value: '$avgPerDay طالب', icon: Icons.analytics_rounded, color: Colors.orange.shade600),
    ];

    return SectionCard(
      title: 'جدول اللجان والفترات المتاحة للاختبار',
      description: 'إضافة الأيام المخصصة للاختبار وتحديد الفترات الزمنية وسعة كل فترة',
      icon: Icons.view_timeline_rounded,
      primaryColor: _primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Stats cards matching dashboard style
          _buildStatsRow(stats, isMobile),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade100, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text('أيام وفترات الاختبار المجدولة', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w800, color: _primary.withValues(alpha: 0.7))),
              ),
              ElevatedButton.icon(
                onPressed: () => setState(() => _days.add(DayBlock())),
                icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                label: const Text('إضافة يوم جديد', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12.5, color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: _primary, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_days.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 56),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                children: [
                  Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: _primary.withValues(alpha: 0.06), shape: BoxShape.circle), child: Icon(Icons.date_range_rounded, size: 40, color: _primary.withValues(alpha: 0.35))),
                  const SizedBox(height: 16),
                  Text('لا توجد أي فترات أو أيام اختبار مجدولة حالياً', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.5, fontWeight: FontWeight.bold, color: _primary.withValues(alpha: 0.6))),
                  const SizedBox(height: 6),
                  Text('اضغط على زر "إضافة يوم جديد" لبدء جدولة أوقات الاختبارات.', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey.shade400)),
                ],
              ),
            )
          else
            ..._days.asMap().entries.map((entry) => _buildDayCard(entry.key, entry.value, isMobile)),
        ],
      ),
    );
  }

  Widget _buildStatsRow(List<StatEntry> stats, bool isMobile) {
    return LayoutBuilder(
      builder: (ctx, c) {
        final cols = c.maxWidth > 700 ? stats.length : 2;
        final w = (c.maxWidth - (cols - 1) * 10) / cols;
        return Wrap(
          spacing: 10, runSpacing: 10,
          children: stats.map((s) => SizedBox(
            width: w,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(color: s.color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: s.color.withValues(alpha: 0.1)), boxShadow: [BoxShadow(color: s.color.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
              child: Row(
                children: [
                  Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: s.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(s.icon, color: s.color, size: 22)),
                  const SizedBox(width: 14),
                  Expanded(child: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w700))),
                  const SizedBox(width: 8),
                  Text(s.value, style: const TextStyle(fontFamily: 'Cairo', fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF03121C))),
                ],
              ),
            ),
          )).toList(),
        );
      },
    );
  }

  // ────────────────────────────────────────────────────────────
  // Day Card (collapsible)
  // ────────────────────────────────────────────────────────────
  Widget _buildDayCard(int dayIndex, DayBlock day, bool isMobile) {
    final dayHasError = day.date == null;
    final isExpanded = _expandedDays.contains(dayIndex);
    final formattedDate = day.date == null ? 'اختر التاريخ' : intl.DateFormat('EEEE، d MMMM yyyy', 'ar').format(day.date!);
    int dayTotalCapacity = 0;
    int totalPeriodsInDay = day.periods.length;
    for (var slot in day.periods) { dayTotalCapacity += slot.estimatedStudentCapacity; }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: dayHasError ? Colors.orange.shade300 : isExpanded ? _primary.withValues(alpha: 0.2) : Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 8, offset: const Offset(0, 3))]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Compact header — tap to expand/collapse
          InkWell(
            onTap: () => setState(() { if (isExpanded) { _expandedDays.remove(dayIndex); } else { _expandedDays.add(dayIndex); } }),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: dayHasError ? Colors.orange.withValues(alpha: 0.03) : const Color(0xFFF8FAFC), borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)), border: isExpanded ? Border(bottom: BorderSide(color: Colors.grey.shade100)) : null),
              child: Row(
                children: [
                  // Date picker button
                  InkWell(
                    onTap: () async { final d = await _pickDate(day.date); if (d != null) setState(() => day.date = d); },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: dayHasError ? Colors.orange.withValues(alpha: 0.08) : _primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_month_rounded, size: 14, color: dayHasError ? Colors.orange.shade800 : _primary),
                          const SizedBox(width: 6),
                          Text(formattedDate, style: TextStyle(fontFamily: 'Cairo', fontSize: 12.5, fontWeight: FontWeight.bold, color: dayHasError ? Colors.orange.shade800 : _primary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Info badges
                  if (day.date != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(6)),
                      child: Text('$totalPeriodsInDay فترات', style: TextStyle(fontFamily: 'Cairo', fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.green.shade700)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: _primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(6)),
                      child: Text('$dayTotalCapacity طالب', style: TextStyle(fontFamily: 'Cairo', fontSize: 10.5, fontWeight: FontWeight.w700, color: _primary)),
                    ),
                  ],
                  const Spacer(),
                  // Expand toggle + actions
                  IconButton(icon: Icon(isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, size: 20, color: _primary.withValues(alpha: 0.6)), onPressed: () => setState(() { if (isExpanded) { _expandedDays.remove(dayIndex); } else { _expandedDays.add(dayIndex); } }), splashRadius: 18, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
                  IconButton(icon: Icon(Icons.add_circle_outline_rounded, size: 18, color: _primary.withValues(alpha: 0.7)), onPressed: () => setState(() { day.periods.add(DayBlock.defaultSlot()); _expandedDays.add(dayIndex); }), splashRadius: 18, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
                  IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red), onPressed: () => setState(() => _days.removeAt(dayIndex)), splashRadius: 18, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
                ],
              ),
            ),
          ),
          // Expandable content
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: isExpanded
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: day.periods.isEmpty
                        ? Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('لا توجد فترات. اضغط + لإضافة فترة.', style: TextStyle(fontFamily: 'Cairo', fontSize: 11.5, color: Colors.grey.shade400))))
                        : Column(children: List.generate(day.periods.length, (periodIndex) {
                            final slot = day.periods[periodIndex];
                            bool slotHasOverlap = false;
                            for (var i = 0; i < day.periods.length; i++) { if (i != periodIndex && slot.startHour < day.periods[i].endHour && day.periods[i].startHour < slot.endHour) { slotHasOverlap = true; break; } }
                            return _buildPeriodRow(day, slot, periodIndex, slotHasOverlap, isMobile);
                          }),
                        ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // Period Row
  // ────────────────────────────────────────────────────────────
  Widget _buildPeriodRow(DayBlock day, ExamScheduleSlot slot, int periodIndex, bool hasOverlap, bool isMobile) {
    final estimatedCap = slot.estimatedStudentCapacity;
    final duration = slot.durationHours;

    if (isMobile) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: hasOverlap ? Colors.red.withValues(alpha: 0.02) : const Color(0xFFFAFBFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: hasOverlap ? Colors.red.shade200 : Colors.grey.shade200, width: hasOverlap ? 1.5 : 1)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasOverlap) Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red), const SizedBox(width: 6), Text('تداخل في أوقات فترات هذا اليوم!', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade700))])),
            Row(
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('من الساعة', style: TextStyle(fontFamily: 'Cairo', fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.bold)), const SizedBox(height: 4), _CompactDropdown(value: slot.startHour, items: List.generate(15, (i) => i + 8), onChanged: (v) => setState(() { slot.startHour = v; slot.clampInclusiveRange(); }), primaryColor: _primary)])),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('إلى الساعة', style: TextStyle(fontFamily: 'Cairo', fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.bold)), const SizedBox(height: 4), _CompactDropdown(value: slot.endHour, items: List.generate(24 - slot.startHour, (i) => i + slot.startHour + 1), onChanged: (v) => setState(() { slot.endHour = v; }), primaryColor: _primary)])),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Row(children: [const Text('سعة/ساعة:', style: TextStyle(fontFamily: 'Cairo', fontSize: 11.5, color: Color(0xFF334155), fontWeight: FontWeight.bold)), const SizedBox(width: 8), Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)), child: Row(mainAxisSize: MainAxisSize.min, children: [InkWell(onTap: slot.studentsPerHour > 1 ? () => setState(() => slot.studentsPerHour--) : null, borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)), child: Container(padding: const EdgeInsets.all(6), child: Icon(Icons.remove_rounded, size: 14, color: slot.studentsPerHour > 1 ? _primary : Colors.grey.shade300))), Container(width: 28, alignment: Alignment.center, child: Text('${slot.studentsPerHour}', style: TextStyle(fontFamily: 'Cairo', fontSize: 12.5, fontWeight: FontWeight.w900, color: _primary))), InkWell(onTap: () => setState(() => slot.studentsPerHour++), borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)), child: Container(padding: const EdgeInsets.all(6), child: Icon(Icons.add_rounded, size: 14, color: _primary)))]))])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: _primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('المدة: $duration ساعة', style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: _primary, fontWeight: FontWeight.bold)), Text('سعة الفترة: $estimatedCap طالب', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: _primary, fontWeight: FontWeight.w800))])),
                const SizedBox(width: 8),
                IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20), onPressed: () => setState(() => day.periods.removeAt(periodIndex))),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: hasOverlap ? Colors.red.withValues(alpha: 0.02) : const Color(0xFFFAFBFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: hasOverlap ? Colors.red.shade200 : Colors.grey.shade100, width: hasOverlap ? 1.5 : 1)),
      child: Row(
        children: [
          const Icon(Icons.access_time_rounded, size: 16, color: Colors.grey),
          const SizedBox(width: 10), const Text('من', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          SizedBox(width: 110, child: _CompactDropdown(value: slot.startHour, items: List.generate(15, (i) => i + 8), onChanged: (v) => setState(() { slot.startHour = v; slot.clampInclusiveRange(); }), primaryColor: _primary)),
          const SizedBox(width: 12), const Text('إلى', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          SizedBox(width: 110, child: _CompactDropdown(value: slot.endHour, items: List.generate(24 - slot.startHour, (i) => i + slot.startHour + 1), onChanged: (v) => setState(() { slot.endHour = v; }), primaryColor: _primary)),
          const SizedBox(width: 16),
          Container(height: 24, width: 1, color: Colors.grey.shade200), const SizedBox(width: 16),
          const Text('السعة لكل ساعة:', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)), child: Row(mainAxisSize: MainAxisSize.min, children: [InkWell(onTap: slot.studentsPerHour > 1 ? () => setState(() => slot.studentsPerHour--) : null, borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)), child: Container(padding: const EdgeInsets.all(6), child: Icon(Icons.remove_rounded, size: 14, color: slot.studentsPerHour > 1 ? _primary : Colors.grey.shade300))), Container(width: 32, alignment: Alignment.center, child: Text('${slot.studentsPerHour}', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w900, color: _primary))), InkWell(onTap: () => setState(() => slot.studentsPerHour++), borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)), child: Container(padding: const EdgeInsets.all(6), child: Icon(Icons.add_rounded, size: 14, color: _primary)))])),
          const SizedBox(width: 8), const Text('طلاب', style: TextStyle(fontFamily: 'Cairo', fontSize: 11.5, color: Colors.grey)),
          const SizedBox(width: 16),
          Container(height: 24, width: 1, color: Colors.grey.shade200), const SizedBox(width: 16),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: _primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(6)), child: Text('المدة: $duration ساعات  |  الإجمالي: $estimatedCap طالب', style: TextStyle(fontFamily: 'Cairo', fontSize: 11.5, fontWeight: FontWeight.bold, color: _primary))),
          if (hasOverlap) ...[
            const SizedBox(width: 12),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)), child: Row(children: [const Icon(Icons.warning_amber_rounded, size: 12, color: Colors.red), const SizedBox(width: 4), Text('تداخل!', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade700))])),
          ],
          const Spacer(),
          IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20), tooltip: 'حذف الفترة', onPressed: () => setState(() => day.periods.removeAt(periodIndex)), splashRadius: 20),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // FAQs Section
  // ────────────────────────────────────────────────────────────
  Widget _buildFaqsSection() {
    return SectionCard(
      title: 'الأسئلة الشائعة',
      description: 'إضافة وتعديل الأسئلة الشائعة التي تظهر في الصفحة الرئيسية للموقع',
      icon: Icons.help_outline_rounded,
      primaryColor: _primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${_faqs.length} سؤال',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w800, color: _primary.withValues(alpha: 0.7)),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => setState(() {
                  final newIdx = _faqs.length;
                  _faqs.add({'q': '', 'a': ''});
                  _expandedFaqs.add(newIdx);
                }),
                icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                label: const Text('إضافة سؤال جديد', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12.5, color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: _primary, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_faqs.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                children: [
                  Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: _primary.withValues(alpha: 0.06), shape: BoxShape.circle), child: Icon(Icons.help_outline_rounded, size: 40, color: _primary.withValues(alpha: 0.35))),
                  const SizedBox(height: 16),
                  Text('لا توجد أسئلة شائعة حالياً', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.5, fontWeight: FontWeight.bold, color: _primary.withValues(alpha: 0.6))),
                  const SizedBox(height: 6),
                  Text('اضغط على زر "إضافة سؤال جديد" لإضافة أسئلة تظهر للزوار.', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey.shade400)),
                ],
              ),
            )
          else
            ..._faqs.asMap().entries.map((entry) => _buildFaqCard(entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _buildFaqCard(int index, Map<String, dynamic> faq) {
    final isExpanded = _expandedFaqs.contains(index);

    return _FaqCard(
      index: index,
      faq: faq,
      primary: _primary,
      isExpanded: isExpanded,
      onToggleExpand: () => setState(() {
        if (isExpanded) {
          _expandedFaqs.remove(index);
        } else {
          _expandedFaqs.add(index);
        }
      }),
      onDelete: () => setState(() {
        _faqs.removeAt(index);
        _expandedFaqs.remove(index);
      }),
    );

  }

}

// ──────────────────────────────────────────────────────────────
// Faq Card - with proper controller lifecycle
// ──────────────────────────────────────────────────────────────
class _FaqCard extends StatefulWidget {
  final int index;
  final Map<String, dynamic> faq;
  final Color primary;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onDelete;

  const _FaqCard({
    required this.index,
    required this.faq,
    required this.primary,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onDelete,
  });

  @override
  State<_FaqCard> createState() => _FaqCardState();
}

class _FaqCardState extends State<_FaqCard> {
  late final TextEditingController _qCtrl;
  late final TextEditingController _aCtrl;

  @override
  void initState() {
    super.initState();
    _qCtrl = TextEditingController(text: widget.faq['q'] as String? ?? '');
    _aCtrl = TextEditingController(text: widget.faq['a'] as String? ?? '');
  }

  @override
  void didUpdateWidget(covariant _FaqCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newQ = widget.faq['q'] as String? ?? '';
    final newA = widget.faq['a'] as String? ?? '';
    if (_qCtrl.text != newQ) {
      _qCtrl.text = newQ;
    }
    if (_aCtrl.text != newA) {
      _aCtrl.text = newA;
    }
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    _aCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.faq['q'] as String? ?? '';
    final a = widget.faq['a'] as String? ?? '';
    final isEmpty = q.trim().isEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isEmpty ? Colors.orange.shade200 : widget.isExpanded ? widget.primary.withValues(alpha: 0.2) : Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: widget.onToggleExpand,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isEmpty ? Colors.orange.withValues(alpha: 0.03) : widget.isExpanded ? const Color(0xFFF8FAFC) : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
                border: widget.isExpanded ? Border(bottom: BorderSide(color: Colors.grey.shade100)) : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(color: isEmpty ? Colors.orange.withValues(alpha: 0.1) : widget.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                    alignment: Alignment.center,
                    child: Text('${widget.index + 1}', style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w900, color: isEmpty ? Colors.orange.shade700 : widget.primary)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      q.isEmpty ? '(سؤال فارغ - اضغط للتعديل)' : q,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12.5, fontWeight: FontWeight.bold, color: isEmpty ? Colors.orange.shade700 : const Color(0xFF1E293B)),
                    ),
                  ),
                  if (!isEmpty)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(6)),
                      child: Text('${a.length} حرف', style: TextStyle(fontFamily: 'Cairo', fontSize: 10, fontWeight: FontWeight.w700, color: Colors.green.shade700)),
                    ),
                  const SizedBox(width: 4),
                  Icon(
                    widget.isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 20, color: widget.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                    onPressed: widget.onDelete,
                    splashRadius: 16, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: widget.isExpanded
                ? Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _qCtrl,
                          textDirection: TextDirection.rtl,
                          onChanged: (v) => widget.faq['q'] = v,
                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            labelText: 'السؤال',
                            labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey.shade600),
                            hintText: 'مثال: كيف أعرف أن تسجيلي تم بنجاح؟',
                            hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey.shade400),
                            filled: true, fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: widget.primary, width: 1.5)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text('الإجابة', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade600)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _aCtrl,
                          textDirection: TextDirection.rtl,
                          onChanged: (v) => widget.faq['a'] = v,
                          maxLines: 3,
                          style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: 'اكتب الإجابة هنا...',
                            hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey.shade400),
                            filled: true, fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: widget.primary, width: 1.5)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupSection() {
    final BackupService backupService = BackupService();

    return SectionCard(
      title: 'النسخ الاحتياطي واستعادة البيانات',
      description: 'إنشاء نسخة احتياطية لجميع بيانات المتسابقين واستعادتها عند الحاجة',
      icon: Icons.backup_rounded,
      primaryColor: _primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _backupActionCard(
                  icon: Icons.cloud_download_rounded,
                  title: 'إنشاء نسخة احتياطية',
                  description: 'حفظ جميع بيانات المتسابقين في ملف JSON',
                  color: Colors.blue.shade600,
                  onTap: () async {
                    try {
                      AppTheme.showSnack(context, 'جاري إنشاء النسخة الاحتياطية...');
                      final file = await backupService.exportBackupToFile();
                      if (file != null && mounted) {
                        AppTheme.showSnack(context, 'تم حفظ النسخة الاحتياطية بنجاح');
                      }
                    } catch (e) {
                      if (mounted) AppTheme.showSnack(context, 'فشل: $e', color: AppTheme.errorColor);
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _backupActionCard(
                  icon: Icons.restore_page_rounded,
                  title: 'استعادة نسخة احتياطية',
                  description: 'استيراد بيانات المتسابقين من ملف JSON',
                  color: Colors.orange.shade700,
                  onTap: () async {
                    try {
                      final data = await backupService.pickBackupFile();
                      if (data == null) return;
                      
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('تأكيد الاستعادة',
                            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800)),
                          content: Text(
                            'سيتم استعادة ${(data['students'] as List?)?.length ?? 0} متسابق. هل أنت متأكد؟',
                            style: const TextStyle(fontFamily: 'Cairo')),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('استعادة', style: TextStyle(fontFamily: 'Cairo')),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && mounted) {
                        AppTheme.showSnack(context, 'جاري استعادة البيانات...');
                        final count = await backupService.restoreFromFile(data);
                        if (mounted) {
                          AppTheme.showSnack(context, 'تم استعادة $count متسابق بنجاح');
                          _load();
                        }
                      }
                    } catch (e) {
                      if (mounted) AppTheme.showSnack(context, 'فشل: $e', color: AppTheme.errorColor);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 20, color: Colors.amber.shade700),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'تنبيه: النسخ الاحتياطي يحفظ بيانات المتسابقين فقط. يُنصح بعمل نسخة احتياطية دورياً.',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Color(0xFF92400E)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _backupActionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 14),
              Text(title, style: const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF03121C))),
              const SizedBox(height: 6),
              Text(description, textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey.shade600, height: 1.4)),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Compact Dropdown
// ──────────────────────────────────────────────────────────────
class _CompactDropdown extends StatelessWidget {
  final int value;
  final List<int> items;
  final Function(int) onChanged;
  final Color primaryColor;

  const _CompactDropdown({required this.value, required this.items, required this.onChanged, required this.primaryColor});

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
        isDense: true, filled: true, fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: primaryColor, width: 2)),
      ),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(_formatTime(i)))).toList(),
      onChanged: (v) { if (v != null) onChanged(v); },
    );
  }
}
